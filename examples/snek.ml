open Tsdl
open Gg
open Batteries

let map_w = 20
let map_h = 20
let block_size = 30

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = map_w * block_size
    let h = map_h * block_size
  end)

open T.Utils
open T.Utils.Sdl_result

let cam = React.S.value T.Camera.screen

let snake_block =
  T.Image.make
    ~w:block_size ~h:block_size
    0xff 0xff 0xff 0xff
  |> handle_error failwith

let apple_block =
  T.Image.make
    ~w:block_size ~h:block_size
    0xff 0x00 0x00 0xff
  |> handle_error failwith

let () = Random.self_init ()

let arrows =
  T.Key.wasd Sdl.Scancode.(up, left, down, right)
  |> React.S.map (fun u ->
    if V2.(dot u ox <> 0. && dot u oy <> 0.) then
      V2.(smul (dot u ox) ox)
    else u)
                  
let head = ref (Dllist.create (V2.v (float (map_w / 2)) (float (map_h / 2))))
let head_dir = ref V2.ox
let frames_per_tick = ref 20

let rec new_apple () =
  let x = Random.int map_w |> float in
  let y = Random.int map_h |> float in
  let apple = V2.v x y in
  if Dllist.exists ((=) apple) !head then new_apple () else apple

let apple = ref (new_apple ())

let of_grid pos = V2.smul (float block_size) pos

let main =
  let count = ref 0 in
  T.Engine.tick
  |> React.E.map (fun _ ->
    let a = React.S.value arrows in
    head_dir := if a = V2.zero then !head_dir else a;
    if !count >= !frames_per_tick then (
      count := 0;
      let new_head = V2.add (Dllist.get !head) !head_dir in
      head := Dllist.prepend !head new_head;
      if new_head = !apple then (
        apple := new_apple ();
        decr frames_per_tick;
        if !frames_per_tick < 1 then T.Engine.quit ();
      ) else (
        Dllist.remove (Dllist.prev !head)
      )
    ) else (
      incr count
    );

    T.Camera.render cam apple_block
      (T.RenderTarget.at_pos (of_grid !apple))
    |> handle_error failwith;

    Dllist.iter (fun pos ->
      T.Camera.render cam snake_block
        (T.RenderTarget.at_pos (of_grid pos))
      |> handle_error failwith
    ) !head
  )

let () = T.Engine.run ()
