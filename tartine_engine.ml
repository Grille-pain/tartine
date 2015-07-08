open Tsdl
open Batteries
open Sigs
open Tartine_utils

module Make (I: Init_sig) = struct
  let fps = 60l
  let wait_time = Int32.(1000l / fps)
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

  let ptime real delay frame =
    let open Int32 in
    let actual_fps = (fps * fps * frame) / 1000l in
    Printf.printf "% 8i% 8i% 8i (fps: % 4d)\r%!"
      (to_int real)
      (to_int delay)
      (to_int frame)
      (to_int actual_fps)

  let update_time, render_time, print_time =
    let open Int32 in
    let ttime = ref 0l in
    let rtime = ref 0l in
    let real  = ref 0l in
    let step  = ref 0l in
    let delay = ref 0l in
    let frame = ref 0l in
    (fun () ->
       let ctime = Sdl.get_ticks () in
       frame := ctime - !ttime;
       delay := (!delay + (wait_time - !frame)) / (of_int 2);
       step :=
         if 0l <= !delay
         then max 1l !frame
         else min 100l !frame;
       ttime := ctime;
       !delay, !step, !ttime),
    (fun () ->
       rtime := Sdl.get_ticks ();
       real := !rtime - !ttime;
       !rtime),
    (fun () -> ptime !real !delay !frame)

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
    let s, send_s = React.S.create None in
    let handle sdl_e_opt =
      Option.map (flip Sdl.Event.get field) sdl_e_opt
      |> send_s in
    EventsH.replace events_s_table ty (handle :: handlers);
    s

  let send_events ev =
    Sdl.pump_events ();
    let received = EventsH.map (fun _ _ -> false) events_s_table in
    while Sdl.poll_event (Some ev) do
      if Sdl.Event.(get ev typ = quit) then do_quit := true;
      let event_typ = Sdl.Event.(get ev typ) in
      try EventsH.find events_table event_typ |> List.iter ((|>) ev)
      with Not_found -> ();
        try EventsH.find events_s_table event_typ
            |> List.iter ((|>) (Some ev));
          EventsH.replace received event_typ true;
        with Not_found -> ();
    done;
    EventsH.iter (fun event_typ b ->
        if b = false then
          EventsH.find events_s_table event_typ
          |> List.iter ((|>) None)
      ) received

  let quit () =
    let e = Sdl.Event.create () in
    Sdl.Event.set e Sdl.Event.typ Sdl.Event.quit;
    Sdl.push_event e |> ignore

  (* Main event loop **********************************************************)

  let event_loop r w =
    let open Int32 in
    let open Sdl_result in
    let ev = Sdl.Event.create () in
    let rec loop () =
      let delay, frame, total = update_time () in
      send_events ev;
      send_tick { frame_time = frame; total_time = total };
      if delay > zero then Sdl.delay (delay / (of_int 2));
      Sdl.render_present r;
      ignore (Gc.major_slice 0);
      send_post_render { frame_time = frame; total_time = render_time () };
      Sdl.render_clear r >>= fun () ->
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
