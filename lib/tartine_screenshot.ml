open Tsdl
open Sigs
open Tartine_utils
open Sdl_result

module Make (Engine: Engine_sig) = struct

  let screenshots_dir_name = "screenshots"

  let fresh_name (): string Sdl.result =
    let fresh () =
      Sys.readdir screenshots_dir_name
      |> Array.to_list
      |> List.map (fun filename -> filename |> Filename.basename |> Filename.remove_extension)
      |> List.filter_map int_of_string_opt
      |> List.fold_left max 0 |> succ
      |> (fun i -> Filename.(screenshots_dir_name ^/ string_of_int i ^ ".bmp"))
      |> return
    in
    if Sys.file_exists screenshots_dir_name then
      if not (Sys.is_directory screenshots_dir_name) then
        Result.Error (`Msg ("\"" ^ screenshots_dir_name ^ "\""
                       ^ " exists but is not a directory"))
      else
        fresh ()
    else (
      Unix.mkdir screenshots_dir_name 0o755;
      fresh ()
    )

  let take_aux filename =
    let w, h = Sdl.get_window_size Engine.window in
    Sdl.create_rgb_surface ~w ~h ~depth:32
      0x00ff0000l 0x0000ff00l 0x000000ffl 0xff000000l >>= fun s ->
    Sdl.render_read_pixels Engine.renderer None (Some Sdl.Pixel.format_argb8888)
      (Sdl.get_surface_pixels s Bigarray.int8_unsigned)
      (Sdl.get_surface_pitch s) >>= fun () ->
    Sdl.save_bmp s filename >>= fun () ->
    return (Sdl.free_surface s)

  let take ?filename () =
    match filename with
    | None -> fresh_name () >>= fun f -> take_aux f
    | Some f -> take_aux f
end
