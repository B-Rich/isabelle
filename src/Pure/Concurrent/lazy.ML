(*  Title:      Pure/Concurrent/lazy.ML
    Author:     Makarius

Lazy evaluation with memoing of results and regular exceptions.
Parallel version based on (passive) futures, to avoid critical or
multiple evaluation (unless interrupted).
*)

signature LAZY =
sig
  type 'a lazy
  val value: 'a -> 'a lazy
  val lazy_name: string -> (unit -> 'a) -> 'a lazy
  val lazy: (unit -> 'a) -> 'a lazy
  val peek: 'a lazy -> 'a Exn.result option
  val is_running: 'a lazy -> bool
  val is_finished: 'a lazy -> bool
  val force_result: 'a lazy -> 'a Exn.result
  val force: 'a lazy -> 'a
  val force_list: 'a lazy list -> 'a list
  val map: ('a -> 'b) -> 'a lazy -> 'b lazy
  val future: Future.params -> 'a lazy -> 'a future
end;

structure Lazy: LAZY =
struct

(* datatype *)

datatype 'a expr =
  Expr of string * (unit -> 'a) |
  Result of 'a future;

abstype 'a lazy = Value of 'a | Lazy of 'a expr Synchronized.var
with

fun value a = Value a;

fun lazy_name name e = Lazy (Synchronized.var "lazy" (Expr (name, e)));
fun lazy e = lazy_name "lazy" e;

fun peek (Value a) = SOME (Exn.Res a)
  | peek (Lazy var) =
      (case Synchronized.value var of
        Expr _ => NONE
      | Result res => Future.peek res);

fun pending (Value _) = false
  | pending (Lazy var) =
      (case Synchronized.value var of
        Expr _ => true
      | Result _ => false);



(* status *)

fun is_running (Value _) = false
  | is_running (Lazy var) =
      (case Synchronized.value var of
        Expr _ => false
      | Result res => not (Future.is_finished res));

fun is_finished (Value _) = true
  | is_finished (Lazy var) =
      (case Synchronized.value var of
        Expr _ => false
      | Result res =>
          Future.is_finished res andalso not (Exn.is_interrupt_exn (Future.join_result res)));


(* force result *)

fun force_result (Value a) = Exn.Res a
  | force_result (Lazy var) =
      (case peek (Lazy var) of
        SOME res => res
      | NONE =>
          Thread_Attributes.uninterruptible (fn restore_attributes => fn () =>
            let
              val (expr, x) =
                Synchronized.change_result var
                  (fn Expr (name, e) =>
                        let val x = Future.promise_name name I
                        in ((SOME (name, e), x), Result x) end
                    | Result x => ((NONE, x), Result x));
            in
              (case expr of
                SOME (name, e) =>
                  let
                    val res0 = Exn.capture (restore_attributes e) ();
                    val _ = Exn.capture (fn () => Future.fulfill_result x res0) ();
                    val res = Future.join_result x;
                    (*semantic race: some other threads might see the same
                      interrupt, until there is a fresh start*)
                    val _ =
                      if Exn.is_interrupt_exn res then
                        Synchronized.change var (fn _ => Expr (name, e))
                      else ();
                  in res end
              | NONE => Exn.capture (restore_attributes (fn () => Future.join x)) ())
            end) ());

end;

fun force x = Exn.release (force_result x);

fun force_list xs =
  (List.app (fn x => if pending x then ignore (force_result x) else ()) xs;
   map force xs);

fun map f x = lazy_name "Lazy.map" (fn () => f (force x));


(* future evaluation *)

fun future params x =
  if is_finished x then Future.value_result (force_result x)
  else (singleton o Future.forks) params (fn () => force x);


(* toplevel pretty printing *)

val _ =
  ML_system_pp (fn depth => fn pretty => fn x =>
    (case peek x of
      NONE => PolyML_Pretty.PrettyString "<lazy>"
    | SOME (Exn.Exn _) => PolyML_Pretty.PrettyString "<failed>"
    | SOME (Exn.Res y) => pretty (y, depth)));

end;

type 'a lazy = 'a Lazy.lazy;
