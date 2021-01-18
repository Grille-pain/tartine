open Gg
open Tsdl

module type Init_sig = sig
  val fullscreen : bool
  val flags : Sdl.Window.flags
  val w : int
  val h : int
end

module type Engine_sig = sig
  type time = { frame_time: int32; total_time: int32 }

  val renderer : Sdl.renderer
  val window : Sdl.window

  type renderable = {
    texture : Sdl.texture;
    src     : Sdl.rect;
    dst     : Sdl.rect;
    angle   : float;
    center  : Sdl.point option;
    flip    : Sdl.flip;
  }

  val render : renderable list React.S.t -> unit

  (** Obtain a react event corresponding to some SDL event. *)
  val event : Sdl.event_type -> 'a Sdl.Event.field -> 'a React.E.t
  val event_this_frame : Sdl.event_type -> 'a Sdl.Event.field -> 'a list React.S.t

  val keyboard_state : bool React.S.t array

  (** Signal and events corresponding to the main loop. For each frame :
    * 0) The renderer is cleared ;
    * 1) The time signal is updated ;
    * 2) SDL events are pushed ;
    * 3) A tick event is emitted ;
    * 4) The renderer is presented ;
    * 5) A tock event is emitted.
  *)
  val time : time React.S.t
  val tick : unit React.E.t
  val tock : unit React.E.t

  (** Call this to start and stop the engine. *)
  val run  : unit -> unit
  val quit : unit -> unit
end

module type Key_sig = sig

  val s_is_pressed : Sdl.scancode -> bool React.S.t
  val k_is_pressed : Sdl.keycode  -> bool React.S.t

  val s_event : Sdl.scancode -> [`Key_up | `Key_down] React.E.t
  val k_event : Sdl.keycode  -> [`Key_up | `Key_down] React.E.t

  val s_event_this_frame : Sdl.scancode -> [`Key_up | `Key_down ] list React.S.t
  val k_event_this_frame : Sdl.keycode  -> [`Key_up | `Key_down ] list React.S.t

  val wasd :
    Sdl.scancode * Sdl.scancode * Sdl.scancode * Sdl.scancode ->
    V2.t React.S.t
end

module type Image_sig = sig
  (** An image, load to memory & GPU. *)
  type t = private { surface: Sdl.surface;
                     texture: Sdl.texture;
                     size: Size2.t }
  val make : w:int -> h:int -> Color.t -> t Sdl.result
  val load : string -> t Sdl.result

  type transform = {
    center : V2.t;
    angle  : float;
    wscale : float;
    hscale : float;
    hflip  : bool;
    vflip  : bool;
  }

  val default : Size2.t -> transform
end

module type Renderer_sig = sig
  type t
  type image_t
  type transform_t
  type renderable_t

  val default : t React.S.t

  val render :
    image_t -> ?src:Box2.t -> ?dst:V2.t -> ?transform:transform_t -> t ->
    renderable_t
end

module type Screen_sig = sig
  include Renderer_sig
end

module type Camera_sig = sig
  include Renderer_sig

  val move_to  : V2.t -> t -> t
  val shift_by : V2.t -> t -> t

  val resize : Size2.t -> t -> t

  val follow : V2.t -> ?border:Size2.t -> t -> t
end

module type ImageStore_sig = sig
  type image_t

  (** ImageStore:
      Utility module aiming at loading entire directories of images at once,
      described by an on-disk configuration file.

      An image store is described by a Toml [1] file, containing a list of
      toplevel string values (each one attached to a key). The value
      represents a relative path to the image to load, the key a name for the
      image, that will be used to recover the image (loaded into memory) from
      the table.

      Recognized Toml file example:
        sky = "sky.png"
        boat = "assets/boat.bmp"
        foo = "duck.jpg"

      [1] https://github.com/toml-lang/toml
  *)

  type t = (string, image_t) Hashtbl.t

  (** [load st path] loads an image store into memory.

      - If [path] points to a directory, then the store described by
        [path]/images.store is loaded;
      - If [path] points to a file, the file is parsed as Toml and used
        as describing a store.

      Images failing to load and invalid keys are ignored.
  *)
  val load : string -> t

  (** Standard hashtable lookup *)
  val find : string -> t -> image_t
end

module type Screenshot_sig = sig
  val take : ?filename:string -> unit -> unit Sdl.result
end
