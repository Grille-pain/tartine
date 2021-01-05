open Tsdl
open Gg
open Sigs

module Make
    (Engine: Engine_sig)
    (Image: Image_sig)
    (Screen: Screen_sig
     with type image_t := Image.t
      and type transform_t := Image.transform) =
struct

  let get_window_size () =
    let w,h = Sdl.get_window_size Engine.window in
    Size2.v (float w) (float h)

  let window_size =
    React.S.hold
      (get_window_size ())
      (Engine.event Sdl.Event.window_event Sdl.Event.window_event_id
       |> React.E.filter ((=) Sdl.Event.window_event_size_changed)
       |> React.E.map (fun _ -> get_window_size ()))

  type t = Box2.t

  let default =
    React.S.map (Box2.v V2.zero) window_size

  let move_to v t = Box2.v v (Box2.size t)

  let shift_by v t = Box2.move v t

  let resize s t = Box2.v (Box2.o t) s

  let follow pos ?(border=Size2.v infinity infinity) t =
    let border =
      Box2.v_mid pos
        (Size2.v
           (min (Box2.w t) (Size2.w border))
           (min (Box2.h t) (Size2.h border)))
    in
    let x =
      if Box2.maxx border > Box2.maxx t then Box2.maxx border -. Box2.maxx t
      else if Box2.minx border < Box2.minx t then Box2.minx border -. Box2.minx t
      else 0.
    in
    let y =
      if Box2.maxy border > Box2.maxy t then Box2.maxy border -. Box2.maxy t
      else if Box2.miny border < Box2.miny t then Box2.miny border -. Box2.miny t
      else 0.
    in
    Box2.move (V2.v x y) t

  let render img
      ?(src=Box2.v V2.zero img.Image.size)
      ?(dst=V2.zero)
      ?(transform=Image.default (Box2.size src))
      camera =
    let window_size = React.S.value window_size in
    let camera_pos  = Box2.o camera in
    let camera_size = Box2.size camera in
    let wscale = Size2.((w window_size) /. (w camera_size)) in
    let hscale = Size2.((h window_size) /. (h camera_size)) in
    let transform = Image.{ transform with
                            wscale = transform.wscale *. wscale;
                            hscale = transform.hscale *. hscale }
    in
    let dst = V2.(mul (dst - camera_pos) (v wscale hscale)) in
    (* let dst = V2.(dst - camera_pos) in *)
    Screen.render img  ~src ~dst ~transform (React.S.value Screen.default)
end
