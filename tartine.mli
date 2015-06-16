open Tsdl

module Operators : sig
  val (>>=) : 'a Sdl.result -> ('a -> 'b Sdl.result) -> 'b Sdl.result
  val handle_error : (string -> 'a) -> 'a Sdl.result -> 'a
  val return : 'a -> 'a Sdl.result
end

type t = private { renderer: Sdl.renderer;
                   window: Sdl.window;
                   frame_time: int32;
                   total_time: int32; }

val event : Sdl.event_type -> 'b Sdl.Event.field -> 'b React.E.t
val tick : t React.E.t

val run :
  w:int -> h:int -> ?fullscreen:bool -> ?flags:Sdl.Window.flags ->
  unit -> unit

val quit : unit -> unit
