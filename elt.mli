open Tsdl
open Gg
open Tartine

type t = private {
  id: int;
  src: Box2.t;
  scale: float;
  angle: float;
  center: V2.t;
  hflip: bool; vflip: bool;

  image: Image.t;
}

val create : Image.t -> t

val src : Box2.t -> t -> t
val scale : float -> t -> t
val angle : float -> t -> t
val center : V2.t -> t -> t
val hflip : bool -> t -> t
val vflip : bool -> t -> t
val reset_transform : t -> t

val render : Tartine.t -> t -> dst:Box2.t -> unit Sdl.result
