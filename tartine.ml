open Tsdl
open Prelude

module Operators = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | `Ok x -> f x
    | `Error err -> `Error err

  let handle_error (type a)
      (f: string -> a)
      (r: a Sdl.result): a =
    match r with
    | `Ok x -> x
    | `Error err -> f err

  let return x = `Ok x
end


let fps = 60l
let wait_time = Int32.(1000l / fps)
(* How much slower do we need to refresh textual debug informations?
   (eg. displayed fps, etc.) *)
let printing_speed_ratio = 3

type point = {
  x: float;
  y: float;
}

type rect = {
  x: float;
  y: float;
  w: float;
  h: float;
}

type t = {
  renderer: Sdl.renderer;
  window: Sdl.window;
  frame_time: int32;
  total_time: int32;
}


module EventsH = Hashtbl.Make (struct
    type t = Sdl.event_type
    let hash = Hashtbl.hash
    let equal = (=)
  end)

let events_table = EventsH.create 255

let event ty field =
  let handlers =
    try EventsH.find events_table ty with Not_found -> []
  in
  let e, send_e = React.E.create () in
  EventsH.replace events_table ty
    ((fun sdl_e -> Sdl.Event.get sdl_e field |> send_e) :: handlers);
  e

let quit = ref false

let send_events ev =
  Sdl.pump_events ();
  while Sdl.poll_event (Some ev) do
    if Sdl.Event.(get ev typ = quit) then quit := true;
    try EventsH.find events_table Sdl.Event.(get ev typ)
        |> List.iter ((|>) ev)
    with Not_found -> ()
  done


let ptime step delay frame =
  let open Int32 in
  let actual_fps = (fps * fps * frame) / 1000l in
  Printf.printf "% 8i% 8i% 8i (%d fps)\r%!"
    (to_int step)
    (to_int delay)
    (to_int frame)
    (to_int actual_fps)

let update_time, print_time =
  let open Int32 in
  let stime = ref 0l in
  let etime = ref 0l in
  let delay = ref 0l in
  let step  = ref 0l in
  let frame_time = ref 0l in
  (fun () ->
     etime := Sdl.get_ticks ();
     frame_time := !etime - !stime;
     delay := (!delay + (wait_time - !frame_time)) / (of_int 2);
     step :=
       if 0l <= !delay
       then max 1l !frame_time
       else min 100l !frame_time;
     stime := Sdl.get_ticks ();
     !delay, !step, !stime),
  (fun () -> ptime !step !delay !frame_time)

let slow_print_time =
  let tick_count = ref 0 in
  fun st ->
    if !tick_count >= printing_speed_ratio then (
      tick_count := 0;
      print_time ()
    ); incr tick_count;
    st

let tick, send_tick =
  let tick, send_tick = React.E.create () in
  React.E.map slow_print_time tick, send_tick

let send_tick r w frame total =
  send_tick {
    renderer = r;
    window = w;
    frame_time = frame;
    total_time = total;
  }

let event_loop r w =
  let open Int32 in
  let open Operators in
  let ev = Sdl.Event.create () in
  let rec loop () =
    let delay, frame, total = update_time () in
    send_events ev;
    send_tick r w frame total;
    if delay > zero then Sdl.delay (delay / (of_int 2));
    Sdl.render_present r;
    Sdl.render_clear r >>= fun () ->
    if not !quit then loop () else return ();
  in
  loop ()


let run ~w ~h ?(fullscreen = false) ?(flags = Sdl.Window.opengl) () =
  let open Operators in
  let main () =
    Sdl.init Sdl.Init.everything >>= fun () ->
    (* Tsdl_image.Image.init Tsdl_image.Image.Init.(png + jpg) |> ignore; *)
    if (Sdl.set_hint Sdl.Hint.render_vsync "1")
    then print_endline "vsync: success"
    else print_endline "vsync: failure";
    if (Sdl.set_hint Sdl.Hint.render_scale_quality "nearest")
    then print_endline "scale quality: success"
    else print_endline "scale quality: failure";

    Sdl.create_window_and_renderer ~w ~h
      (if fullscreen then Sdl.Window.(fullscreen + flags) else flags) >>= fun (w, r) ->

    event_loop r w >>= fun () ->

    Sdl.destroy_renderer r;
    Sdl.destroy_window w;
    (* Tsdl_image.Image.quit (); *)
    Sdl.quit ();
    `Ok ()
  in
  match main () with
  | `Ok () -> ()
  | `Error err -> Printf.eprintf "%s\n%!" err

let quit () =
  let e = Sdl.Event.create () in
  Sdl.Event.set e Sdl.Event.typ Sdl.Event.quit;
  Sdl.push_event e |> ignore
