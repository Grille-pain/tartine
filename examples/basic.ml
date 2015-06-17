open Batteries
open Tsdl
open Gg
open Tartine
open Utils.Sdl_result

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let v2_normalize v =
  if v <> V2.zero then V2.unit v else v

let update_position step (pos: V2.t): V2.t =
  let open Scancode in
  [(left, V2.neg V2.ox); (right, V2.ox); (up, V2.neg V2.oy); (down, V2.oy)]
  |> List.map (fun (code, v) -> if Key.s code then v else V2.zero)
  |> List.fold_left V2.add V2.zero
  |> v2_normalize
  |> V2.smul step
  |> V2.add pos

let escape =
  Key.s_event Scancode.escape |> React.E.map (fun _ -> Engine.quit ())

let main =
  Engine.tick
  |> Utils.event_map_init
    (fun st -> ImageStore.load st "examples/images")

    (fun imgstore ->
       let background = ImageStore.find "background" imgstore in
       let square = ImageStore.find "square" imgstore in
       let square_pos = ref V2.zero in
       let square_size = Size2.v 64. 48. in
       fun st ->
         let step = (Int32.to_float st.Engine.frame_time) /. 2. in
         square_pos := update_position step !square_pos;
         Screen.(render st background ~pos:V2.zero no_transform) >>= fun () ->
         Screen.(render st square ~pos:!square_pos ~size:square_size no_transform))

let () = Engine.run ~w:640 ~h:480 ()
