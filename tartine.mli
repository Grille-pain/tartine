open Tsdl
open Gg
open Sigs

module type Init_sig = Init_sig

module Init_defaults : sig
  val fullscreen : bool
  val flags : Sdl.Window.flags
end

module Run : functor (Init : Init_sig) -> sig
  module Engine : Engine_sig

  module Key : Key_sig

  module Image : Image_sig

  module Screen : Screen_sig with
    type image_t := Image.t

  module Camera : Camera_sig with
    type screen_transform := Screen.transform

  module ImageStore : ImageStore_sig with
    type image_t := Image.t
    
  module Screenshot : Screenshot_sig

  module Utils : sig
    (** A quite useful alternative to [React.E.map], that allows the user to
        create some initial value based on the value of the first event, and
        hold it for every other events.

        [event_map_init init f e] is [React.E.map (f (init x)) e], where [x] is
        the first value of [e].

        Note that [f] is partially applied to its first argument only once, so
        it is safe to perform some computations on the initialization value in
        the closure of the ['a -> 'c] resulting function; as these will be
        performed only once.
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
end
