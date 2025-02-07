(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(* TODO(T132410158) Add a module-level doc comment. *)


module type S = MyMap_sig.S
module Make(Ord: Map.OrderedType) : S with type key = Ord.t = struct
  include Map.Make(Ord)
  let get x t =
    try Some (find x t) with Not_found -> None

  let find_unsafe = find

  let union ?combine x y =
    let combine = match combine with
      | None -> (fun _ fst _ -> Some fst)
      | Some f -> f
    in
    union combine x y

  let compare x y = compare Pervasives.compare x y
  let equal x y = compare x y = 0

  let keys m = fold (fun k _ acc -> k :: acc) m []
  let values m = fold (fun _ v acc -> v :: acc) m []
  let elements m = fold (fun k v acc -> (k,v)::acc) m []

  let map_env f env m =
    fold (
      fun x y (env, acc) ->
        let env, y = f env y in
        env, add x y acc
    ) m (env, empty)

  let choose x =
    try Some (choose x) with Not_found -> None

  let from_keys keys f =
    List.fold_left begin fun acc key ->
      add key (f key) acc
    end empty keys

  let add ?combine key new_value map =
    match combine with
    | None -> add key new_value map
    | Some combine -> begin
        match get key map with
        | None -> add key new_value map
        | Some old_value -> add key (combine old_value new_value) map
      end
end
