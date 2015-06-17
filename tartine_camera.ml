open Tsdl
open Gg
open Batteries
open Tartine_screen

let window_size engine =
  Sdl.get_window_size engine.Tartine_engine.window
  |> Tuple2.mapn Float.of_int

let default_size engine =
  window_size engine |> uncurry Size2.v

let transform engine ~pos ?size elt =
  let (ww, wh) = window_size engine in
  let size = size |? Size2.v ww wh in
  { elt with
    dst =
      Box2.v
        V2.((Box2.o elt.dst) - pos)
        Size2.(v ((Box2.w elt.dst) *. (ww /. (Size2.w size)))
                 ((Box2.h elt.dst) *. (wh /. (Size2.h size))));
  }
  
let box2_subset b b' =
  (Box2.ox b' <= Box2.ox b) &&
  (Box2.oy b' <= Box2.oy b) &&
  (Box2.maxx b <= Box2.maxx b') &&
  (Box2.maxy b <= Box2.maxy b')

let follow engine ~pos ?size ~border (elt_pos, elt_size) =
  let e = Box2.v elt_pos elt_size in
  let size = size |? default_size engine in
  (* sanity check *)
  if border >= (Size2.w size -. (Box2.w e)) /. 2. ||
     border >= (Size2.h size -. (Box2.h e)) /. 2. then
    (* safe solution: do not move *)
    pos
  else
    let follow_box = Box2.v V2.(pos + (v border border)) 
                            Size2.(v (Size2.w size -. 2. *. border)
                                     (Size2.h size -. 2. *. border)) in
    if box2_subset e follow_box then
      pos
    else
      let offset_x =
        let dl = Box2.ox follow_box -. (Box2.ox e) in
        let dr = Box2.maxx e -. (Box2.maxx follow_box) in
        if dl >= 0. then -. dl
        else if dr >= 0. then dr
        else 0. in
      let offset_y =
        let du = Box2.oy follow_box -. (Box2.oy e) in
        let dd = Box2.maxy e -. (Box2.maxy follow_box) in
        if du >= 0. then -. du
        else if dd >= 0. then dd
        else 0. in
      V2.add V2.(v offset_x offset_y) pos
