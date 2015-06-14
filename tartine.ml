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

type t = private { renderer: Sdl.renderer; window: Sdl.window }

module EltsH = Hashtbl.Make (struct
  type t = Elt.t
  let hash e = Hashtbl.hash e.id
end)

module EventsH = Hashtbl.Make (struct
  type t = Sdl.event_type
  let hash = Hashtbl.hash
end)


let elts_table = EltsH.create 255
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
let step, send_step = React.S.create 0l
let st_ref = ref None
let st () = match !st_ref with
  | None -> failwith "st: Engine not running"
  | Some t -> t

let fps = 60.
let wait_time = 1000. /. fps
let current_time = 0l
let delay = ref 0.

let event_loop renderer =
  let ev = Event.create () in
  let rec loop () =
    send_tick ();
    Sdl.pump_events ();
    while Sdl.poll_event (Some ev) do
      try EventsH.find events_table Sdl.Event.(get ev typ)
          |> List.iter ((|>) ev)
      with Not_found -> ()
    done;
    let tm = Sdl.get_ticks () in
    delay := Int32.(!delay + (wait_time - (tm - !current_time)));
    send_step (if 0l <= delay then
                 Int32.(max 1l delay) else
                 Int32.(min 100l delay));
    Sdl.render_present renderer;
    current_time := Sdl.get_ticks ()
  in
  loop ()

let run ~w ~h ?(fullscreen = false) ?(flags = Sdl.Window.opengl) () =
  let open Operators in
  Sdl.init Sdl.Init.everything >>= fun () ->
  Sdl.set_hint Sdl.Hint.render_vsync "1" |> ignore;
  Sdl.set_hint Sdl.Hint.render_scale_quality "nearest" |> ignore;
  
  Sdl.create_window_and_renderer ~w ~h
    (if fullscreen then Sdl.Window.(fullscreen + flags) else flags) >>= fun (w, r) ->

  st_ref := { renderer = r; window = w };
  event_loop r;

  Sdl.destroy_renderer r;
  Sdl.destroy_window w;
  Image.quit ();
  Sdl.quit ();
  `Ok ()
