open Batteries
open Tsdl
open Gg
open Tartine.Operators

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let v2_normalize v =
  if v <> V2.zero then V2.unit v else v

let update_position (rect: Box2.t): Box2.t =
  let keyboard_st = Sdl.get_keyboard_state () in
  let kk orient code =
    if Bigarray.Array1.get keyboard_st code = 1 then
      if orient then 1. else -1.
    else 0. in

  let open Scancode in
  V2.v ((kk false left) +. (kk true right)) ((kk false up) +. (kk true down))
  |> v2_normalize
  |> V2.smul 10.
  |> flip Box2.move rect

let escape =
  Tartine.event Event.key_down Event.keyboard_scancode
  |> React.E.map (fun ev ->
    if ev = Scancode.escape then
      Tartine.quit ())

let main =
  Tartine.tick
  |> Prelude.event_map_init
    (fun st -> ImageStore.load st "examples/images"
               |> Hashtbl.map (const Elt.create))

    (fun imgstore ->
       let background = Hashtbl.find imgstore "background" in
       let square = Hashtbl.find imgstore "square" in
       let square_dst = ref (Box2.v V2.zero Size2.(v 64. 48.)) in
       fun st ->
         Printf.printf "\x1B[8D%ld%!" st.Tartine.frame_time;
         square_dst := update_position !square_dst;
         Elt.render st background background.Elt.src >>= fun () ->
         Elt.render st square !square_dst)

let () = Tartine.run ~w:640 ~h:480 ()
