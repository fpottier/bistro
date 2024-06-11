(* [filter] is the same as in OCaml's Set library. *)

(* The worst-case time complexity of this implementation may be worse
   than linear, due to the use of [join] and [join2] -- I am not quite
   sure. One could imagine a completely different implementation of
   [filter], with linear worst-case time complexity, as follows: copy
   the data to an array, filter the array, reconstruct a tree.
   However, this approach would require linear auxiliary storage, may
   be slower in practice, and would be less effective at preserving
   sharing in scenarios where many elements are retained. *)

let rec filter p (t : tree) =
  match VIEW(t) with
  | LEAF ->
      leaf
  | NODE(l, v, r) ->
      (* Enforce left-to-right evaluation order. *)
      let l' = filter p l in
      let pv = p v in
      let r' = filter p r in
      if pv then
        if l == l' && r == r' then t else join l' v r'
      else
        join2 l' r'
