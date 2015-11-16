open Tsdl
open Gg
open Batteries
open Sigs

module Make
    (Engine: Engine_sig)
    (Image: Image_sig)
    (RenderTarget: RenderTarget_sig) =
struct
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

  let render ?src img target =
    let src = src |? Box2.v V2.zero img.Image.size |> box2_to_sdl in
    let p = target img.Image.size in
    
    let dst = box2_to_sdl (Box2.v
                             p.RenderTarget.pos
                             p.RenderTarget.size) in
    let center = Some (v2_to_sdl p.RenderTarget.center) in
    let flip = Sdl.Flip.(
      (if p.RenderTarget.hflip then Sdl.Flip.horizontal else Sdl.Flip.none)
      + (if p.RenderTarget.vflip then Sdl.Flip.vertical else Sdl.Flip.none)
    ) in

    if Float.abs p.RenderTarget.angle < 0.01 && flip = Sdl.Flip.none then
      Sdl.render_copy ~src ~dst Engine.renderer
        img.Image.texture
    else
      Sdl.render_copy_ex
        ~src ~dst
        Engine.renderer img.Image.texture
        p.RenderTarget.angle center flip
end
