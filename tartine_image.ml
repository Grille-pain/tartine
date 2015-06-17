open Tsdl
open Tartine_engine
open Tartine_utils.Sdl_result

type t = { surface: Sdl.surface; texture: Sdl.texture; size: Gg.size2 }

let free_t t =
  Sdl.free_surface t.surface;
  Sdl.destroy_texture t.texture

let load t path =
  Sdl.load_bmp path >>= fun surface ->
  Sdl.create_texture_from_surface t.renderer surface >>= fun texture ->
  let size =
    let w, h = Sdl.get_surface_size surface in
    Gg.V2.v (float w) (float h)
  in
  let t = { surface; texture; size } in
  Gc.finalise free_t t;
  return t
