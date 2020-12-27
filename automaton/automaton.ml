module type COMPARABLE =
sig
  type t
  val compare : t -> t -> int
  val equal : t -> t -> bool
end

module type S =
sig

  type time
  type state
  type input
  type output

  module InProgress :
  sig
    type t

    val create : initial:state -> t

    val add_state : state -> t -> t
    val add_output : state -> output -> t -> t

    val add_transition : state -> input -> state -> t -> t
    val add_transition_nondet : state -> input -> (int * state) list -> t -> t

    val add_timeout : state -> time -> state -> t -> t
    val add_timeout_nondet : state -> time ->  (int * state) list -> t -> t

    val fold : (state -> t -> t) -> t -> t
  end

  type t

  val finalize : InProgress.t -> t
  val run : t -> time React.S.t -> input React.E.t ->
    ((state * time) React.S.t * (output * time) React.E.t)

end

module Make
    (Time: sig include COMPARABLE val sub : t -> t -> t end)
    (State: COMPARABLE) (Input: COMPARABLE) (Output: COMPARABLE) : S
  with type time = Time.t
   and type state = State.t
   and type input = Input.t
   and type output = Output.t =
struct

  type time = Time.t
  type state = State.t
  type input = Input.t
  type output = Output.t

  module InputMap = Map.Make(Input)
  module StateMap = Map.Make(State)

  type 'a weighted_list = int * (int * 'a) list

  module InProgress =
  struct

    type content = {
      trans   : State.t weighted_list InputMap.t;
      timeout : (time * State.t weighted_list) option;
      output  : Output.t option;
    }

    type t = {
      initial : State.t;
      table   : content StateMap.t;
    }

    let empty = { trans = InputMap.empty; timeout = None; output = None }

    let create ~initial =
      { initial; table = StateMap.singleton initial empty }

    let get state t =
      match StateMap.find_opt state t with
      | None -> empty, StateMap.add state empty t
      | Some content -> content, t

    let add_state state t =
      let table = StateMap.add state empty t.table in
      { t with table  }

    let add_output state output t =
      let content, table = get state t.table in
      let table =  StateMap.add state { content with output = Some output } table in
      { t with table }

    let fold_nondet table list =
      List.fold_left
        (fun (sum, list, table as acc) (int, state as dst) ->
           if int > 0 then
             int + sum, dst :: list, snd (get state table)
           else acc)
        (0, [], table) list

    let add_transition src input dst t =
      let content, table = get src t.table in
      let _, table = get dst table in
      let trans = InputMap.add input (1, [1, dst]) content.trans in
      let table = StateMap.add src { content with trans } table in
      { t with table }

    let add_transition_nondet src input list t =
      let content, table = get src t.table in
      let sum, list, table = fold_nondet table list in
      let trans = InputMap.add input (sum, list) content.trans  in
      let table = StateMap.add src { content with trans } table in
      { t with table }

    let add_timeout src time dst t =
      let content, table = get src t.table in
      let _, table = get dst table in
      let timeout = Some (time, (1, [1, dst])) in
      let table = StateMap.add src { content with timeout } table in
      { t with table }

    let add_timeout_nondet src time list t =
      let content, table = get src t.table in
      let sum, list, table = fold_nondet table list in
      let timeout = Some (time, (sum, list)) in
      let table = StateMap.add src { content with timeout } table in
      { t with table }

    let fold f t =
      StateMap.fold (fun state _ acc -> f state acc) t.table t

  end

  type content = {
    trans   : int array InputMap.t;
    timeout : (time * int array) option;
    output  : Output.t option;
  }

  type t = {
    states  : State.t array;
    initial : int;
    table   : content array;
  }

(*
  let map_weighted_list f (int, list) =
    int, List.map (fun (int, x) -> int, f x) list
*)

  let array_of_weighted_list f (sum, list) =
    let array = Array.of_list list in
    let sum = ref sum in
    Array.init (2 * Array.length array)
      (fun i ->
         if i mod 2 = 0
         then begin
           let s = !sum in
           sum := s - fst array.(i / 2);
           s
         end
         else f (snd array.(i / 2)))

  let finalize InProgress.{ initial; table } =
    let states, contents =
      let fst, snd = StateMap.bindings table |> List.split in
      Array.of_list fst, Array.of_list snd
    in
    let get_index =
      let map =
        Array.fold_left
          (fun (map, int) state -> StateMap.add state int map, succ int)
          (StateMap.empty, 0) states
        |> fst
      in
      (fun state -> StateMap.find state map)
    in
    let initial = get_index initial in
    let table =
      Array.map
        (fun InProgress.{ trans; timeout; output } ->
           let trans = InputMap.map (array_of_weighted_list get_index) trans in
           let timeout =
             match timeout with
             | None -> None
             | Some (time, weighted_list) ->
               Some (time, array_of_weighted_list get_index weighted_list)
           in
           { trans; timeout; output })
        contents
    in
    { states; initial; table }

  type event = Input of Input.t | Time of Time.t

(*
  let choose (sum, list) =
    let rdm = Random.int sum in
    List.fold_left
      (fun (sum, cur) (wg, st) ->
         sum + wg, if sum <= rdm then Some st else cur)
      (0, None) list
    |> snd
*)

  let choose array =
    try
      let rdm = Random.int array.(0) in
      let opt = ref None in
      Array.iteri
        (fun idx int ->
           if idx mod 2 = 1 && array.(pred idx) > rdm
           then opt := Some int)
        array;
      !opt
    with _ -> None

  let next_state t time (int, float as current) event =
    let time = React.S.value time in
    match event with
    | Input i ->
      (match InputMap.find_opt i t.table.(int).trans with
       | None -> int, time
       | Some weighted_array ->
         match choose weighted_array with
         | None -> int, time
         | Some int -> int, time)
    | Time f ->
      match t.table.(int).timeout with
      | None -> current
      | Some (timeout, weighted_array) ->
        if Time.compare (Time.sub f float) timeout > 0
        then
          match choose weighted_array with
          | None -> int, time
          | Some int -> int, time
        else current

  let run t time input =
    let tm = React.S.value time in
    let event =
      React.E.select
        [React.E.map (fun i -> Input i) input;
         React.S.diff (fun t _ -> Time t) time]
      |> React.E.fold (fun int event -> next_state t time int event) (t.initial, tm)
      |> React.E.diff (fun pair _ -> pair)
    in
    React.S.hold (t.initial, tm) event
    |> React.S.map (fun (int, float) -> t.states.(int), float),
    React.E.fmap (fun (int, float) ->
        match t.table.(int).output with
        | None -> None
        | Some o -> Some (o, float))
      event

end

