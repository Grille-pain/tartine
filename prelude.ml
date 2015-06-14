module Int32 = struct
  include Int32
  
  let (+) = Int32.add
  let (-) = Int32.sub

  let max a b = if a < b then b else a
  let min a b = if a < b then a else b
end
