open Tsdl
open Batteries
open Tartine_engine
open Tartine_utils
open Sdl_result

let screenshots_dir_name = "screenshots"

let fresh_name (): string Sdl.result =
  let fresh () =
    Sys.readdir screenshots_dir_name
    |> Array.to_list
    |> List.map (Filename.basename %> Filename.chop_extension)
    |> List.filter_map String.Exceptionless.to_int
    |> List.fold_left max 0
    |> (fun i -> Filename.(screenshots_dir_name ^/ String.of_int i ^ ".bmp"))
    |> return
  in
  if Sys.file_exists screenshots_dir_name then
    if not (Sys.is_directory screenshots_dir_name) then
      `Error ("\"" ^ screenshots_dir_name ^ "\"" ^ " exists but is not a directory")
    else
      fresh ()
  else (
    Unix.mkdir screenshots_dir_name 0o755;
    fresh ()
  )
      
let take_aux st filename =
  let w, h = Sdl.get_window_size st.window in
  Sdl.create_rgb_surface ~w ~h ~depth:32
    0x00ff0000l 0x0000ff00l 0x000000ffl 0xff000000l >>= fun s ->
  Sdl.render_read_pixels st.renderer None (Some Sdl.Pixel.format_argb8888)
    (Sdl.get_surface_pixels s Bigarray.int8_unsigned)
    (Sdl.get_surface_pitch s) >>= fun () ->
  Sdl.save_bmp s filename >>= fun () ->
  return (Sdl.free_surface s)

let take ?filename st =
  match filename with
  | None -> fresh_name () >>= fun f -> take_aux st f
  | Some f -> take_aux st f
