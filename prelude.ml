module Int32 = struct
  include Int32
  
  let (+) = Int32.add
  let (-) = Int32.sub
  let (/) = Int32.div

  let max a b = if a < b then b else a
  let min a b = if a < b then a else b
end

let event_map_init
    (init: 'a -> 'b)
    (f: 'a -> 'b -> 'c)
    (e: 'a React.E.t):
  'c React.E.t
  =
  React.E.map init (React.E.once e)
  |> React.E.map (fun init_value -> React.E.map (fun x -> f x init_value) e)
  |> React.E.switch React.E.never
