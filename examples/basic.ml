open Batteries
open Tsdl
open Gg
open Tartine

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = 640
    let h = 480
  end)

open T.Utils.Sdl_result

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let wasd keys step pos =
  T.Key.wasd keys
  |> V2.smul step
  |> V2.add pos

let move_square = wasd Scancode.(up, left, down, right)
let move_camera = wasd Scancode.(w, a, s, d)

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

let imgstore = T.ImageStore.load "examples/images"

let main =
  T.Engine.tick
  |> React.E.map (
    let square = T.ImageStore.find "square" imgstore in
    let map = T.ImageStore.find "discworld_map" imgstore in
    let square_pos, camera_pos = ref V2.(v 150. 150.), ref V2.zero in
    let square_size = Size2.v 64. 48. in
    fun tm ->
      let step = (Int32.to_float tm.T.Engine.frame_time) /. 2. in
      square_pos := move_square step !square_pos;
      camera_pos := move_camera step !camera_pos;
      camera_pos := T.Camera.follow ~pos:!camera_pos ~border:100.
          (!square_pos, square_size);
      let camera_transform = T.Camera.transform ~pos:!camera_pos in
      T.Screen.(render map ~pos:V2.zero camera_transform) >>= fun () ->
      T.Screen.(render square ~pos:!square_pos ~size:square_size camera_transform))

let () = T.Engine.run ()
