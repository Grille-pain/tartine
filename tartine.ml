open Tsdl

module Operators = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | `Ok x -> f x
    | `Error err -> `Error err
end
