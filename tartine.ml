open Tsdl

module Operators = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | `Ok x -> f x
    | `Error err -> `Error err

  let return x = `Ok x
end

open Operators

type point = {
  x: float;
  y: float;
}

type rect = {
  x: float;
  y: float;
  w: float;
  h: float;
}

type t = private { renderer: Sdl.renderer; window: Sdl.window }

let event = assert false
let tick = assert false

let run = assert false

