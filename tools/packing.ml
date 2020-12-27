open Gg
open Batteries

type 'a t =
  | Leaf of Box2.t * 'a option
  | Node of Box2.t * 'a t * 'a t

exception Full

(* Implements the algorithm described in
   http://www.blackpawn.com/texts/lightmaps/
*)
let rec insert (p: 'a t) (elt: 'a) (sz: Size2.t) =
  match p with
  | Node (nrect, lp, rp) ->
    (try
       Node (nrect, insert lp elt sz, rp)
     with Full ->
       Node (nrect, lp, insert rp elt sz))
  | Leaf (_, Some _) -> raise Full
  | Leaf (lrect, None) ->
    if Size2.w sz > Box2.w lrect || Size2.h sz > Box2.h lrect then
      raise Full
    else if Size2.w sz = Box2.w lrect && Size2.h sz = Box2.h lrect then
      Leaf (lrect, Some elt)
    else (
      let dw = (Box2.w lrect) -. (Size2.w sz) in
      let dh = (Box2.h lrect) -. (Size2.h sz) in
      let l1, l2 =
        if dw > dh then
          (Box2.v (Box2.o lrect) (Size2.v (Size2.w sz) (Box2.h lrect))),
          (Box2.v (V2.v (Box2.ox lrect +. (Size2.w sz)) (Box2.oy lrect))
             (Size2.v (Box2.w lrect -. (Size2.w sz)) (Box2.h lrect)))
        else
          (Box2.v (Box2.o lrect) (Size2.v (Box2.w lrect) (Size2.h sz))),
          (Box2.v (V2.v (Box2.ox lrect) (Box2.oy lrect +. (Size2.h sz)))
             (Size2.v (Box2.w lrect) (Box2.h lrect -. (Size2.h sz))))
      in
      Node (lrect, insert (Leaf (l1, None)) elt sz, Leaf (l2, None))
    )

let log2 x = log x /. log 2.

let packing (elts: 'a list) (get_sz: 'a -> Size2.t): 'a t =
  let area sz = (Size2.w sz) *. (Size2.h sz) in
  let max_side sz = Float.max (Size2.w sz) (Size2.h sz) in
  let total_area = List.fold_left (fun acc elt ->
    acc +. (area (get_sz elt))
  ) 0. elts in

  let side_log_ub = ceil @@ log2 @@ sqrt total_area in

  let sorted_elts = List.sort
      (fun a b -> compare (get_sz b |> max_side) (get_sz a |> max_side))
      elts
  in
    
  let rec pack side_log =
    let side = 2. ** side_log in
    let square = Box2.v V2.zero (Size2.v side side) in
    try
      List.fold_left (fun p elt ->
        insert p elt (get_sz elt)
      ) (Leaf (square, None)) sorted_elts
    with Full -> pack (side_log +. 1.)
  in
  pack side_log_ub

let size (p: 'a t): Size2.t =
  match p with
  | Node (r, _, _)
  | Leaf (r, _) -> Box2.size r

let rec iter (f: 'a -> Box2.t -> unit) = function
  | Node (_, l, r) -> iter f l; iter f r
  | Leaf (_, None) -> ()
  | Leaf (rect, Some elt) -> f elt rect
    
