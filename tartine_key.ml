open Tsdl
open Gg
open Batteries
open Sigs

module Make (Engine: Engine_sig) = struct
  let keyboard_st = ref (Sdl.get_keyboard_state ())

  let update_keyboard_st =
    Engine.tick |> React.E.map (fun _ ->
      keyboard_st := Sdl.get_keyboard_state ()
    )

  let s scancode = (Bigarray.Array1.get !keyboard_st scancode = 1)
  let k keycode = s (Sdl.get_scancode_from_key keycode)

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
    let down : [`Key_up | `Key_down] option React.S.t =
      Engine.event_this_frame Sdl.Event.key_down Sdl.Event.keyboard_scancode
      |> React.S.map (fun sc -> if sc = Some scancode then Some `Key_down else None) in

    let up : [`Key_up | `Key_down] option React.S.t =
      Engine.event_this_frame Sdl.Event.key_up Sdl.Event.keyboard_scancode
      |> React.S.map (fun sc -> if sc = Some scancode then Some `Key_up else None) in

    React.S.merge (fun o o' -> match o' with Some _ -> o' | _ -> o)
      None [down; up]

  let k_event_this_frame keycode =
    s_event_this_frame (Sdl.get_scancode_from_key keycode)


  let v2_normalize v =
    if v <> V2.zero then V2.unit v else v

  let wasd (w, a, _s, d) =
    [(a, V2.neg V2.ox); (d, V2.ox); (w, V2.neg V2.oy); (_s, V2.oy)]
    |> List.map (fun (code, v) -> if s code then v else V2.zero)
    |> List.fold_left V2.add V2.zero
    |> v2_normalize
end
