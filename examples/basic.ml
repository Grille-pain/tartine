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
    | `S -> Tartine.{ r with y = r.y +. 10. }
    | `A -> Tartine.{ r with x = r.x -. 10. }
    | `D -> Tartine.{ r with x = r.x +. 10. }
    | _ -> r
  in
  Tartine.event Event.key_down Event.keyboard_scancode
  |> React.S.fold handle Tartine.{ x = 0.; y = 0.; w = 64.; h = 48.}

let on_state r st big =
  let is_press sc =
    Bigarray.Array1.get big sc = 1
  in
  let x, y =
    Scancode.(
      (if is_press up then (0., -.st) else (0., 0.))
      |> (fun (x,y) -> if is_press down then (x, y +. st) else (x, y))
      |> (fun (x,y) -> if is_press left then (x -. st, y) else (x, y))
      |> (fun (x,y) -> if is_press right then (x +. st, y) else (x, y))
      |> (fun (x,y) ->
          if x <> 0. && y <> 0.
          then x /. (sqrt 2.), y /. (sqrt 2.)
          else x, y))
  in Tartine.{ r with x = r.x +. x; y = r.y +. y }

let update_state =
  let r = ref Tartine.{ x = 0.; y = 0.; w = 64.; h = 48.} in
  fun st big -> r := on_state !r st big; !r

let on_tick =
  let handle t =
    background t >>= fun b ->
    let dst = b.Elt.src in
    Elt.render t b dst >>= fun () ->
    square t >>= fun s ->
    (*  let dst = React.S.value on_move in *)
    let big = Sdl.get_keyboard_state () in
    let st = (Int32.to_float t.Tartine.frame_time) /. 2. in
    let dst = update_state st big in
    Elt.render t s dst
  in
  React.E.map handle Tartine.tick

let () =
  Tartine.run ~w:640 ~h:480 ()
