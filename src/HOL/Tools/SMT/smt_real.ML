(*  Title:      HOL/Tools/SMT/smt_real.ML
    Author:     Sascha Boehme, TU Muenchen

SMT setup for reals.
*)

structure SMT_Real: sig end =
struct


(* SMT-LIB logic *)

fun smtlib_logic ts =
  if exists (Term.exists_type (Term.exists_subtype (equal @{typ real}))) ts
  then SOME "AUFLIRA"
  else NONE


(* SMT-LIB and Z3 built-ins *)

local
  fun real_num _ i = SOME (string_of_int i ^ ".0")

  fun is_linear [t] = SMT_Util.is_number t
    | is_linear [t, u] = SMT_Util.is_number t orelse SMT_Util.is_number u
    | is_linear _ = false

  fun mk_times ts = Term.list_comb (@{const times (real)}, ts)

  fun times _ _ ts = if is_linear ts then SOME ("*", 2, ts, mk_times) else NONE
in

val setup_builtins =
  SMT_Builtin.add_builtin_typ SMTLIB_Interface.smtlibC
    (@{typ real}, K (SOME ("Real", [])), real_num) #>
  fold (SMT_Builtin.add_builtin_fun' SMTLIB_Interface.smtlibC) [
    (@{const less (real)}, "<"),
    (@{const less_eq (real)}, "<="),
    (@{const uminus (real)}, "-"),
    (@{const plus (real)}, "+"),
    (@{const minus (real)}, "-") ] #>
  SMT_Builtin.add_builtin_fun SMTLIB_Interface.smtlibC
    (Term.dest_Const @{const times (real)}, times) #>
  SMT_Builtin.add_builtin_fun' Z3_Interface.smtlib_z3C
    (@{const times (real)}, "*") #>
  SMT_Builtin.add_builtin_fun' Z3_Interface.smtlib_z3C
    (@{const divide (real)}, "/")

end


(* Z3 constructors *)

local
  fun z3_mk_builtin_typ (Z3_Interface.Sym ("Real", _)) = SOME @{typ real}
    | z3_mk_builtin_typ (Z3_Interface.Sym ("real", _)) = SOME @{typ real}
        (*FIXME: delete*)
    | z3_mk_builtin_typ _ = NONE

  fun z3_mk_builtin_num _ i T =
    if T = @{typ real} then SOME (Numeral.mk_cnumber @{ctyp real} i)
    else NONE

  fun mk_nary _ cu [] = cu
    | mk_nary ct _ cts = uncurry (fold_rev (Thm.mk_binop ct)) (split_last cts)

  val mk_uminus = Thm.apply (Thm.cterm_of @{context} @{const uminus (real)})
  val add = Thm.cterm_of @{context} @{const plus (real)}
  val real0 = Numeral.mk_cnumber @{ctyp real} 0
  val mk_sub = Thm.mk_binop (Thm.cterm_of @{context} @{const minus (real)})
  val mk_mul = Thm.mk_binop (Thm.cterm_of @{context} @{const times (real)})
  val mk_div = Thm.mk_binop (Thm.cterm_of @{context} @{const divide (real)})
  val mk_lt = Thm.mk_binop (Thm.cterm_of @{context} @{const less (real)})
  val mk_le = Thm.mk_binop (Thm.cterm_of @{context} @{const less_eq (real)})

  fun z3_mk_builtin_fun (Z3_Interface.Sym ("-", _)) [ct] = SOME (mk_uminus ct)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("+", _)) cts = SOME (mk_nary add real0 cts)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("-", _)) [ct, cu] = SOME (mk_sub ct cu)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("*", _)) [ct, cu] = SOME (mk_mul ct cu)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("/", _)) [ct, cu] = SOME (mk_div ct cu)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("<", _)) [ct, cu] = SOME (mk_lt ct cu)
    | z3_mk_builtin_fun (Z3_Interface.Sym ("<=", _)) [ct, cu] = SOME (mk_le ct cu)
    | z3_mk_builtin_fun (Z3_Interface.Sym (">", _)) [ct, cu] = SOME (mk_lt cu ct)
    | z3_mk_builtin_fun (Z3_Interface.Sym (">=", _)) [ct, cu] = SOME (mk_le cu ct)
    | z3_mk_builtin_fun _ _ = NONE
in

val z3_mk_builtins = {
  mk_builtin_typ = z3_mk_builtin_typ,
  mk_builtin_num = z3_mk_builtin_num,
  mk_builtin_fun = (fn _ => fn sym => fn cts =>
    (case try (Thm.typ_of_cterm o hd) cts of
      SOME @{typ real} => z3_mk_builtin_fun sym cts
    | _ => NONE)) }

end


(* Z3 proof replay *)

val real_linarith_proc =
  Simplifier.make_simproc @{context} "fast_real_arith"
   {lhss = [@{term "(m::real) < n"}, @{term "(m::real) \<le> n"}, @{term "(m::real) = n"}],
    proc = K Lin_Arith.simproc}


(* setup *)

val _ = Theory.setup (Context.theory_map (
  SMTLIB_Interface.add_logic (10, smtlib_logic) #>
  setup_builtins #>
  Z3_Interface.add_mk_builtins z3_mk_builtins #>
  Z3_Replay_Util.add_simproc real_linarith_proc))

end;
