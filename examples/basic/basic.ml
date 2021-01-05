open Tsdl
open Gg

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = 640
    let h = 480
  end)

open T.Utils.Sdl_result

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let step time = (Int32.to_float time.T.Engine.frame_time) /. 2.

let arrows =
  T.Key.wasd Scancode.(up, left, down, right)
  |> React.S.map (fun v -> if v <> V2.zero then V2.unit v else v)

let wasd =
  T.Key.wasd Scancode.(w, a, s, d)
  |> React.S.map (fun v -> if v <> V2.zero then V2.unit v else v)

let escape =
  T.Key.s_event Scancode.escape |> React.E.map (fun _ -> T.Engine.quit ())

let f12 = T.Key.s_event_this_frame Scancode.f12

let screenshot =
  T.Engine.post_render
  |> React.E.map (fun _ ->
      match React.S.value f12 with
      | Some `Key_down ->
        T.Screenshot.take () |> handle_error print_endline
      | _ -> ())

let imgstore = T.ImageStore.load "examples/basic/"

let square = T.ImageStore.find "square" imgstore
let map = T.ImageStore.find "discworld_map" imgstore

let box =
  React.S.fold
    (fun box time ->
       Box2.move (V2.smul (step time) (React.S.value wasd)) box)
    (Box2.v (V2.v 150. 150.) square.T.Image.size)
    T.Engine.tick

let camera =
  React.S.fold
    (fun camera time ->
       let box = React.S.value box in
       camera
       |> T.Camera.shift_by (V2.smul (step time) (React.S.value arrows))
       |> T.Camera.follow ~border:(V2.smul 2. (Box2.size box)) (Box2.mid box))
    (React.S.value T.Camera.default)
    T.Engine.tick

let main =
  React.S.l3
    (fun box camera _ ->
       T.Camera.render map camera >>= fun () ->
       T.Camera.render square ~dst:(Box2.o box) camera)
    box camera T.Engine.time

let () = T.Engine.run ()
