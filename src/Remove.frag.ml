(******************************************************************************)
(*                                                                            *)
(*                                    Baby                                    *)
(*                                                                            *)
(*                       François Pottier, Inria Paris                        *)
(*                                                                            *)
(*       Copyright 2024--2024 Inria. All rights reserved. This file is        *)
(*       distributed under the terms of the GNU Library General Public        *)
(*       License, with an exception, as described in the file LICENSE.        *)
(*                                                                            *)
(******************************************************************************)

(* [remove_min_elt_1 l v r] removes the minimum element of the tree
   [NODE(l, v, r)]. *)

let rec remove_min_elt_1 (l : tree) (v : key) (r : tree) : tree =
  match VIEW(l) with
  | LEAF ->
      r
  | NODE(ll, lv, lr) ->
      let l = remove_min_elt_1 ll lv lr in
      join_neighbors l v r

(* [remove_min_elt t] removes the minimum element of the tree [t]. *)

let remove_min_elt (t : tree) : tree =
  match VIEW(t) with
  | LEAF ->
      raise Not_found
  | NODE(l, v, r) ->
      remove_min_elt_1 l v r

(* [remove_max_elt_1 l v r] removes the maximum element of the tree
   [NODE(l, v, r)]. *)

let rec remove_max_elt_1 (l : tree) (v : key) (r : tree) : tree =
  match VIEW(r) with
  | LEAF ->
      l
  | NODE(rl, rv, rr) ->
      let r = remove_max_elt_1 rl rv rr in
      join_neighbors l v r

(* [remove_max_elt t] removes the maximum element of the tree [t]. *)

let remove_max_elt (t : tree) : tree =
  match VIEW(t) with
  | LEAF ->
      raise Not_found
  | NODE(l, v, r) ->
      remove_max_elt_1 l v r

(* [join2_siblings l r] is analogous to [join2 l r], but requires the
   subtrees [l] and [r] to be siblings in a valid tree. *)

(* [join2_siblings] is named [merge] in OCaml's Set library. *)

(* This implementation arbitrarily chooses to place the minimum element of the
   tree [r] at the root. One could also choose to place the maximum element of
   the tree [l] at the root. One could imagine choosing between these
   alternatives, based on the weights or heights of the trees [l] and [r], if
   such a notion exists. That would remove the need for rebalancing. However,
   this seems to make essentially no difference in practice. *)

let join2_siblings (l : tree) (r : tree) : tree =
  match VIEW(l), VIEW(r) with
  | _, LEAF ->
      l
  | LEAF, _ ->
      r
  | _, NODE(rl, rv, rr) ->
      join_neighbors
        l
        (min_elt_1 rv rl)           (* same as [min_elt r] *)
        (remove_min_elt_1 rl rv rr) (* same as [remove_min_elt r] *)

(* This is removal in the style of BFS. *)

(* (Disabled.)

let remove (k : key) (t : tree) : tree =
  let l, _, r = split k t in
  join2 l r

 *)

(* This is a less elegant but more efficient version of removal. *)

(* This implementation is taken from OCaml's Set library. *)

let rec remove (x : key) (t : tree) : tree =
  match VIEW(t) with
  | LEAF ->
      empty
  | NODE(l, v, r) ->
      let c = E.compare x v in
      if c = 0 then
        join2_siblings l r
      else if c < 0 then
        let l' = remove x l in
        if l == l' then t else join_neighbors l' v r
      else
        let r' = remove x r in
        if r == r' then t else join_neighbors l v r'
