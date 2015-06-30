open Batteries
open Tsdl
open Gg
open Tartine
open Utils.Sdl_result

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let wasd keys step pos =
  Tartine.Key.wasd keys
  |> V2.smul step
  |> V2.add pos

let move_square = wasd Scancode.(up, left, down, right)
let move_camera = wasd Scancode.(w, a, s, d)

let escape =
  Key.s_event Scancode.escape |> React.E.map (fun _ -> Engine.quit ())


let b = ref false

let event =
  Key.s_event Scancode.f12
  |> React.E.map (function
        `Key_up -> b := true
      | `Key_down -> ())

let screenshot =
  Engine.post_render
  |> React.E.map (fun t -> if !b then
                     Screenshot.take t
                     |> handle_error print_endline;
                   b := false)

let main =
  Engine.tick
  |> Utils.event_map_init
    (fun st -> ImageStore.load st "examples/images")

    (fun imgstore ->
       let square = ImageStore.find "square" imgstore in
       let map = ImageStore.find "discworld_map" imgstore in
       let square_pos, camera_pos = ref V2.(v 150. 150.), ref V2.zero in
       let square_size = Size2.v 64. 48. in
       fun st ->
         let step = (Int32.to_float st.Engine.frame_time) /. 2. in
         square_pos := move_square step !square_pos;
         camera_pos := move_camera step !camera_pos;
         camera_pos := Camera.follow st ~pos:!camera_pos ~border:100. (!square_pos, square_size);
         let camera_transform = Camera.transform st ~pos:!camera_pos in
         Screen.(render st map ~pos:V2.zero camera_transform) >>= fun () ->
         Screen.(render st square ~pos:!square_pos ~size:square_size camera_transform))

let () = Engine.run ~flags:Sdl.Window.resizable ~w:640 ~h:480 ()
