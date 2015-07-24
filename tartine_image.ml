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

  let make ~w ~h r g b a =
    let r = Int32.(shift_left (of_int (r land 0xff)) 16) in
    let g = Int32.(shift_left (of_int (g land 0xff)) 8) in
    let b = Int32.of_int (b land 0xff) in
    let a = Int32.(shift_left (of_int (a land 0xff)) 24) in
    let color = Int32.(r |> logor g |> logor b |> logor a) in
    
    Sdl.create_rgb_surface ~w ~h ~depth:32
      0x00ff0000l 0x0000ff00l 0x000000ffl 0xff000000l >>= fun surface ->
    Sdl.fill_rect surface None color >>= fun () ->
    Sdl.create_texture_from_surface Engine.renderer surface >>= fun texture ->
    let img = { surface; texture; size = V2.v (float w) (float h) } in
    Gc.finalise free_t img;
    return img

  let load path =
    Sdl.load_bmp path >>= fun surface ->
    Sdl.create_texture_from_surface Engine.renderer surface >>= fun texture ->
    let size =
      let w, h = Sdl.get_surface_size surface in
      V2.v (float w) (float h)
    in
    let t = { surface; texture; size } in
    Gc.finalise free_t t;
    return t
end
