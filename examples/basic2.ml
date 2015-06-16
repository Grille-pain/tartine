open Tsdl
open Tartine.Operators

module Event = Sdl.Event
module Scancode = Sdl.Scancode

let update_position step (rect: Tartine.rect): Tartine.rect =
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

let tick =
  Tartine.tick
  |> Prelude.event_map_init
    (fun st ->
       (* load images *)
       handle_error (fun msg -> Printf.eprintf "%s\n" msg; exit 1) (
         Image.load st "examples/images/background.bmp" >>= fun b ->
         Image.load st "examples/images/square.bmp" >>= fun s ->
         return (Elt.create b, Elt.create s)
       ))

    (fun (background, square) ->
       let square_dst = ref Tartine.{ x = 0.; y = 0.; w = 64.; h = 48. } in
       fun st ->
         let step = (Int32.to_float st.Tartine.frame_time) /. 2. in 
         square_dst := update_position step !square_dst;
         Elt.render st background background.Elt.src >>= fun () ->
         Elt.render st square !square_dst)

let () = Tartine.run ~w:640 ~h:480 ()
