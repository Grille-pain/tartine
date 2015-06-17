open Tsdl

let keyboard_st = ref (Sdl.get_keyboard_state ())

let update_keyboard_st =
  Tartine_engine.tick
  |> React.E.map (fun _ ->
    keyboard_st := Sdl.get_keyboard_state ()
  )

let s scancode = (Bigarray.Array1.get !keyboard_st scancode = 1)
let k keycode = s (Sdl.get_scancode_from_key keycode)

let s_event scancode =
  let down : [`Key_up | `Key_down] React.E.t = 
    Tartine_engine.event Sdl.Event.key_down Sdl.Event.keyboard_scancode
    |> React.E.fmap (fun sc -> if sc = scancode then Some `Key_down else None) in

  let up : [`Key_up | `Key_down] React.E.t = 
    Tartine_engine.event Sdl.Event.key_down Sdl.Event.keyboard_scancode
    |> React.E.fmap (fun sc -> if sc = scancode then Some `Key_up else None) in

  React.E.select [down; up]

let k_event keycode = s_event (Sdl.get_scancode_from_key keycode)
