open Monolith

(* This is the reference implementation. *)
module R = Reference.Make(Int)

(* The candidate implementation is supplied by a separate library,
   which is either [Weight_candidate] or [Height_candidate]. Both
   of these libraries offer a module named [Candidate]. *)
module C = Candidate

(* -------------------------------------------------------------------------- *)

(* We have one abstract type, namely [set]. *)

(* It is equipped with a well-formedness check,
   which ignores the model (the reference side). *)

let check _model =
  C.check,
  constant "check"

let set =
  declare_abstract_type ~check ()

(* We draw random integer keys. *)

let range =
  1 lsl 8

let value =
  semi_open_interval (-range) (range-1)

(* We can also draw an inhabitant out of a set. *)

let inhabits s =
  int_within @@ fun () ->
    let open R in
    let open Gen in
    if is_empty s then reject() else
    let x = min_elt s
    and y = max_elt s in
    let k = x + Random.int (y - x + 1) in
    let _, b, r = split k s in
    let z = if b then k else min_elt r in
    assert (mem z s);
    z

(* Deconstructing a triple. *)

let nest (x, y, z) =
  (x, (y, z))

let triple spec1 spec2 spec3 =
  map_into
    nest
    (nest, constant "nest")
    (spec1 *** (spec2 *** spec3))

(* Generating arrays. *)

let array_value =
  easily_constructible
    Gen.(array (int range) (semi_open_interval (-range) (range-1)))
    Print.(array int)

let sorted_unique_array compare n element () =
  Gen.list n element ()
  |> List.sort_uniq compare
  |> Array.of_list

let sorted_unique_array_value =
  easily_constructible
    Gen.(sorted_unique_array Int.compare (int 16) (semi_open_interval (-16) (15)))
    Print.(array int)

(* Generating or consuming sequences of values. *)

let seq_value =
  declare_seq value

(* Exchanging two arguments. *)

let flip f x y =
  f y x

(* -------------------------------------------------------------------------- *)

(* Declare the operations. *)

let () =

  let spec = set in
  declare "empty" spec R.empty C.empty;

  let spec = value ^> set in
  declare "singleton" spec R.singleton C.singleton;

  (* not tested: [is_empty] *)

  let spec = set ^!> value in
  declare "min_elt" spec R.min_elt C.min_elt;

  let spec = set ^!> option value in
  declare "min_elt_opt" spec R.min_elt_opt C.min_elt_opt;

  let spec = set ^!> value in
  declare "max_elt" spec R.max_elt C.max_elt;

  let spec = set ^!> option value in
  declare "max_elt_opt" spec R.max_elt_opt C.max_elt_opt;

  (* not tested: [choose], [choose_opt] *)
  (* not tested: [find_first], [find_first_opt] *)
  (* not tested: [find_last], [find_last_opt] *)

  let spec = value ^> set ^> bool in
  declare "mem" spec R.mem C.mem;

  let spec = value ^> set ^!> value in
  declare "find" spec R.find C.find;

  let spec = value ^> set ^> option value in
  declare "find_opt" spec R.find_opt C.find_opt;

  let spec = value ^> set ^> set in
  declare "add" spec R.add C.add;

  let spec = value ^> set ^> set in
  declare "remove" spec R.remove C.remove;

  (* TODO do the same for [mem], [find], [add], etc. *)
  (* Specifically remove a value that is in the set. *)
  let spec = set ^>> fun s -> (inhabits s) ^> set in
  declare "flip remove" spec (flip R.remove) (flip C.remove);

  let spec = set ^!> set in
  declare "remove_min_elt" spec R.remove_min_elt C.remove_min_elt;

  let spec = set ^!> set in
  declare "remove_max_elt" spec R.remove_max_elt C.remove_max_elt;

  let spec = set ^> set ^> set in
  declare "union" spec R.union C.union;

  let spec = set ^> set ^> set in
  declare "inter" spec R.inter C.inter;

  let spec = set ^> set ^> bool in
  declare "disjoint" spec R.disjoint C.disjoint;

  let spec = set ^> set ^> set in
  declare "diff" spec R.diff C.diff;

  let spec = set ^> set ^> bool in
  declare "subset" spec R.subset C.subset;

  let spec = set ^> set ^> set in
  declare "xor" spec R.xor C.xor;

  let spec = set ^> set ^> int in
  declare "compare" spec R.compare C.compare;

  (* [split] is not tested. *)

  let spec = set ^> list value in
  declare "elements" spec R.elements C.elements;

  let spec = seq_value ^> set in
  declare "of_seq" spec R.of_seq C.of_seq;

  let spec = set ^> seq_value in
  declare "to_seq" spec R.to_seq C.to_seq;

  let spec = value ^> set ^> seq_value in
  declare "to_seq_from" spec R.to_seq_from C.to_seq_from;

  let spec = set ^> seq_value in
  declare "to_rev_seq" spec R.to_rev_seq C.to_rev_seq;

  let spec = seq_value ^> set ^> set in
  declare "add_seq" spec R.add_seq C.add_seq;

  (* [of_list] is important in this test because it offers a cheap way
     of creating nontrivial sets. It consumes just one unit of fuel. *)
  let spec = list value ^> set in
  declare "of_list" spec R.of_list C.of_list;

  let spec = array_value ^> set in
  declare "of_array" spec R.of_array C.of_array;

  let spec = sorted_unique_array_value ^> set in
  declare "of_sorted_unique_array" spec R.of_array C.of_array;

  let spec = set ^> list value in
  declare "(fun s -> Array.to_list (to_array s))" spec
    R.elements
    (fun s -> Array.to_list (C.to_array s));

  let spec = set ^> int in
  declare "cardinal" spec R.cardinal C.cardinal;

  if C.has_random_access_functions then begin

    let spec = set ^>> fun s -> lt (R.cardinal s) ^> value in
    declare "get" spec R.get C.get;

    let spec = value ^> set ^!> int in
    declare "index" spec R.index C.index;

    (* Specifically query a value that is in the set. *)
    let spec = set ^>> fun s -> (inhabits s) ^> int in
    declare "flip index" spec (flip R.index) (flip C.index);

    let spec = set ^>> fun s -> le (R.cardinal s) ^> set *** set in
    declare "cut" spec R.cut C.cut;

    let spec = set ^>> fun s -> lt (R.cardinal s) ^> triple set value set in
    declare "cut_and_get" spec R.cut_and_get C.cut_and_get;

  end;

  (* not tested: [map] *)
  (* TODO test [filter_map] with identity (test physical equality),
       with monotone function, with non-monotone function *)
  (* not tested: [filter] *)
  (* TODO test [partition] *)

  (* not tested: [iter] *)
  (* not tested: [fold] *)
  (* not tested: [for_all] *)
  (* not tested: [exists] *)

  ()

(* -------------------------------------------------------------------------- *)

(* Start the engine! *)

let () =
  let prologue () =
    dprintf "          open %s;;\n" C.name;
    dprintf "          let flip f x y = f y x;;\n";
    dprintf "          let nest (x, y, z) = (x, (y, z));;\n";
    ()
  in
  let fuel = 16 in
  main ~prologue fuel
