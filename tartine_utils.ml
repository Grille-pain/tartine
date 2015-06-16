open Tsdl

module Sdl_result = struct
  let (>>=) (type a) (type b)
      (r: a Sdl.result)
      (f: a -> b Sdl.result): b Sdl.result =
    match r with
    | `Ok x -> f x
    | `Error err -> `Error err

  let handle_error (type a)
      (f: string -> a)
      (r: a Sdl.result): a =
    match r with
    | `Ok x -> x
    | `Error err -> f err

  let return x = `Ok x
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

let event_map_init
    (init: 'a -> 'b)
    (f: 'b -> 'a -> 'c)
    (e: 'a React.E.t):
  'c React.E.t
  =
  React.E.map init (React.E.once e)
  |> React.E.map (fun init_value -> React.E.map (f init_value) e)
  |> React.E.switch React.E.never
