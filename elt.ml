open Tsdl

open Tartine
open Operators

module Elt = struct
  type t = private {
    id: int;
    src: rect;
    scale: float;
    rot: float;
    center: point;
    hflip: bool; vflip: bool;

    image: Image.t;
  }

  let fresh =
    let i = ref 0 in
    fun () -> incr i; !i

  let create i =
    let (w,h) = Sdl.get_surface_size i.surface in
    {
      id = fresh ();
      src = { x = 0; y = 0; w; h};
      scale = 1.;
      rot = 0.;
      center = { x = float (w / 2); y = float (h /2) };
      hflip = false; vflip = false;


      image = i;
    }
(*
  val src : rect -> t -> t
  val scale : float -> t -> t
  val rot : float -> t -> t
  val center : point -> t -> t
  val hflip : bool -> t -> t
  val vflip : bool -> t -> t
  val reset_transform : t -> t

  val render : Elt.t -> rect -> unit
*)
end
