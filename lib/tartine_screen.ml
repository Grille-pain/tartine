open Tsdl
open Gg
open Sigs

module Make
    (Engine: Engine_sig)
    (Image: Image_sig) =
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

  type t = unit

  let default = React.S.const ()

  let render img
      ?(src=Box2.v V2.zero img.Image.size)
      ?(dst=V2.zero)
      ?(transform=Image.default (Box2.size src))
      () =
    let dst = box2_to_sdl
        (Box2.v dst
           Size2.(v ((Box2.w src) *. transform.Image.wscale)
                    ((Box2.h src) *. transform.Image.hscale))) in
    let src = box2_to_sdl src in
    let center = Some (v2_to_sdl transform.Image.center) in
    let flip =
      Sdl.Flip.(+)
        (if transform.Image.hflip then Sdl.Flip.horizontal else Sdl.Flip.none)
        (if transform.Image.vflip then Sdl.Flip.vertical else Sdl.Flip.none)
    in
    Engine.{ texture = img.Image.texture; src; dst; angle = transform.Image.angle; center; flip }
(*
    Sdl.render_copy_ex
      ~src ~dst
      Engine.renderer img.Image.texture
      transform.Image.angle center flip
*)
end
