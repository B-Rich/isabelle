(*  Title:      FOL/fologic.ML
    Author:     Lawrence C Paulson

Abstract syntax operations for FOL.
*)

signature FOLOGIC =
sig
  val oT: typ
  val mk_Trueprop: term -> term
  val dest_Trueprop: term -> term
  val not: term
  val conj: term
  val disj: term
  val imp: term
  val iff: term
  val mk_conj: term * term -> term
  val mk_disj: term * term -> term
  val mk_imp: term * term -> term
  val dest_imp: term -> term * term
  val dest_conj: term -> term list
  val mk_iff: term * term -> term
  val dest_iff: term -> term * term
  val all_const: typ -> term
  val mk_all: term * term -> term
  val exists_const: typ -> term
  val mk_exists: term * term -> term
  val eq_const: typ -> term
  val mk_eq: term * term -> term
  val dest_eq: term -> term * term
  val mk_binop: string -> term * term -> term
  val mk_binrel: string -> term * term -> term
  val dest_bin: string -> typ -> term -> term * term
end;


structure FOLogic: FOLOGIC =
struct

val oT = Type(@{type_name o},[]);

val Trueprop = Const(@{const_name Trueprop}, oT-->propT);

fun mk_Trueprop P = Trueprop $ P;

fun dest_Trueprop (Const (@{const_name Trueprop}, _) $ P) = P
  | dest_Trueprop t = raise TERM ("dest_Trueprop", [t]);


(* Logical constants *)

val not = Const (@{const_name Not}, oT --> oT);
val conj = Const(@{const_name conj}, [oT,oT]--->oT);
val disj = Const(@{const_name disj}, [oT,oT]--->oT);
val imp = Const(@{const_name imp}, [oT,oT]--->oT)
val iff = Const(@{const_name iff}, [oT,oT]--->oT);

fun mk_conj (t1, t2) = conj $ t1 $ t2
and mk_disj (t1, t2) = disj $ t1 $ t2
and mk_imp (t1, t2) = imp $ t1 $ t2
and mk_iff (t1, t2) = iff $ t1 $ t2;

fun dest_imp (Const(@{const_name imp},_) $ A $ B) = (A, B)
  | dest_imp  t = raise TERM ("dest_imp", [t]);

fun dest_conj (Const (@{const_name conj}, _) $ t $ t') = t :: dest_conj t'
  | dest_conj t = [t];

fun dest_iff (Const(@{const_name iff},_) $ A $ B) = (A, B)
  | dest_iff  t = raise TERM ("dest_iff", [t]);

fun eq_const T = Const (@{const_name eq}, [T, T] ---> oT);
fun mk_eq (t, u) = eq_const (fastype_of t) $ t $ u;

fun dest_eq (Const (@{const_name eq}, _) $ lhs $ rhs) = (lhs, rhs)
  | dest_eq t = raise TERM ("dest_eq", [t])

fun all_const T = Const (@{const_name All}, [T --> oT] ---> oT);
fun mk_all (Free (x, T), P) = all_const T $ absfree (x, T) P;

fun exists_const T = Const (@{const_name Ex}, [T --> oT] ---> oT);
fun mk_exists (Free (x, T), P) = exists_const T $ absfree (x, T) P;


(* binary oprations and relations *)

fun mk_binop c (t, u) =
  let val T = fastype_of t in
    Const (c, [T, T] ---> T) $ t $ u
  end;

fun mk_binrel c (t, u) =
  let val T = fastype_of t in
    Const (c, [T, T] ---> oT) $ t $ u
  end;

fun dest_bin c T (tm as Const (c', Type ("fun", [T', _])) $ t $ u) =
      if c = c' andalso T = T' then (t, u)
      else raise TERM ("dest_bin " ^ c, [tm])
  | dest_bin c _ tm = raise TERM ("dest_bin " ^ c, [tm]);

end;
