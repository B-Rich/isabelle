(*  Title:      HOL/Tools/BNF/bnf_gfp_util.ML
    Author:     Dmitriy Traytel, TU Muenchen
    Copyright   2012

Library for the codatatype construction.
*)

signature BNF_GFP_UTIL =
sig
  val mk_rec_simps: int -> thm -> thm list -> thm list list

  val dest_listT: typ -> typ

  val mk_Cons: term -> term -> term
  val mk_InN: typ list -> term -> int -> term
  val mk_Shift: term -> term -> term
  val mk_Succ: term -> term -> term
  val mk_Times: term * term -> term
  val mk_append: term * term -> term
  val mk_congruent: term -> term -> term
  val mk_Id_on: term -> term
  val mk_in_rel: term -> term
  val mk_equiv: term -> term -> term
  val mk_fromCard: term -> term -> term
  val mk_proj: term -> term
  val mk_quotient: term -> term -> term
  val mk_rec_list: term -> term -> term
  val mk_rec_nat: term -> term -> term
  val mk_shift: term -> term -> term
  val mk_size: term -> term
  val mk_toCard: term -> term -> term
  val mk_undefined: typ -> term
  val mk_univ: term -> term

  val mk_specN: int -> thm -> thm

  val mk_InN_Field: int -> int -> thm
  val mk_InN_inject: int -> int -> thm
  val mk_InN_not_InM: int -> int -> thm
  val mk_sumEN: int -> thm
end;

structure BNF_GFP_Util : BNF_GFP_UTIL =
struct

open BNF_Util
open BNF_FP_Util

val mk_append = HOLogic.mk_binop @{const_name append};

fun mk_equiv B R =
  Const (@{const_name equiv}, fastype_of B --> fastype_of R --> HOLogic.boolT) $ B $ R;

fun mk_InN [_] t 1 = t
  | mk_InN (_ :: Ts) t 1 = mk_Inl (mk_sumTN Ts) t
  | mk_InN (LT :: Ts) t m = mk_Inr LT (mk_InN Ts t (m - 1))
  | mk_InN Ts t _ = raise TYPE ("mk_InN", Ts, [t]);

fun mk_Sigma (A, B) =
  let
    val AT = fastype_of A;
    val BT = fastype_of B;
    val ABT = mk_relT (HOLogic.dest_setT AT, HOLogic.dest_setT (range_type BT));
  in Const (@{const_name Sigma}, AT --> BT --> ABT) $ A $ B end;

fun mk_Id_on A =
  let
    val AT = fastype_of A;
    val AAT = mk_relT (HOLogic.dest_setT AT, HOLogic.dest_setT AT);
  in Const (@{const_name Id_on}, AT --> AAT) $ A end;

fun mk_in_rel R =
  let
    val ((A, B), RT) = `dest_relT (fastype_of R);
  in Const (@{const_name in_rel}, RT --> mk_pred2T A B) $ R end;

fun mk_Times (A, B) =
  let val AT = HOLogic.dest_setT (fastype_of A);
  in mk_Sigma (A, Term.absdummy AT B) end;

fun dest_listT (Type (@{type_name list}, [T])) = T
  | dest_listT T = raise TYPE ("dest_setT: set type expected", [T], []);

fun mk_Succ Kl kl =
  let val T = fastype_of kl;
  in
    Const (@{const_name Succ},
      HOLogic.mk_setT T --> T --> HOLogic.mk_setT (dest_listT T)) $ Kl $ kl
  end;

fun mk_Shift Kl k =
  let val T = fastype_of Kl;
  in
    Const (@{const_name Shift}, T --> dest_listT (HOLogic.dest_setT T) --> T) $ Kl $ k
  end;

fun mk_shift lab k =
  let val T = fastype_of lab;
  in
    Const (@{const_name shift}, T --> dest_listT (Term.domain_type T) --> T) $ lab $ k
  end;

fun mk_toCard A r =
  let
    val AT = fastype_of A;
    val rT = fastype_of r;
  in
    Const (@{const_name toCard},
      AT --> rT --> HOLogic.dest_setT AT --> fst (dest_relT rT)) $ A $ r
  end;

fun mk_fromCard A r =
  let
    val AT = fastype_of A;
    val rT = fastype_of r;
  in
    Const (@{const_name fromCard},
      AT --> rT --> fst (dest_relT rT) --> HOLogic.dest_setT AT) $ A $ r
  end;

fun mk_Cons x xs =
  let val T = fastype_of xs;
  in Const (@{const_name Cons}, dest_listT T --> T --> T) $ x $ xs end;

fun mk_size t = HOLogic.size_const (fastype_of t) $ t;

fun mk_quotient A R =
  let val T = fastype_of A;
  in Const (@{const_name quotient}, T --> fastype_of R --> HOLogic.mk_setT T) $ A $ R end;

fun mk_proj R =
  let val ((AT, BT), T) = `dest_relT (fastype_of R);
  in Const (@{const_name proj}, T --> AT --> HOLogic.mk_setT BT) $ R end;

fun mk_univ f =
  let val ((AT, BT), T) = `dest_funT (fastype_of f);
  in Const (@{const_name univ}, T --> HOLogic.mk_setT AT --> BT) $ f end;

fun mk_congruent R f =
  Const (@{const_name congruent}, fastype_of R --> fastype_of f --> HOLogic.boolT) $ R $ f;

fun mk_undefined T = Const (@{const_name undefined}, T);

fun mk_rec_nat Zero Suc =
  let val T = fastype_of Zero;
  in Const (@{const_name old.rec_nat}, T --> fastype_of Suc --> HOLogic.natT --> T) $ Zero $ Suc end;

fun mk_rec_list Nil Cons =
  let
    val T = fastype_of Nil;
    val (U, consT) = `(Term.domain_type) (fastype_of Cons);
  in
    Const (@{const_name rec_list}, T --> consT --> HOLogic.listT U --> T) $ Nil $ Cons
  end;

fun mk_InN_not_InM 1 _ = @{thm Inl_not_Inr}
  | mk_InN_not_InM n m =
    if n > m then mk_InN_not_InM m n RS @{thm not_sym}
    else mk_InN_not_InM (n - 1) (m - 1) RS @{thm not_arg_cong_Inr};

fun mk_InN_Field 1 1 = @{thm TrueE[OF TrueI]}
  | mk_InN_Field _ 1 = @{thm Inl_Field_csum}
  | mk_InN_Field 2 2 = @{thm Inr_Field_csum}
  | mk_InN_Field n m = mk_InN_Field (n - 1) (m - 1) RS @{thm Inr_Field_csum};

fun mk_InN_inject 1 _ = @{thm TrueE[OF TrueI]}
  | mk_InN_inject _ 1 = @{thm Inl_inject}
  | mk_InN_inject 2 2 = @{thm Inr_inject}
  | mk_InN_inject n m = @{thm Inr_inject} RS mk_InN_inject (n - 1) (m - 1);

fun mk_sumEN 1 = @{thm one_pointE}
  | mk_sumEN 2 = @{thm sumE}
  | mk_sumEN n =
    (fold (fn i => fn thm => @{thm obj_sumE_f} RSN (i, thm)) (2 upto n - 1) @{thm obj_sumE}) OF
      replicate n (impI RS allI);

fun mk_specN 0 thm = thm
  | mk_specN n thm = mk_specN (n - 1) (thm RS spec);

fun mk_rec_simps n rec_thm defs = map (fn i =>
  map (fn def => def RS rec_thm RS mk_nthI n i RS fun_cong) defs) (1 upto n);

end;
