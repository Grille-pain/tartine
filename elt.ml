open Tsdl

open Tartine
open Operators

type t = {
  id: int;
  src: rect;
  scale: float;
  angle: float;
  center: point;
  hflip: bool; vflip: bool;

  image: Image.t;
}

let rect_to_sdl rect =
  let x = truncate rect.x in
  let y = truncate rect.y in
  let w = truncate rect.w in
  let h = truncate rect.h in
  Sdl.Rect.create ~x ~y ~w ~h

let rect_from_sdl rect =
  let x = float @@ Sdl.Rect.x rect in
  let y = float @@ Sdl.Rect.y rect in
  let w = float @@ Sdl.Rect.w rect in
  let h = float @@ Sdl.Rect.h rect in
  { x; y; w; h }

let point_to_sdl (point : Tartine.point) =
  let x = truncate point.x in
  let y = truncate point.y in
  Sdl.Point.create ~x ~y

let fresh =
  let i = ref 0 in
  fun () -> incr i; !i

let create i =
  let (w,h) = Sdl.get_surface_size i.Image.surface in
  {
    id = fresh ();
    src = { x = 0.; y = 0.; w = float w; h = float h};
    scale = 1.;
    angle = 0.;
    center = { x = float (w / 2); y = float (h /2) };
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
    center = { x = float (w / 2); y = float (h / 2) };
    hflip = false; vflip = false
  }

let render t elt ~dst =
  let src = rect_to_sdl elt.src in
  let dst = rect_to_sdl dst in
  let center = Some (point_to_sdl elt.center) in
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
