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
  let keyboard_st = Sdl.get_keyboard_state () in
  let kk orient code =
    if Bigarray.Array1.get keyboard_st code = 1 then
      if orient then 1. else -1.
    else 0. in

  let open Scancode in
  V2.v ((kk false left) +. (kk true right)) ((kk false up) +. (kk true down))
  |> v2_normalize
  |> V2.smul step
  |> V2.add pos

let escape =
  Engine.event Event.key_down Event.keyboard_scancode
  |> React.E.map (fun ev ->
    if ev = Scancode.escape then
      Engine.quit ())

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
