(*  Title:      HOL/HyperBin.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1999  University of Cambridge
*)

header{*Binary arithmetic and Simplification for the Hyperreals*}

theory HyperArith = HyperOrd
files ("hypreal_arith.ML"):

subsection{*Binary Arithmetic for the Hyperreals*}

instance hypreal :: number ..

defs (overloaded)
  hypreal_number_of_def:
    "number_of v == hypreal_of_real (number_of v)"
     (*::bin=>hypreal               ::bin=>real*)
     --{*This case is reduced to that for the reals.*}



subsubsection{*Embedding the Reals into the Hyperreals*}

lemma hypreal_number_of [simp]: "hypreal_of_real (number_of w) = number_of w"
by (simp add: hypreal_number_of_def)

lemma hypreal_numeral_0_eq_0: "Numeral0 = (0::hypreal)"
by (simp add: hypreal_number_of_def)

lemma hypreal_numeral_1_eq_1: "Numeral1 = (1::hypreal)"
by (simp add: hypreal_number_of_def)

subsubsection{*Addition*}

lemma add_hypreal_number_of [simp]:
     "(number_of v :: hypreal) + number_of v' = number_of (bin_add v v')"
by (simp only: hypreal_number_of_def hypreal_of_real_add [symmetric]
               add_real_number_of)


subsubsection{*Subtraction*}

lemma minus_hypreal_number_of [simp]:
     "- (number_of w :: hypreal) = number_of (bin_minus w)"
by (simp only: hypreal_number_of_def minus_real_number_of
               hypreal_of_real_minus [symmetric])

lemma diff_hypreal_number_of [simp]:
     "(number_of v :: hypreal) - number_of w =
      number_of (bin_add v (bin_minus w))"
by (unfold hypreal_number_of_def hypreal_diff_def, simp)


subsubsection{*Multiplication*}

lemma mult_hypreal_number_of [simp]:
     "(number_of v :: hypreal) * number_of v' = number_of (bin_mult v v')"
by (simp only: hypreal_number_of_def hypreal_of_real_mult [symmetric] mult_real_number_of)

text{*Lemmas for specialist use, NOT as default simprules*}
lemma hypreal_mult_2: "2 * z = (z+z::hypreal)"
proof -
  have eq: "(2::hypreal) = 1 + 1"
    by (simp add: hypreal_numeral_1_eq_1 [symmetric])
  thus ?thesis by (simp add: eq left_distrib)
qed

lemma hypreal_mult_2_right: "z * 2 = (z+z::hypreal)"
by (subst hypreal_mult_commute, rule hypreal_mult_2)


subsubsection{*Comparisons*}

(** Equals (=) **)

lemma eq_hypreal_number_of [simp]:
     "((number_of v :: hypreal) = number_of v') =
      iszero (number_of (bin_add v (bin_minus v')))"
apply (simp only: hypreal_number_of_def hypreal_of_real_eq_iff eq_real_number_of)
done


(** Less-than (<) **)

(*"neg" is used in rewrite rules for binary comparisons*)
lemma less_hypreal_number_of [simp]:
     "((number_of v :: hypreal) < number_of v') =
      neg (number_of (bin_add v (bin_minus v')))"
by (simp only: hypreal_number_of_def hypreal_of_real_less_iff less_real_number_of)



text{*New versions of existing theorems involving 0, 1*}

lemma hypreal_minus_1_eq_m1 [simp]: "- 1 = (-1::hypreal)"
by (simp add: hypreal_numeral_1_eq_1 [symmetric])

lemma hypreal_mult_minus1 [simp]: "-1 * z = -(z::hypreal)"
proof -
  have  "-1 * z = (- 1) * z" by (simp add: hypreal_minus_1_eq_m1)
  also have "... = - (1 * z)" by (simp only: minus_mult_left)
  also have "... = -z" by simp
  finally show ?thesis .
qed

lemma hypreal_mult_minus1_right [simp]: "(z::hypreal) * -1 = -z"
by (subst hypreal_mult_commute, rule hypreal_mult_minus1)


subsection{*Simplification of Arithmetic when Nested to the Right*}

lemma hypreal_add_number_of_left [simp]:
     "number_of v + (number_of w + z) = (number_of(bin_add v w) + z::hypreal)"
by (simp add: add_assoc [symmetric])

lemma hypreal_mult_number_of_left [simp]:
     "number_of v *(number_of w * z) = (number_of(bin_mult v w) * z::hypreal)"
by (simp add: hypreal_mult_assoc [symmetric])

lemma hypreal_add_number_of_diff1:
    "number_of v + (number_of w - c) = number_of(bin_add v w) - (c::hypreal)"
by (simp add: hypreal_diff_def hypreal_add_number_of_left)

lemma hypreal_add_number_of_diff2 [simp]:
     "number_of v + (c - number_of w) =
      number_of (bin_add v (bin_minus w)) + (c::hypreal)"
apply (subst diff_hypreal_number_of [symmetric])
apply (simp only: hypreal_diff_def add_ac)
done


declare hypreal_numeral_0_eq_0 [simp] hypreal_numeral_1_eq_1 [simp]



use "hypreal_arith.ML"

setup hypreal_arith_setup

text{*Used once in NSA*}
lemma hypreal_add_minus_eq_minus: "x + y = (0::hypreal) ==> x = -y"
by arith


subsubsection{*Division By @{term 1} and @{term "-1"}*}

lemma hypreal_divide_minus1 [simp]: "x/-1 = -(x::hypreal)"
by simp

lemma hypreal_minus1_divide [simp]: "-1/(x::hypreal) = - (1/x)"
by (simp add: hypreal_divide_def hypreal_minus_inverse)




(** number_of related to hypreal_of_real.
Could similar theorems be useful for other injections? **)

lemma number_of_less_hypreal_of_real_iff [simp]:
     "(number_of w < hypreal_of_real z) = (number_of w < z)"
apply (subst hypreal_of_real_less_iff [symmetric])
apply (simp (no_asm))
done

lemma number_of_le_hypreal_of_real_iff [simp]:
     "(number_of w <= hypreal_of_real z) = (number_of w <= z)"
apply (subst hypreal_of_real_le_iff [symmetric])
apply (simp (no_asm))
done

lemma hypreal_of_real_eq_number_of_iff [simp]:
     "(hypreal_of_real z = number_of w) = (z = number_of w)"
apply (subst hypreal_of_real_eq_iff [symmetric])
apply (simp (no_asm))
done

lemma hypreal_of_real_less_number_of_iff [simp]:
     "(hypreal_of_real z < number_of w) = (z < number_of w)"
apply (subst hypreal_of_real_less_iff [symmetric])
apply (simp (no_asm))
done

lemma hypreal_of_real_le_number_of_iff [simp]:
     "(hypreal_of_real z <= number_of w) = (z <= number_of w)"
apply (subst hypreal_of_real_le_iff [symmetric])
apply (simp (no_asm))
done

(*
FIXME: we should have this, as for type int, but many proofs would break.
It replaces x+-y by x-y.
Addsimps [symmetric hypreal_diff_def]
*)

ML
{*
val hypreal_add_minus_eq_minus = thm "hypreal_add_minus_eq_minus";
*}

end
