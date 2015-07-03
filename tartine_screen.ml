open Tsdl
open Gg
open Batteries
open Sigs

module Make
    (Engine: Engine_sig)
    (Image: Image_sig) =
struct

  type elt = {
    dst: Box2.t;

    center: V2.t;
    angle: float;
    hflip: bool;
    vflip: bool;
  }

  type transform = elt -> elt

  let no_transform e = e

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

  let render img ~pos ?src ?size transform =
    let open Engine in
    let src = src |? Box2.v V2.zero img.Image.size |> box2_to_sdl in
    let size = size |? img.Image.size in
    let elt = transform {
      dst = Box2.v pos size;
      center = V2.smul 0.5 size;
      angle = 0.;
      hflip = false;
      vflip = false;
    } in

    let dst = box2_to_sdl elt.dst in
    let center = Some (v2_to_sdl elt.center) in
    let flip = Sdl.Flip.(
      (if elt.hflip then Sdl.Flip.horizontal else Sdl.Flip.none)
      + (if elt.vflip then Sdl.Flip.vertical else Sdl.Flip.none)
    ) in

    if Float.abs elt.angle < 0.01 && flip = Sdl.Flip.none then
      Sdl.render_copy ~src ~dst Engine.renderer
        img.Image.texture
    else
      Sdl.render_copy_ex
        ~src ~dst
        Engine.renderer img.Image.texture
        elt.angle center flip
end
