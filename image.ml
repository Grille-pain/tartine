open Tsdl

open Tartine
open Operators

type t = { surface: Sdl.surface; texture: Sdl.texture }

let load t path =
  Sdl.load_bmp path >>= fun surface ->
  Sdl.create_texture_from_surface t.renderer surface >>= fun texture ->
  return { surface; texture }
