(* -------------------------------------------------------------------------- *)

(* Union. *)

(* The union algorithm proposed by BFS is improved (or complicated)
   with two features of OCaml's Set library:
   - the subtree that seems smaller is split (this is a heuristic);
   - if one subtree is a singleton then [union] degenerates to [add].

   Whereas OCaml tests which subtree seems smaller at every step in
   the recursive function, we do so only once at the beginning. This
   avoids code duplication and seems to work just as well. (Because
   the trees are balanced, in the recursive function, the property
   that [t1] is (roughly) the smaller tree is preserved.) *)

let rec union (t1 : tree) (t2 : tree) : tree =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _ ->
      t2
  | _, LEAF ->
      t1
  | NODE(_, k1, _), NODE(l2, k2, r2) ->
      if is_singleton t1 then add k1 t2 else
      let l1, r1 = split2 k2 t1 in
      let l = union l1 l2
      and r = union r1 r2 in
      join l k2 r

let union (t1 : tree) (t2 : tree) : tree =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _ ->
      t2
  | _, LEAF ->
      t1
  | NODE(_, _, _), NODE(_, _, _) ->
      if seems_smaller t2 t1 then
        union t2 t1
      else
        union t1 t2

(* -------------------------------------------------------------------------- *)

(* Intersection. *)

let rec inter (t1 : tree) (t2 : tree) : tree =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _
  | _, LEAF ->
      leaf
  | NODE(_, _, _), NODE(l2, k2, r2) ->
      let l1, b, r1 = split k2 t1 in
      let l = inter l1 l2
      and r = inter r1 r2 in
      if b then join l k2 r else join2 l r

(* -------------------------------------------------------------------------- *)

(* Disjointness. *)

(* This simple version of [disjoint] has the same structure as [inter]. *)

(* (Disabled.)

let rec disjoint (t1 : tree) (t2 : tree) : bool =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _
  | _, LEAF ->
      true
  | NODE(_, _, _), NODE(l2, k2, r2) ->
      let l1, b, r1 = split k2 t1 in
      not b && disjoint l1 l2 && disjoint r1 r2

 *)

(* This more complex version of [disjoint] does not use [split],
   therefore does not construct new trees; it does not allocate
   memory or perform rebalancing work. *)

(* In comparison with [disjoint] in OCaml's Set library, this version
   of [disjoint] can be twice faster and up to 40% slower. *)

(* [disjoint_node t1 l2 v2 r2] tests whether the trees [t1]
   and [NODE(l2, v2, r2)] are disjoint. *)

let rec disjoint_node t1 l2 v2 r2 =
  match VIEW(t1) with
  | LEAF ->
      true
  | NODE(l1, v1, r1) ->
      let c = E.compare v2 v1 in
      if c = 0 then
        false
      else if c < 0 then
        not (mem v1 r2) &&
        disjoint r1 r2 &&
        disjoint_node l1 l2 v2 r2
      else
        not (mem v1 l2) &&
        disjoint l1 l2 &&
        disjoint_node r1 l2 v2 r2

and disjoint (t1 : tree) (t2 : tree) : bool =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _
  | _, LEAF ->
      true
  | NODE(_, _, _), NODE(l2, v2, r2) ->
      t1 != t2 && (* fast path *)
      disjoint_node t1 l2 v2 r2

(* -------------------------------------------------------------------------- *)

(* Difference. *)

let rec diff (t1 : tree) (t2 : tree) : tree =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _ ->
      leaf
  | _, LEAF ->
      t1
  | NODE(_, _, _), NODE(l2, k2, r2) ->
      let l1, r1 = split2 k2 t1 in
      let l = diff l1 l2
      and r = diff r1 r2 in
      join2 l r

(* -------------------------------------------------------------------------- *)

(* Inclusion. *)

(* This version of [subset] has the same structure as [disjoint] above.
   Compared with [subset] in OCaml's Set library, this version does not
   allocate any memory, and includes a fast path based on a physical
   equality test. It also avoids redundant pattern matching.  *)

let rec subset_node t1 l2 v2 r2 =
  match VIEW(t1) with
  | LEAF ->
      true
  | NODE(l1, v1, r1) ->
      let c = E.compare v2 v1 in
      if c = 0 then
        subset l1 l2 && subset r1 r2
      else if c < 0 then
        mem v1 r2 &&
        subset r1 r2 &&
        subset_node l1 l2 v2 r2
      else
        mem v1 l2 &&
        subset l1 l2 &&
        subset_node r1 l2 v2 r2

and subset (t1 : tree) (t2 : tree) : bool =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _ ->
      true
  | _, LEAF ->
      false
  | NODE(_, _, _), NODE(l2, v2, r2) ->
      t1 == t2 || (* fast path *)
      subset_node t1 l2 v2 r2

(* -------------------------------------------------------------------------- *)

(* Symmetric difference. *)

let rec xor (t1 : tree) (t2 : tree) : tree =
  match VIEW(t1), VIEW(t2) with
  | LEAF, _ ->
      t2
  | _, LEAF ->
      t1
  | NODE(_, _, _), NODE(l2, k2, r2) ->
      let l1, b, r1 = split k2 t1 in
      let l = xor l1 l2
      and r = xor r1 r2 in
      if b then join2 l r else join l k2 r

(* -------------------------------------------------------------------------- *)

(* Equality. *)

(* Equality can be implemented in several ways. E.g., [equal t1 t2] could be
   implemented in one line by [subset t1 t2 && subset t2 t1] or also in one
   line by [is_empty (xor t1 t2)]. (The latter idea could be optimized, so
   as to avoid actually constructing the tree [xor t1 t2] in memory.) Some
   experiments suggest that either of these approaches is more expensive
   than the following approach, which is based on [compare]. *)

let equal t1 t2 =
  t1 == t2 || (* fast path *)
  compare t1 t2 = 0
