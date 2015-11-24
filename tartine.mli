open Tsdl
open Gg
open Sigs

module type Init_sig = Init_sig

module Init_defaults : sig
  val fullscreen : bool
  val flags : Sdl.Window.flags
  val fps_cap : int option
end

module Run : functor (Init : Init_sig) -> sig
  module Engine : Engine_sig

  module Key : Key_sig

  module Image : Image_sig

  module RenderTarget : RenderTarget_sig

  module Screen : Screen_sig with
    type image_t := Image.t with
    type renderTarget_t := RenderTarget.t

  module Camera : Camera_sig with
    type image_t := Image.t with
    type renderTarget_t := RenderTarget.t

  module ImageStore : ImageStore_sig with
    type image_t := Image.t
    
  module Screenshot : Screenshot_sig

  module Utils : sig
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
