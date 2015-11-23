open Tsdl
open Gg
open Batteries

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = 100
    let h = 100
  end)

open T.Utils.Sdl_result

let wait_time = ref 0l

let wait_more =
  T.Key.s_event Sdl.Scancode.right
  |> React.E.map (function `Key_down -> wait_time := Int32.(!wait_time + 1l)
                         | _ -> ())

let wait_less =
  T.Key.s_event Sdl.Scancode.left
  |> React.E.map (function `Key_down -> wait_time := max Int32.(!wait_time - 1l) 0l
                         | _ -> ())

let () = Random.self_init ()

let main =
  T.Engine.tick
  |> React.E.map (fun _ ->
    let tm = Random.int 5 |> Int32.of_int in
    Sdl.delay Int32.(!wait_time + tm)
  )

let () = T.Engine.run ()
