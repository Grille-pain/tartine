open Tsdl
open Gg
open Sigs

module Make (Engine: Engine_sig) = struct

  let s_is_pressed scancode = Engine.keyboard_state.(scancode)
  let k_is_pressed keycode = Engine.keyboard_state.(Sdl.get_scancode_from_key keycode)

  let s_event scancode =
    let down : [`Key_up | `Key_down] React.E.t =
      Engine.event Sdl.Event.key_down Sdl.Event.keyboard_scancode
      |> React.E.fmap (fun sc -> if sc = scancode then Some `Key_down else None) in

    let up : [`Key_up | `Key_down] React.E.t =
      Engine.event Sdl.Event.key_up Sdl.Event.keyboard_scancode
      |> React.E.fmap (fun sc -> if sc = scancode then Some `Key_up else None) in

    React.E.select [down; up]

  let k_event keycode = s_event (Sdl.get_scancode_from_key keycode)

  let s_event_this_frame scancode =
    let down : [`Key_up | `Key_down] list React.S.t =
      Engine.event_this_frame Sdl.Event.key_down Sdl.Event.keyboard_scancode
      |> React.S.map (fun l -> if List.mem scancode l then [`Key_down] else [])
    in
    let up : [`Key_up | `Key_down] list React.S.t =
      Engine.event_this_frame Sdl.Event.key_up Sdl.Event.keyboard_scancode
      |> React.S.map (fun l -> if List.mem scancode l then [`Key_up] else [])
    in
    React.S.merge (@) [] [down; up]

  let k_event_this_frame keycode =
    s_event_this_frame (Sdl.get_scancode_from_key keycode)

  let normalize v = if v <> V2.zero then V2.unit v else v

  let add_if bool x y = V2.add y (if bool then x else V2.zero)

  let wasd (w,a,s,d) =
    React.S.l4 (fun w a s d ->
        normalize
          V2.(zero
              + (if w then neg oy else zero)
              + (if a then neg ox else zero)
              + (if s then oy else zero)
              + (if d then ox else zero)))
      (s_is_pressed w)
      (s_is_pressed a)
      (s_is_pressed s)
      (s_is_pressed d)
end
