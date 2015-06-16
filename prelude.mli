open Tsdl

module Sdl_result : sig
  val (>>=) : 'a Sdl.result -> ('a -> 'b Sdl.result) -> 'b Sdl.result
  val handle_error : (string -> 'a) -> 'a Sdl.result -> 'a
  val return : 'a -> 'a Sdl.result
end

module Int32 : sig
  include module type of Int32

  val ( + ) : int32 -> int32 -> int32
  val ( - ) : int32 -> int32 -> int32
  val ( * ) : int32 -> int32 -> int32
  val ( / ) : int32 -> int32 -> int32

  val max : int32 -> int32 -> int32
  val min : int32 -> int32 -> int32
end

module Filename : sig
  include module type of Filename

  val ( ^/ ) : string -> string -> string
end

val event_map_init :
  ('a -> 'b) ->
  ('b -> 'a -> 'c) ->
  'a React.E.t -> 'c React.E.t
