open Tsdl
open Sigs
open Tartine_utils

module Make (I: Init_sig) = struct
  (* Runtime data *************************************************************)

  let do_quit = ref false

  (* init sdl stuff *)
  let () =
    let open Sdl_result in
    handle_error failwith
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
      end

  let window, renderer =
    let open Sdl_result in
    handle_error failwith
      begin
        Sdl.create_window_and_renderer ~w:I.w ~h:I.h
          (if I.fullscreen then Sdl.Window.(fullscreen + I.flags) else I.flags)
      end

  (* Time, tick and tock ******************************************************)

  type time = { frame_time: int32; total_time: int32 }

  let eq t1 t2 =
    Int32.equal t1.total_time t2.total_time
    && Int32.equal t1.frame_time t2.frame_time

  (* How much slower do we need to refresh textual debug informations?
     (eg. displayed fps, etc.) *)
  let printing_speed = 100

  let ptime time =
    let open Int32 in
    let fps = if time.frame_time = 0l then 0l else 1000l / time.frame_time in
    Printf.printf "% 4i (fps: % 4d)\r%!"
      (to_int time.frame_time)
      (to_int fps)

  let slow_print_time =
    let count = ref 0 in
    fun real time ->
      if Int32.of_int (!count * printing_speed) < real.total_time then (
        incr count;
        ptime time)

  let real_time, send_real_time = React.E.create ()

  let time =
    React.S.fold ~eq
      Int32.(fun time real_time ->
          slow_print_time time real_time;
          let frame_time = (3l * time.frame_time + real_time.frame_time) / 4l in
          let total_time = time.total_time + frame_time in
          { frame_time; total_time })
      { frame_time = 0l; total_time = 0l }
      real_time

  let tick, send_tick = React.E.create ()
  let tock, send_tock = React.E.create ()

  (* SDL states and events ****************************************************)

  let keyboard_state, (keyboard_send: (step:React.step -> unit -> unit) array) =
    let bigarray = Sdl.get_keyboard_state () in
    let array =
      Array.init (Bigarray.Array1.dim bigarray)
        (fun int ->
           let s, send_s = React.S.create ~eq:(==) false in
           s, fun ~step () -> send_s ~step (Bigarray.Array1.get bigarray int > 0))
    in
    Array.map fst array,
    Array.map snd array

  let event, send_event = React.E.create ()
  let event_this_frame, send_event_this_frame = React.S.create ~eq:(==) []

  let filter_map_event ev ty field =
    if Sdl.Event.get ev Sdl.Event.typ = ty
    then Some (Sdl.Event.get ev field)
    else None

  let event (ty: Sdl.event_type) field =
    React.E.fmap (fun ev -> filter_map_event ev ty field)
      event

  let event_this_frame (ty: Sdl.event_type) field =
    React.S.map (fun list ->
        List.filter_map (fun ev -> filter_map_event ev ty field) list)
      event_this_frame

  let send_events ev =
    let list = ref [] in
    Sdl.pump_events ();
    while Sdl.poll_event (Some ev) do
      list := ev :: !list;
      match Sdl.Event.enum (Sdl.Event.get ev Sdl.Event.typ) with
      | `Quit -> do_quit := true; send_event ev
      | `Key_down | `Key_up ->
        let step = React.Step.create () in
        send_event ~step ev;
        keyboard_send.(Sdl.Event.get ev Sdl.Event.keyboard_scancode) ~step ();
        React.Step.execute step
      | _ -> send_event ev
    done;
    send_event_this_frame (List.rev !list);
    let step = React.Step.create () in
    Array.iter (fun send_s -> send_s ~step ()) keyboard_send;
    React.Step.execute step

  (* Renderable ***************************************************************)

  type renderable = {
    texture : Sdl.texture;
    src     : Sdl.rect;
    dst     : Sdl.rect;
    angle   : float;
    center  : Sdl.point option;
    flip    : Sdl.flip;
  }

  let to_be_render, render =
    let signal, send_signal = React.S.create ~eq:(==) (React.S.const []) in
    (React.S.switch signal),
    (fun signal -> send_signal signal)

  let iter_render_copy_ex renderer =
    List.iter (fun renderable ->
        Sdl_result.handle_error prerr_endline
          (Sdl.render_copy_ex
             renderer renderable.texture
             ~src:renderable.src ~dst:renderable.dst
             renderable.angle renderable.center renderable.flip))
      (React.S.value to_be_render)

  (* Main event loop **********************************************************)

  let event_loop renderer _window =
    let open Sdl_result in
    let event = Sdl.Event.create () in
    let rec loop before after =
      let time = Int32.{ frame_time = max (after - before) 1l; total_time = after } in
      Sdl.render_clear renderer >>= fun () ->
      send_real_time time;
      send_events event;
      send_tick ();
      iter_render_copy_ex renderer;
      ignore (Gc.major_slice 0);
      Sdl.delay 1l;
      Sdl.render_present renderer;
      send_tock ();
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
    Sdl_result.handle_error prerr_endline (event_loop renderer window);
    cleanup_and_quit renderer window

  let quit () =
    let e = Sdl.Event.create () in
    Sdl.Event.set e Sdl.Event.typ Sdl.Event.quit;
    ignore (Sdl.push_event e)

end
