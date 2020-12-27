open Tsdl
open Sigs
open Tartine_utils

module Make (I: Init_sig) = struct
  let smoothing_samples_nb = 10
  (* How much slower do we need to refresh textual debug informations?
     (eg. displayed fps, etc.) *)
  let printing_speed_ratio = 3

  type time = { frame_time: int32; total_time: int32 }

  module EventsH = Hashtbl.Make (struct
      type t = Sdl.event_type
      let hash = Hashtbl.hash
      let equal = (=)
    end)

  (* Time handling ************************************************************)

  let ptime render delay frame =
    let open Int32 in
    let fps = if frame = 0l then 0l else 1000l / frame in
    Printf.printf "% 8i% 8i% 8i (fps: % 4d)\r%!"
      (to_int render)
      (to_int delay)
      (to_int frame)
      (to_int fps)

  let make_smoothed () =
    let samples = Array.make smoothing_samples_nb 0l in
    let sample_id = ref 0 in
    let stored_samples = ref 0 in
    let samples_sum = ref 0l in
    let store_sample time =
      samples_sum := Int32.(!samples_sum - samples.(!sample_id) + time);
      samples.(!sample_id) <- time;
      sample_id := (!sample_id + 1) mod smoothing_samples_nb;
      if !stored_samples < smoothing_samples_nb then
        incr stored_samples in
    let smoothed_time () =
      if !stored_samples = 0 then 0l
      else Int32.(!samples_sum / (of_int !stored_samples)) in
    store_sample, smoothed_time

  (* [update_time] must be called after the rendering/computations phase.  It
     updates the average rendering frame time, and computes - if the framerate
     is capped - the additionnal delay.
  *)
  let update_time, get_rendering_time, get_frame_time, get_delay, print_time =
    let open Int32 in
    let after_rendering_total_time = ref 0l in
    let delay = ref 0l in
    let store_rendering_time, get_average_rendering_time = make_smoothed () in
    let store_frame_time, get_average_frame_time = make_smoothed () in
    (fun () ->
       let current_time = Sdl.get_ticks () in
       let last_frame_time = current_time - !after_rendering_total_time in
       let last_frame_rendering_time = last_frame_time - !delay in
       store_frame_time last_frame_time;
       store_rendering_time last_frame_rendering_time;
       let average_rendering_time = get_average_rendering_time () in
       let min_delay = if average_rendering_time = 0l then 1l else 0l in
       begin match I.fps_cap with
         | None -> delay := min_delay
         | Some fps -> delay := max
               ((1000l / of_int fps) - average_rendering_time)
               min_delay
       end;
       after_rendering_total_time := current_time),
    (fun () -> get_average_rendering_time ()),
    (fun () -> get_average_frame_time ()),
    (fun () -> !delay),
    (fun () ->
       ptime
         (get_average_rendering_time ())
         !delay
         (get_average_frame_time ()))

  let slow_print_time =
    let tick_count = ref 0 in
    fun st ->
      if !tick_count >= printing_speed_ratio then (
        tick_count := 0;
        print_time ()
      ); incr tick_count;
      st

  (* Runtime data *************************************************************)

  let events_table = EventsH.create 255
  let events_s_table = EventsH.create 255

  let do_quit = ref false

  (* init sdl stuff *)
  let () =
    let open Sdl_result in
    begin
      Sdl.init Sdl.Init.everything >>= fun () ->
      (* Tsdl_image.Image.init Tsdl_image.Image.Init.(png + jpg) |> ignore; *)
      if (Sdl.set_hint Sdl.Hint.render_vsync "1")
      then print_endline "vsync: success"
      else print_endline "vsync: failure";
      if (Sdl.set_hint Sdl.Hint.render_scale_quality "nearest")
      then print_endline "scale quality: success"
      else print_endline "scale quality: failure";
      return ()
    end |> handle_error failwith

  let window, renderer =
    let open Sdl_result in
    Sdl.create_window_and_renderer ~w:I.w ~h:I.h
      (if I.fullscreen then Sdl.Window.(fullscreen + I.flags) else I.flags)
    |> handle_error failwith

  let tick, send_tick =
    let tick, send_tick = React.E.create () in
    React.E.map slow_print_time tick, send_tick

  let post_render, send_post_render = React.E.create ()

  let time = React.S.hold { frame_time = 0l; total_time = 0l } tick

  (****************************************************************************)

  let event ty field =
    let handlers =
      try EventsH.find events_table ty with Not_found -> []
    in
    let e, send_e = React.E.create () in
    let handle sdl_e = Sdl.Event.get sdl_e field |> send_e in
    EventsH.replace events_table ty (handle :: handlers);
    e

  let event_this_frame ty field =
    let handlers =
      try EventsH.find events_s_table ty with Not_found -> []
    in
    let s, send_s = React.S.create [] in
    let record_ev, send_recorded =
      let mem = ref [] in
      (fun sdl_e -> mem := (Sdl.Event.get sdl_e field) :: !mem),
      (fun () -> send_s !mem; mem := [])
    in
    EventsH.replace events_s_table ty
      ((record_ev, send_recorded)::handlers);
    s

  let send_events ev =
    Sdl.pump_events ();
    while Sdl.poll_event (Some ev) do
      if Sdl.Event.(get ev typ = quit) then do_quit := true;
      let event_typ = Sdl.Event.(get ev typ) in
      (try EventsH.find events_table event_typ |> List.iter ((|>) ev)
       with Not_found -> ());
      (try EventsH.find events_s_table event_typ
           |> List.map fst
           |> List.iter ((|>) ev);
       with Not_found -> ());
    done;
    EventsH.iter (fun _ l ->
        List.iter (fun (_, send_recorded) -> send_recorded ()) l)
      events_s_table

  let quit () =
    let e = Sdl.Event.create () in
    Sdl.Event.set e Sdl.Event.typ Sdl.Event.quit;
    Sdl.push_event e |> ignore

  (* Main event loop **********************************************************)

  let event_loop r _w =
    let open Sdl_result in
    let ev = Sdl.Event.create () in
    let rec loop () =
      let frame = get_frame_time () in
      send_events ev;
      send_tick { frame_time = frame; total_time = Sdl.get_ticks () };
      ignore (Gc.major_slice 0);
      send_post_render { frame_time = frame; total_time = Sdl.get_ticks () };
      Sdl.render_present r;
      Sdl.render_clear r >>= fun () ->
      update_time ();
      let delay = get_delay () in
      if delay > 0l then Sdl.delay delay;
      if not !do_quit then loop () else return ();
    in
    loop ()

  let cleanup_and_quit r w =
    Sdl.destroy_renderer r;
    Sdl.destroy_window w;
    (* Tsdl_image.Image.quit (); *)
    Sdl.quit ();
    print_endline "\nquit."

  let run () =
    event_loop renderer window
    |> Sdl_result.handle_error (Printf.eprintf "%s\n%!");
    cleanup_and_quit renderer window
end
