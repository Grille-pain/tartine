module T = Tartine.Run(struct
    include Tartine.Init_defaults
    let w = 640
    let h = 480
  end)

open T.Utils
open T.Engine
open T.Key
open T.Image
open T.ImageStore
open T.Screen
open T.Camera
open T.Screenshot
