open Tsdl
open Gg
open Batteries
open Tartine_screen

let transform engine ~pos ?size elt =
  let (ww, wh) = Sdl.get_window_size engine.Tartine_engine.window
                 |> Tuple2.mapn Float.of_int in
  let size = size |? Size2.v ww wh in
  { elt with
    dst =
      Box2.v
        V2.((Box2.o elt.dst) - pos)
        Size2.(v ((Box2.w elt.dst) *. (ww /. (Size2.w size)))
                 ((Box2.h elt.dst) *. (wh /. (Size2.h size))));
  }
  
