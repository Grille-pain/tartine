open Tsdl
open Tartine.Operators

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let cache opt str t =
  match !opt with
  | None -> begin
      match Image.load t str with
      | `Error e -> `Error e
      | `Ok i ->
        let elt = Elt.create i in
        opt := Some elt; `Ok elt
    end
  | Some elt -> `Ok elt

let background =
  let opt = ref None in
  cache opt "examples/images/background.bmp"

let square =
  let opt = ref None in
  cache opt "examples/images/square.bmp"

let on_escape =
  let handle ev =
    match Scancode.enum ev with
    | `Escape -> Tartine.quit ()
    | _ -> ()
  in
  Tartine.event Event.key_down Event.keyboard_scancode
  |> React.E.map handle

let on_move =
  let handle r ev =
    match Scancode.enum ev with
    | `W -> Tartine.{ r with y = r.y -. 10. }
    | `A -> Tartine.{ r with x = r.x -. 10. }
    | `S -> Tartine.{ r with y = r.y +. 10. }
    | `D -> Tartine.{ r with x = r.x +. 10. }
    | _ -> r
  in
  Tartine.event Event.key_down Event.keyboard_scancode
  |> React.S.fold handle Tartine.{ x = 0.; y = 0.; w = 64.; h = 48.}

let on_tick =
  let handle t =
    background t >>= fun b ->
    let dst = b.Elt.src in
    Elt.render t b dst >>= fun () ->
    square t >>= fun s ->
    let dst = React.S.value on_move in
    Elt.render t s dst
  in
  React.E.map handle Tartine.tick

let () =
  Tartine.run ~w:640 ~h:480 ()
