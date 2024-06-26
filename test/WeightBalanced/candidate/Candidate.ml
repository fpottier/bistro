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

(* -------------------------------------------------------------------------- *)

(* The name of this module, viewed from outside this library. *)

let name =
  "Weight_candidate.Candidate"

(* Whether the random access functions should be tested. *)

let has_random_access_functions =
  true

(* -------------------------------------------------------------------------- *)

(* The candidate. *)

include Baby.W.Set.Make(Int)

(* -------------------------------------------------------------------------- *)

(* Wrap some of the candidate functions with extra runtime checks. *)

(* We could also place these runtime checks in [Baby] itself, under
   [if debug], so they are erased in release mode. I prefer to place
   them here. *)

(* -------------------------------------------------------------------------- *)

(* [union] and [inter] guarantee that if the result is logically equal
   to one of the arguments then it is physically equal to one of the
   arguments. *)

(* This guarantee holds for weight-balanced trees, but not for
   height-balanced trees; indeed, a reliable way of comparing
   the cardinals of the two sets is needed. *)

let union t1 t2 =
  let result = union t1 t2 in
  if equal result t1 || equal result t2 then
    assert (result == t1 || result == t2);
  result

let inter t1 t2 =
  let result = inter t1 t2 in
  if equal result t1 || equal result t2 then
    assert (result == t1 || result == t2);
  result
