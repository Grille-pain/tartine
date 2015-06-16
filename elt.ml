open Tsdl
open Gg
open Tartine
open Prelude.Sdl_result

type t = {
  id: int;
  src: Box2.t;
  scale: float;
  angle: float;
  center: V2.t;
  hflip: bool; vflip: bool;

  image: Image.t;
}

let box2_to_sdl rect =
  let x = truncate @@ Box2.ox rect in
  let y = truncate @@ Box2.oy rect in
  let w = truncate @@ Box2.w rect in
  let h = truncate @@ Box2.h rect in
  Sdl.Rect.create ~x ~y ~w ~h

let box2_from_sdl rect =
  let x = float @@ Sdl.Rect.x rect in
  let y = float @@ Sdl.Rect.y rect in
  let w = float @@ Sdl.Rect.w rect in
  let h = float @@ Sdl.Rect.h rect in
  Box2.v (V2.v x y) (Size2.v w h)

let v2_to_sdl (point: V2.t) =
  let x = truncate (V2.x point) in
  let y = truncate (V2.y point) in
  Sdl.Point.create ~x ~y

let fresh =
  let i = ref 0 in
  fun () -> incr i; !i

let create i =
  let (w,h) = Sdl.get_surface_size i.Image.surface in
  {
    id = fresh ();
    src = Box2.v (V2.v 0. 0.) (Size2.v (float w) (float h));
    scale = 1.;
    angle = 0.;
    center = V2.v (float (w / 2)) (float (h / 2));
    hflip = false; vflip = false;

    image = i;
  }

let src src t = { t with src }
let scale scale t = { t with scale }
let angle angle t = { t with angle }
let center center t = { t with center }
let hflip hflip t = { t with hflip }
let vflip vflip t = { t with vflip }
let reset_transform t = 
  let (w,h) = Sdl.get_surface_size t.image.Image.surface in
  { t with
    angle = 0.;
    center = V2.v (float (w / 2)) (float (h / 2));
    hflip = false; vflip = false
  }

let render t elt ~dst =
  let src = box2_to_sdl elt.src in
  let dst = box2_to_sdl dst in
  let center = Some (v2_to_sdl elt.center) in
  let flip =
    Sdl.Flip.
      ((if elt.hflip then Sdl.Flip.horizontal else Sdl.Flip.none)
       + (if elt.vflip then Sdl.Flip.vertical else Sdl.Flip.none))
  in
  if elt.angle < 1. && elt.angle > -1. then
    Sdl.render_copy_ex
      ~src ~dst
      t.renderer elt.image.Image.texture
      elt.angle center flip
  else
    Sdl.render_copy
      ~src ~dst
      t.renderer elt.image.Image.texture
