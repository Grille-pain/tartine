open Tsdl
open Gg
open Sigs
open Tartine_utils.Sdl_result

module Make (Engine : Engine_sig) = struct

  type t = { surface: Sdl.surface; texture: Sdl.texture; size: Size2.t }

  let free_t t =
    Sdl.free_surface t.surface;
    Sdl.destroy_texture t.texture

  let make ~w ~h col =
    let r = Int32.(shift_left (of_float (Color.r col *. 255.)) 16) in
    let g = Int32.(shift_left (of_float (Color.g col *. 255.)) 8) in
    let b = Int32.of_float (Color.b col *. 255.) in
    let a = Int32.(shift_left (of_float (Color.a col *. 255.)) 24) in
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

  type transform = {
    center : V2.t;
    angle  : float;
    wscale : float;
    hscale : float;
    hflip  : bool;
    vflip  : bool;
  }


  let default size = {
    center = V2.v (Size2.w size /. 2.) (Size2.h size /. 2.);
    angle  = 0.;
    wscale = 1.;
    hscale = 1.;
    hflip  = false;
    vflip  = false;
  }

end
