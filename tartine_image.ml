open Tsdl
open Gg
open Sigs
open Tartine_utils.Sdl_result

module Make (Engine : Engine_sig) = struct
  open Engine

  type t = { surface: Sdl.surface; texture: Sdl.texture; size: Size2.t }

  let free_t t =
    Sdl.free_surface t.surface;
    Sdl.destroy_texture t.texture

  let load path =
    Sdl.load_bmp path >>= fun surface ->
    Sdl.create_texture_from_surface Engine.renderer surface >>= fun texture ->
    let size =
      let w, h = Sdl.get_surface_size surface in
      Gg.V2.v (float w) (float h)
    in
    let t = { surface; texture; size } in
    Gc.finalise free_t t;
    return t
end
