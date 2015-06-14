open Tsdl

module Operators : sig
  val (>>=) : 'a Sdl.result -> ('a -> 'b Sdl.result) -> 'b Sdl.result
  val return : 'a -> 'a Sdl.result
end

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

val event : Sdl.event_type -> 'b Sdl.Event.field -> 'b React.E.t
val tick : unit React.E.t

val run : (unit -> unit) -> unit
