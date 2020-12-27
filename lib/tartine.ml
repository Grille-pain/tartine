open Tsdl
open Sigs

module Init_defaults = struct
  let fullscreen = false
  let flags = Sdl.Window.opengl
  let fps_cap = None
end

module Run (Init : Init_sig) = struct
  module Engine = Tartine_engine.Make(Init)
  module Key = Tartine_key.Make(Engine)
  module Image = Tartine_image.Make(Engine)
  module RenderTarget = Tartine_renderTarget
  module Screen = Tartine_screen.Make(Engine)(Image)(RenderTarget)
  module Camera = Tartine_camera.Make(Engine)(Image)(RenderTarget)(Screen)
  module ImageStore = Tartine_imageStore.Make(Engine)(Image)
  module Screenshot = Tartine_screenshot.Make(Engine)
  module Utils = Tartine_utils
end
