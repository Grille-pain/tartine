open Tsdl

module Image : sig
  type t = private { surface: Sdl.surface; texture: Sdl.texture }
  (* quand faut-il détruire la surface/texture ? finalizer *)
  val load : string -> t
end

val event : Sdl.event_type -> 'b Sdl.Event.field -> 'b React.E.t
val tick : unit React.E.t

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

module Operators : sig
  val (>>=) : 'a Sdl.result -> ('a -> 'b Sdl.result) -> 'b Sdl.result
end

module Elt : sig
  type t = private {
    id: int;
    src: rect;
    scale: float;
    rot: float;
    center: point;
    hflip: bool; vflip: bool;
    
    image: Sdl.texture;
  }

  val create : Sdl.texture -> t

  val src : rect -> t -> t
  val scale : float -> t -> t
  val rot : float -> t -> t
  val center : point -> t -> t
  val hflip : bool -> t -> t
  val vflip : bool -> t -> t
  val reset_transform : t -> t
end

val render : Elt.t -> rect -> unit

type t = private { renderer: Sdl.renderer; window: Sdl.window }

val run :
  w:int -> h:int -> ?fullscreen:bool -> ?flags:Sdl.Window.flags ->
  (t -> unit) ->
  unit
