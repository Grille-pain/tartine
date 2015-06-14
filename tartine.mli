open Tsdl

module Image : sig
  (* quand faut-il détruire la surface/texture ? finalizer *)
  val load : string -> Sdl.texture
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

module Elt : sig
  type elt = private {
    id: int;
    src: rect;
    scale: float;
    rot: float;
    center: point;
    hflip: bool; vflip: bool;
    
    image: Sdl.texture;
  }

  val create : Sdl.texture -> elt

  val src : rect -> elt -> elt
  val scale : float -> elt -> elt
  val rot : float -> elt -> elt
  val center : point -> elt -> elt
  val hflip : bool -> elt -> elt
  val vflip : bool -> elt -> elt
  val reset_transform : elt -> elt
end

val render : Elt.elt -> rect -> unit
val run : (unit -> unit) -> unit
