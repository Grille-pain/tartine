open Tsdl
open Sigs
open Tartine_utils

module Make (I: Init_sig) = struct
  (* How much slower do we need to refresh textual debug informations?
     (eg. displayed fps, etc.) *)
  let printing_speed = 100

  type time = { frame_time: int32; total_time: int32 }

  module SdlEventTable = Hashtbl.Make (struct
      type t = Sdl.event_type
      let hash = Hashtbl.hash
      let equal = (=)
    end)

  (* Time printing ************************************************************)

  let ptime tick =
    let open Int32 in
    let tick_fps = if tick.frame_time = 0l then 0l else 1000l / tick.frame_time in
    Printf.printf "% 4i (fps: % 4d)\r%!"
      (to_int tick.frame_time)
      (to_int tick_fps)

  let slow_print_time =
    let count = ref 0 in
    fun real tick ->
      if Int32.of_int (!count * printing_speed) < real.total_time then (
        incr count;
        ptime tick)

  (* Runtime data *************************************************************)

  let events_table = SdlEventTable.create 255
  let signals_table = SdlEventTable.create 255

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

  let real_tick, send_real_tick = React.E.create ()

  let tick =
    let open Int32 in
    React.E.fold (fun tick real_tick ->
        slow_print_time tick real_tick;
        let frame_time = (3l * tick.frame_time + real_tick.frame_time) / 4l in
        let total_time = tick.total_time + frame_time in
        { frame_time; total_time })
      { frame_time = 0l; total_time = 0l }
      real_tick

  let time = React.S.hold { frame_time = 0l; total_time = 0l } tick

  let post_render, send_post_render = React.E.create ()

  (****************************************************************************)

  let event ty field =
    let handlers =
      try SdlEventTable.find events_table ty with Not_found -> []
    in
    let e, send_e = React.E.create () in
    let handle sdl_e = Sdl.Event.get sdl_e field |> send_e in
    SdlEventTable.replace events_table ty (handle :: handlers);
    e

  let event_this_frame ty field =
    let handlers =
      try SdlEventTable.find signals_table ty with Not_found -> []
    in
    let s, send_s = React.S.create [] in
    let record_ev, send_recorded =
      let mem = ref [] in
      (fun sdl_e -> mem := (Sdl.Event.get sdl_e field) :: !mem),
      (fun () -> send_s !mem; mem := [])
    in
    SdlEventTable.replace signals_table ty
      ((record_ev, send_recorded) :: handlers);
    s

  let send_events ev =
    Sdl.pump_events ();
    while Sdl.poll_event (Some ev) do
      if Sdl.Event.(get ev typ = quit) then do_quit := true;
      let event_typ = Sdl.Event.(get ev typ) in
      (try SdlEventTable.find events_table event_typ |> List.iter ((|>) ev)
       with Not_found -> ());
      (try SdlEventTable.find signals_table event_typ
           |> List.map fst
           |> List.iter ((|>) ev);
       with Not_found -> ());
    done;
    SdlEventTable.iter (fun _ l ->
        List.iter (fun (_, send_recorded) -> send_recorded ()) l)
      signals_table

  let quit () =
    let e = Sdl.Event.create () in
    Sdl.Event.set e Sdl.Event.typ Sdl.Event.quit;
    Sdl.push_event e |> ignore

  (* Main event loop **********************************************************)

  let event_loop renderer _window =
    let open Sdl_result in
    let event = Sdl.Event.create () in
    let rec loop before after =
      let time = Int32.{ frame_time = max (after - before) 1l; total_time = after } in
      send_events event;
      send_real_tick time;
      send_post_render time;
      ignore (Gc.major_slice 0);
      Sdl.render_present renderer;
      Sdl.render_clear renderer >>= fun () ->
      Sdl.delay 1l;
      if not !do_quit then loop after (Sdl.get_ticks ()) else return ();
    in
    loop 0l (Sdl.get_ticks ())

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
