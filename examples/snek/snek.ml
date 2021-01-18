open Tsdl
open Gg

let map_w = 20
let map_h = 20
let block_size = 30

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = map_w * block_size
    let h = map_h * block_size
  end)

open T.Utils.Sdl_result

module M = Map.Make(Int)

let snake_block =
  T.Image.make
    ~w:block_size ~h:block_size Color.white
  |> handle_error failwith

let apple_block =
  T.Image.make
    ~w:block_size ~h:block_size Color.red
  |> handle_error failwith

let frames_per_tick = ref 20

let count =
  let count = ref 0 in
  React.E.fmap (fun _ ->
      if !count < !frames_per_tick
      then (incr count; None)
      else (count := 0; Some ()))
    T.Engine.tick

let arrows =
  React.S.fmap (fun u ->
      if V2.x u > 0. then Some V2.ox
      else if V2.x u < 0. then Some V2.(neg ox)
      else if V2.y u > 0. then Some V2.oy
      else if V2.y u < 0. then Some V2.(neg oy)
      else None)
    V2.ox
    (T.Key.wasd Sdl.Scancode.(up, left, down, right))

let pause =
  T.Key.k_event Sdl.K.space
  |> React.E.map (function `Key_down -> true | `Key_up -> false)
  |> React.S.hold false

type snek = {
  direction : V2.t;
  body      : V2.t M.t;
}

let initial = {
  direction = V2.ox;
  body = M.singleton 0 (V2.v (float (map_w / 2)) (float (map_h / 2)));
}

let new_snek =
  let cnt = ref 0 in
  (fun snek ->
     incr cnt;
     let x, y =
       M.max_binding snek.body |> snd
       |> V2.add snek.direction
       |> V2.add (V2.v (float map_w) (float map_h))
       |> V2.to_tuple
     in
     { snek with
       body =
         M.add !cnt
           Stdlib.Float.(V2.v (rem x (float map_w)) (rem y (float map_h)))
           snek.body
     })

let rec new_apple snek =
  let x = Random.int map_w |> float in
  let y = Random.int map_h |> float in
  let apple = V2.v x y in
  if M.exists (fun _ v -> v = apple) snek.body
  then new_apple snek else apple

let of_grid pos = V2.smul (float block_size) pos

let snek_apple =
  React.S.fold
    (fun (snek, apple) _ ->
       if not (React.S.value pause) then begin
         let snek = new_snek { snek with direction = React.S.value arrows } in
         if M.max_binding snek.body |> snd = apple then begin
           decr frames_per_tick;
           if !frames_per_tick < 1 then T.Engine.quit ();
           snek, new_apple snek
         end
         else { snek with body = M.remove (M.min_binding snek.body |> fst) snek.body }, apple
       end
       else snek, apple)
    (initial, new_apple initial)
    count

let renderables =
  React.S.map
    (fun (snek, apple) ->
       let screen = React.S.value T.Screen.default in
       M.fold
         (fun _ pos list ->
            T.Screen.render snake_block ~dst:(of_grid pos) screen :: list)
         snek.body
         [T.Screen.render apple_block ~dst:(of_grid apple) screen])
    snek_apple

let () = T.Engine.run (T.Engine.render renderables)
