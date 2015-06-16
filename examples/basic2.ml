open Batteries
open Tsdl
open Tartine.Operators

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let update_position (rect: Tartine.rect): Tartine.rect =
  let keyboard_st = Sdl.get_keyboard_state () in
  let kk offset code =
    if Bigarray.Array1.get keyboard_st code = 1 then offset else 0.
  in

  let x, y =
    let open Scancode in
    ((kk (-10.) left) +. (kk 10. right), (kk (-10.) up) +. (kk 10. down))
  in

  let offset_x, offset_y =
    if x <> 0. && y <> 0. then
      x /. (sqrt 2.), y /. (sqrt 2.) else
      x, y
  in
  Tartine.{ rect with x = rect.x +. offset_x; y = rect.y +. offset_y }

let escape =
  Tartine.event Event.key_down Event.keyboard_scancode
  |> React.E.map (fun ev ->
    if ev = Scancode.escape then
      Tartine.quit ())

let tick =
  Tartine.tick
  |> Prelude.event_map_init
    (fun st -> ImageStore.load st "examples/images"
               |> Hashtbl.map (const Elt.create))

    (fun imgstore ->
       let background = Hashtbl.find imgstore "background" in
       let square = Hashtbl.find imgstore "square" in
       let square_dst = ref Tartine.{ x = 0.; y = 0.; w = 64.; h = 48. } in
       fun st ->
         Printf.printf "\x1B[8D%ld%!" st.Tartine.frame_time;
         square_dst := update_position !square_dst;
         Elt.render st background background.Elt.src >>= fun () ->
         Elt.render st square !square_dst)

let () = Tartine.run ~w:640 ~h:480 ()
