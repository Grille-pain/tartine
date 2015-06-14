open Tsdl

module Elt : sig
  type t = private {
    id: int;
    src: rect;
    scale: float;
    rot: float;
    center: point;
    hflip: bool; vflip: bool;
    
    image: Image.t;
  }

  val create : Image.t -> t

  val src : rect -> t -> t
  val scale : float -> t -> t
  val rot : float -> t -> t
  val center : point -> t -> t
  val hflip : bool -> t -> t
  val vflip : bool -> t -> t
  val reset_transform : t -> t

  val render : t -> rect -> unit
end
