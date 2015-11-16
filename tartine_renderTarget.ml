open Tsdl
open Gg
open Batteries

type params = {
  pos : V2.t;
  size : Size2.t;

  center : V2.t;
  angle : float;
  hflip : bool;
  vflip : bool;
}

type t = Size2.t -> params

let (>>) t f = fun img_size -> f (t img_size)

let at_pos v = fun img_size -> {
    pos = v;
    size = img_size;
    center = V2.smul 0.5 img_size;
    angle = 0.;
    hflip = false;
    vflip = false;
  }

let pos pos t = { t with pos }
let size size t = { t with size }
let center center t = { t with center }
let angle angle t = { t with angle }
let hflip hflip t = { t with hflip }
let vflip vflip t = { t with vflip }
