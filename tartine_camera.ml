open Tsdl
open Gg
open Batteries
open Sigs

module Make
    (Engine: Engine_sig)
    (Image: Image_sig)
    (RenderTarget: RenderTarget_sig)
    (Screen: Screen_sig
     with type image_t := Image.t
     with type renderTarget_t := RenderTarget.t) =
struct
  let get_window_size () =
    Sdl.get_window_size Engine.window
    |> Tuple2.mapn Float.of_int
    |> uncurry Size2.v

  let window_size =
    React.S.hold
      (get_window_size ())
      (Engine.event Sdl.Event.window_event Sdl.Event.window_event_id
       |> React.E.filter ((=) Sdl.Event.window_event_size_changed)
       |> React.E.map (fun _ -> get_window_size ()))

  type t = Box2.t

  let with_screen_size ~pos =
    window_size
    |> React.S.map (Box2.v pos)

  let screen =
    window_size
    |> React.S.map (Box2.v V2.zero)

  let render cam ?src img target =
    let sz = get_window_size () in
    let ww, wh = Size2.w sz, Size2.h sz in
    let cam_pos = Box2.o cam in
    let cam_size = Box2.size cam in
    let scale_w = ww /. (Size2.w cam_size) in
    let scale_h = wh /. (Size2.h cam_size) in
    let target = RenderTarget.(
      target >>
      (fun p -> pos V2.(mul (p.pos - cam_pos) (v scale_w scale_h)) p) >>
      (fun p -> size Size2.(v ((Size2.w p.size) *. scale_w)
                              ((Size2.h p.size) *. scale_h))
          p)
    ) in
    Screen.render ?src img target
end
