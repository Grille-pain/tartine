open Gg
open Tsdl

module T = Tartine.Run (struct
    include Tartine.Init_defaults
    let w = 160
    let h = 160
  end)

module Event = Sdl.Event
module Scancode = Sdl.Scancode

module Color =
struct
  type t = Red | Green | Blue
  let compare t1 t2 = compare t1 t2
  let equal t1 t2 = t1 = t2
end

module Direction =
struct
  type t = Up | Left | Down | Right
  let compare t1 t2 = compare t1 t2
  let equal t1 t2 = t1 = t2
end

module Empty =
struct
  type t
  let compare t1 t2 = compare t1 t2
  let equal t1 t2 = t1 = t2
end

let time = React.S.map (fun time -> time.T.Engine.total_time) T.Engine.time

let arrow =
  [ React.E.fmap (function `Key_up -> Some Direction.Up | _ -> None) (T.Key.s_event Sdl.Scancode.up);
    React.E.fmap (function `Key_up -> Some Direction.Left | _ -> None) (T.Key.s_event Sdl.Scancode.left);
    React.E.fmap (function `Key_up -> Some Direction.Down | _ -> None) (T.Key.s_event Sdl.Scancode.down);
    React.E.fmap (function `Key_up -> Some Direction.Right | _ -> None) (T.Key.s_event Sdl.Scancode.right) ]
  |> React.E.select

let space =
  React.E.fmap (function `Key_up -> Some () | _ -> None) (T.Key.s_event Sdl.Scancode.space)

module ColAutomaton = Automaton.Make(Int32)(Color)(Unit)(Empty)
module DirAutomaton = Automaton.Make(Int32)(Direction)(Direction)(Empty)
module IntAutomaton = Automaton.Make(Int32)(Int)(Empty)(Empty)

let color =
  let open ColAutomaton in
  InProgress.create ~initial:Red
  |> InProgress.add_state Green
  |> InProgress.add_state Blue
  |> InProgress.fold (fun s t -> InProgress.add_transition_nondet s () [1,Red; 1,Green; 1,Blue] t)
  |> InProgress.fold (fun s t -> InProgress.add_timeout_nondet s 2000l [1,Red; 1,Green; 1,Blue] t)
  |> finalize

let color = ColAutomaton.run color time space |> fst

let direction =
  let open DirAutomaton in
  InProgress.create ~initial:Down
  |> InProgress.add_state Up
  |> InProgress.add_state Left
  |> InProgress.add_state Right
  |> InProgress.fold (fun s t -> InProgress.add_transition s Up Up t)
  |> InProgress.fold (fun s t -> InProgress.add_transition s Left Left t)
  |> InProgress.fold (fun s t -> InProgress.add_transition s Down Down t)
  |> InProgress.fold (fun s t -> InProgress.add_transition s Right Right t)
  |> finalize

let direction = DirAutomaton.run direction time arrow |> fst

let step =
  let open IntAutomaton in
  InProgress.create ~initial:0
  |> InProgress.add_state 1
  |> InProgress.add_timeout 0 200l 1
  |> InProgress.add_timeout 1 200l 0
  |> finalize

let step = IntAutomaton.run step time React.E.never |> fst

let render_target col dir step =
  let open T.RenderTarget in
  let y =
    match col with
    | Color.Red -> 0.
    | Color.Green -> -160.
    | Color.Blue -> -320.
  in
  let x =
    match dir with
    | Direction.Up -> -.(160. +. (float step) *. 480.)
    | Direction.Down -> -.((float step) *. 480.)
    | Direction.Left -> -.(320. +. (float step) *. 480.)
    | Direction.Right -> -.(480. -. (float step) *. 480.)
  in
  let h =
    match dir with
    | Direction.Right -> true
    | _ -> false
  in
  at_pos (V2.v x y) >> size (Size2.v 960. 480.) >> hflip h

let render_target =
  React.S.l3 ~eq:(fun r1 r2 -> r1 (Size2.v 0. 0.) = r2 (Size2.v 0. 0.))
    (fun col dir step -> render_target (fst col) (fst dir) (fst step))
    color direction step

let img =
  match T.Image.load "examples/character/OverworldCharacters.bmp" with
  | Error _ -> assert false
  | Ok img -> img

let main =
  T.Engine.tick
  |> React.E.map (fun _ -> T.Screen.render img (React.S.value render_target))

let () = T.Engine.run ()
