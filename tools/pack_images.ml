open Gg
open Batteries

let input_images = ref []
let output_name = ref "pack"

let () =
  Arg.parse [
    "-o", Arg.Set_string output_name, "Base name for the output pack image and toml files";
  ]
    (fun input_img -> input_images := input_img :: !input_images)
    "Pack multiple images to a unique one."

let to_rgba = function
  | Images.Index8 i -> Images.Rgba32 (Index8.to_rgba32 i)
  | Images.Rgb24 i -> Images.Rgba32 (Rgb24.to_rgba32 i)
  | Images.Index16 i -> Images.Rgba32 (Index16.to_rgba32 i)
  | Images.Rgba32 i -> Images.Rgba32 i
  | Images.Cmyk32 _ -> failwith "CMYK32 color profile not supported"

let () =
  if !input_images = [] then
    exit 0;

  let imgs = !input_images |> List.map (fun name ->
    (Filename.basename name |> Filename.chop_extension,
     Images.load name [] |> to_rgba))
  in
  let packing = Packing.packing imgs
      (fun (_, i) ->
         Images.size i
         |> Tuple2.mapn Float.of_int
         |> uncurry Size2.v) in
  let packing_size = Packing.size packing in

  Printf.printf "Packing size: %dx%d\n%!"
    (Size2.w packing_size |> truncate)
    (Size2.h packing_size |> truncate);

  let output_img =
    Images.Rgba32 (
      Rgba32.create
        (truncate (Size2.w packing_size))
        (truncate (Size2.h packing_size))
    ) in
  let output_toml = ref TomlTypes.Table.empty in

  Packing.iter (fun (name, img) rect ->
    let x, y, w, h = (
      Box2.ox rect,
      Box2.oy rect,
      Box2.w rect,
      Box2.h rect
    ) |> Tuple4.mapn truncate in

    output_toml := TomlTypes.Table.add
        (TomlTypes.Table.Key.bare_key_of_string name)
        (TomlTypes.TArray (TomlTypes.NodeInt [x; y; w; h]))
        !output_toml;

    Images.blit img 0 0 output_img x y w h
  ) packing;

  let cout = open_out (!output_name ^ ".toml") in
  let fmt = Format.formatter_of_out_channel cout in
  Toml.Printer.table fmt !output_toml;
  close_out cout;
  Images.save (!output_name ^ ".png") None [] output_img
