open Tsdl
open Gg
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
      |> React.S.map (fun l -> if List.mem scancode l then Some `Key_down else None) in

    let up : [`Key_up | `Key_down] option React.S.t =
      Engine.event_this_frame Sdl.Event.key_up Sdl.Event.keyboard_scancode
      |> React.S.map (fun l -> if List.mem scancode l then Some `Key_up else None) in

    React.S.merge (fun o o' -> match o' with Some _ -> o' | _ -> o)
      None [down; up]

  let k_event_this_frame keycode =
    s_event_this_frame (Sdl.get_scancode_from_key keycode)


  let v2_normalize v =
    if v <> V2.zero then V2.unit v else v

  let wasd_value (ww, aa, ss, dd) =
    [(aa, V2.neg V2.ox); (dd, V2.ox); (ww, V2.neg V2.oy); (ss, V2.oy)]
    |> List.map (fun (code, v) -> if s code then v else V2.zero)
    |> List.fold_left V2.add V2.zero

  let wasd (w,a,s,d as keys) =
    let w_e, a_e, s_e, d_e = s_event w, s_event a, s_event s, s_event d in
    let e = React.E.select [w_e; a_e; s_e; d_e] in
    React.S.fold (fun _ _ -> wasd_value keys) V2.zero e
end