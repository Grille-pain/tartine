open Tsdl
open Tartine
open Prelude.Sdl_result

type t = { surface: Sdl.surface; texture: Sdl.texture }

let free_t t =
  Sdl.free_surface t.surface;
  Sdl.destroy_texture t.texture

let load t path =
  Sdl.load_bmp path >>= fun surface ->
  Sdl.create_texture_from_surface t.renderer surface >>= fun texture ->
  let t = { surface; texture } in
  Gc.finalise free_t t;
  return t
