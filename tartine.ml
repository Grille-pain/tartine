open Tsdl
open Prelude

module Operators = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | `Ok x -> f x
    | `Error err -> `Error err

  let return x = `Ok x
end

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

type t = { renderer: Sdl.renderer;
           window: Sdl.window;
           frame_time: int32;
           total_time: int32; }

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

let tick, send_tick = React.E.create ()

let fps = 60l
let wait_time = Int32.(1000l / fps)
let delay = ref 0l
let step = ref wait_time

let event_loop r w =
  let open Operators in
  let ev = Sdl.Event.create () in
  let rec loop () =
    let start_time = Sdl.get_ticks () in
    let quit = ref false in
    Sdl.pump_events ();
    while Sdl.poll_event (Some ev) do
      if Sdl.Event.(get ev typ = quit) then quit := true;
      try EventsH.find events_table Sdl.Event.(get ev typ)
          |> List.iter ((|>) ev)
      with Not_found -> ()
    done;
    send_tick { renderer = r;
                window = w;
                frame_time = !step;
                total_time = start_time; };
    let end_time = Sdl.get_ticks () in
    delay := Int32.(!delay + (wait_time - (end_time - start_time)));
    step :=
      if 0l <= !delay
      then Int32.(max 1l !delay)
      else Int32.(min 100l !delay);
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
    Sdl.set_hint Sdl.Hint.render_vsync "1" |> ignore;
    Sdl.set_hint Sdl.Hint.render_scale_quality "nearest" |> ignore;

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
