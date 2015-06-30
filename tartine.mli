open Tsdl
open Gg

module Engine : sig
  (** The value bundling some informations about the engine at some point in time. *)
  type t = private { renderer: Sdl.renderer;
                     window: Sdl.window;
                     frame_time: int32;
                     total_time: int32; }

  (** Obtain a react event corresponding to some SDL event. *)
  val event : Sdl.event_type -> 'b Sdl.Event.field -> 'b React.E.t

  (** The event corresponding to the main loop. Emits one event per frame,
      i.e. 60 events per second.

      You probably want to use [Util.event_map_init] on this event to plug in
      your main code.
  *)
  val tick : t React.E.t

  (** Run the engine. Must be called at some point. *)
  val run :
    ?fullscreen:bool -> ?flags:Sdl.Window.flags -> w:int -> h:int ->
    unit -> unit

  (** Get the state of the engine. *)
  val state : unit -> t

  (** Call this to stop the engine. *)
  val quit : unit -> unit
end

module Key : sig
  val s : Sdl.scancode -> bool
  val k : Sdl.keycode -> bool
  
  val s_event : Sdl.scancode -> [`Key_up | `Key_down] React.E.t
  val k_event : Sdl.keycode -> [`Key_up | `Key_down] React.E.t

  val wasd :
    Sdl.scancode * Sdl.scancode * Sdl.scancode * Sdl.scancode ->
    V2.t
end

module Image : sig
  (** An image, load to memory & GPU. *)
  type t = private { surface: Sdl.surface; texture: Sdl.texture; size: Size2.t }
  val load : Engine.t -> string -> t Sdl.result
end

module Screen : sig
  type elt = {
    dst: Box2.t;
    
    center: V2.t;
    angle: float;
    hflip: bool;
    vflip: bool;
  }

  type transform = elt -> elt

  val no_transform : transform

  val render :
    Engine.t -> Image.t -> pos:V2.t ->
    ?src:Box2.t ->
    ?size:Size2.t ->
    transform ->
    unit Sdl.result
end

module Camera : sig
  val transform : Engine.t -> pos:V2.t -> ?size:Size2.t -> Screen.transform

  val follow : Engine.t -> pos:V2.t -> ?size:Size2.t ->
    border:float ->
    V2.t * Size2.t ->
    V2.t
end

module ImageStore : sig
  (** ImageStore:
      Utility module aiming at loading entire directories of images at once,
      described by an on-disk configuration file.

      An image store is described by a Toml [1] file, containing a list of
      toplevel string values (each one attached to a key). The value represents
      a relative path to the image to load, the key a name for the image, that
      will be used to recover the image (loaded into memory) from the table.

      Recognized Toml file example:
        sky = "sky.png"
        boat = "assets/boat.bmp"
        foo = "duck.jpg"

      [1] https://github.com/toml-lang/toml
  *)

  type t = (string, Image.t) Hashtbl.t

  (** [load st path] loads an image store into memory.

      - If [path] points to a directory, then the store described by
        [path]/imagestore.toml is loaded;
      - If [path] points to a file, the file is parsed as Toml and used
        as describing a store.

      Images failing to load and invalid keys are ignored.
  *)
  val load : Engine.t -> string -> t

  (** Standard hashtable lookup *)
  val find : string -> t -> Image.t
end

module Screenshot : sig
  val take : ?filename:string -> Engine.t -> unit Sdl.result
end

module Utils : sig
  (** A quite useful alternative to [React.E.map], that allows the user to
      create some initial value based on the value of the first event, and hold
      it for every other events.

      [event_map_init init f e] is [React.E.map (f (init x)) e], where [x] is
      the first value of [e].

      Note that [f] is partially applied to its first argument only once, so it is
      safe to perform some computations on the initialization value in the closure
      of the ['a -> 'c] resulting function; as these will be performed only once.
  *)
  val event_map_init :
    ('a -> 'b) ->
    ('b -> 'a -> 'c) ->
    'a React.E.t -> 'c React.E.t

  (** Some operators, useful to manipulate values of type ['a Sdl.result] *)
  module Sdl_result : sig
    val (>>=) : 'a Sdl.result -> ('a -> 'b Sdl.result) -> 'b Sdl.result
    val handle_error : (string -> 'a) -> 'a Sdl.result -> 'a
    val return : 'a -> 'a Sdl.result
  end

  module Int32 : sig
    include module type of Int32

    val ( + ) : int32 -> int32 -> int32
    val ( - ) : int32 -> int32 -> int32
    val ( * ) : int32 -> int32 -> int32
    val ( / ) : int32 -> int32 -> int32

    val max : int32 -> int32 -> int32
    val min : int32 -> int32 -> int32
  end

  module Filename : sig
    include module type of Filename
    val ( ^/ ) : string -> string -> string
  end
end
