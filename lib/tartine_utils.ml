open Tsdl

module Sdl_result = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | Result.Ok x -> f x
    | Result.Error err -> Result.Error err

  let handle_error (type a)
      (f: string -> a)
      (r: a Sdl.result): a =
    match r with
    | Result.Ok x -> x
    | Result.Error (`Msg err) -> f err

  let return x = Result.Ok x
end

module Int32 = struct
  include Int32

  let (+) = Int32.add
  let (-) = Int32.sub
  let ( * ) = Int32.mul
  let (/) = Int32.div

  let max a b = if a < b then b else a
  let min a b = if a < b then a else b
end

module Filename = struct
  include Filename

  let (^/) = Filename.concat
end
