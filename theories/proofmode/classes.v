From iris.base_logic Require Export base_logic.
Set Default Proof Using "Type".
Import uPred.

(* The Or class is useful for efficiency: instead of having two instances
[P → Q1 → R] and [P → Q2 → R] we could have one instance [P → Or Q1 Q2 → R],
which avoids the need to derive [P] twice. *)
Inductive Or (P1 P2 : Type) :=
  | Or_l : P1 → Or P1 P2
  | Or_r : P2 → Or P1 P2.
Existing Class Or.
Existing Instance Or_l | 9.
Existing Instance Or_r | 10.

Class FromAssumption {M} (p : bool) (P Q : uPred M) :=
  from_assumption : □?p P ⊢ Q.
Arguments from_assumption {_} _ _ _ {_}.
(* No need to restrict Hint Mode, we have a default instance that will always
be used in case of evars *)
Hint Mode FromAssumption + + - - : typeclass_instances.

Class IntoPure {M} (P : uPred M) (φ : Prop) := into_pure : P ⊢ ⌜φ⌝.
Arguments into_pure {_} _ _ {_}.
Hint Mode IntoPure + ! - : typeclass_instances.

Class FromPure {M} (P : uPred M) (φ : Prop) := from_pure : ⌜φ⌝ ⊢ P.
Arguments from_pure {_} _ _ {_}.
Hint Mode FromPure + ! - : typeclass_instances.

Class IntoPersistentP {M} (P Q : uPred M) := into_persistentP : P ⊢ □ Q.
Arguments into_persistentP {_} _ _ {_}.
Hint Mode IntoPersistentP + ! - : typeclass_instances.

(* The class [IntoLaterN] has only two instances:

- The default instance [IntoLaterN n P P], i.e. [▷^n P -∗ P]
- The instance [IntoLaterN' n P Q → IntoLaterN n P Q], where [IntoLaterN']
  is identical to [IntoLaterN], but computationally is supposed to make
  progress, i.e. its instances should actually strip a later.

The point of using the auxilary class [IntoLaterN'] is to ensure that the
default instance is not applied deeply in the term, which may cause in too many
definitions being unfolded (see issue #55).

For binary connectives we have the following instances:

<<
IntoLaterN' n P P'       IntoLaterN n Q Q'
------------------------------------------
     IntoLaterN' n (P /\ Q) (P' /\ Q')


      IntoLaterN' n Q Q'
-------------------------------
IntoLaterN n (P /\ Q) (P /\ Q')
>>
*)
Class IntoLaterN {M} (n : nat) (P Q : uPred M) := into_laterN : P ⊢ ▷^n Q.
Arguments into_laterN {_} _ _ _ {_}.
Hint Mode IntoLaterN + - - - : typeclass_instances.

Class IntoLaterN' {M} (n : nat) (P Q : uPred M) :=
  into_laterN' :> IntoLaterN n P Q.
Arguments into_laterN' {_} _ _ _ {_}.
Hint Mode IntoLaterN' + - ! - : typeclass_instances.

Instance into_laterN_default {M} n (P : uPred M) : IntoLaterN n P P | 1000.
Proof. apply laterN_intro. Qed.

Class FromLaterN {M} (n : nat) (P Q : uPred M) := from_laterN : ▷^n Q ⊢ P.
Arguments from_laterN {_} _ _ _ {_}.
Hint Mode FromLaterN + - ! - : typeclass_instances.

Class WandWeaken {M} (p : bool) (P Q P' Q' : uPred M) :=
  wand_weaken : (P -∗ Q) ⊢ (□?p P' -∗ Q').
Hint Mode WandWeaken + + - - - - : typeclass_instances.

Class WandWeaken' {M} (p : bool) (P Q P' Q' : uPred M) :=
  wand_weaken' :> WandWeaken p P Q P' Q'.
Hint Mode WandWeaken' + + - - ! - : typeclass_instances.
Hint Mode WandWeaken' + + - - - ! : typeclass_instances.

Class IntoWand {M} (p : bool) (R P Q : uPred M) := into_wand : R ⊢ □?p P -∗ Q.
Arguments into_wand {_} _ _ _ _ {_}.
Hint Mode IntoWand + + ! - - : typeclass_instances.

Class FromAnd {M} (p : bool) (P Q1 Q2 : uPred M) :=
  from_and : (if p then Q1 ∧ Q2 else Q1 ∗ Q2) ⊢ P.
Arguments from_and {_} _ _ _ _ {_}.
Hint Mode FromAnd + + ! - - : typeclass_instances.
Hint Mode FromAnd + + - ! ! : typeclass_instances. (* For iCombine *)
Lemma mk_from_and_and {M} p (P Q1 Q2 : uPred M) :
  (Q1 ∧ Q2 ⊢ P) → FromAnd p P Q1 Q2.
Proof. rewrite /FromAnd=><-. destruct p; auto using sep_and. Qed.
Lemma mk_from_and_persistent {M} (P Q1 Q2 : uPred M) :
  Or (PersistentP Q1) (PersistentP Q2) → (Q1 ∗ Q2 ⊢ P) → FromAnd true P Q1 Q2.
Proof.
  intros [?|?] ?; rewrite /FromAnd.
  - by rewrite always_and_sep_l.
  - by rewrite always_and_sep_r.
Qed.

Class IntoAnd {M} (p : bool) (P Q1 Q2 : uPred M) :=
  into_and : P ⊢ if p then Q1 ∧ Q2 else Q1 ∗ Q2.
Arguments into_and {_} _ _ _ _ {_}.
Hint Mode IntoAnd + + ! - - : typeclass_instances.
Lemma mk_into_and_sep {M} p (P Q1 Q2 : uPred M) :
  (P ⊢ Q1 ∗ Q2) → IntoAnd p P Q1 Q2.
Proof. rewrite /IntoAnd=>->. destruct p; auto using sep_and. Qed.

(* There are various versions of [IsOp] with different modes:

- [IsOp a b1 b2]: this one has no mode, it can be used regardless of whether
  any of the arguments is an evar. This class has only one direct instance:
  [IsOp (a ⋅ b) a b].
- [IsOp' a b1 b2]: requires either [a] to start with a constructor, OR [b1] and
  [b2] to start with a constructor. All usual instances should be of this
  class to avoid loops.
- [IsOp'LR a b1 b2]: requires either [a] to start with a constructor. This one
  has just one instance: [IsOp'LR (a ⋅ b) a b] with a very low precendence.
  This is important so that when performing, for example, an [iDestruct] on
  [own γ (q1 + q2)] where [q1] and [q2] are fractions, we actually get
  [own γ q1] and [own γ q2] instead of [own γ ((q1 + q2)/2)] twice.
*)
Class IsOp {A : cmraT} (a b1 b2 : A) := is_op : a ≡ b1 ⋅ b2.
Arguments is_op {_} _ _ _ {_}.
Hint Mode IsOp + - - - : typeclass_instances.

Instance is_op_op {A : cmraT} (a b : A) : IsOp (a ⋅ b) a b | 100.
Proof. by rewrite /IsOp. Qed.

Class IsOp' {A : cmraT} (a b1 b2 : A) := is_op' :> IsOp a b1 b2.
Hint Mode IsOp' + ! - - : typeclass_instances.
Hint Mode IsOp' + - ! ! : typeclass_instances.

Class IsOp'LR {A : cmraT} (a b1 b2 : A) := is_op_lr : IsOp a b1 b2.
Existing Instance is_op_lr | 0.
Hint Mode IsOp'LR + ! - - : typeclass_instances.
Instance is_op_lr_op {A : cmraT} (a b : A) : IsOp'LR (a ⋅ b) a b | 0.
Proof. by rewrite /IsOp'LR /IsOp. Qed.

Class Frame {M} (p : bool) (R P Q : uPred M) := frame : □?p R ∗ Q ⊢ P.
Arguments frame {_ _} _ _ _ {_}.
Hint Mode Frame + + ! ! - : typeclass_instances.

Class MaybeFrame {M} (p : bool) (R P Q : uPred M) := maybe_frame : □?p R ∗ Q ⊢ P.
Arguments maybe_frame {_} _ _ _ {_}.
Hint Mode MaybeFrame + + ! ! - : typeclass_instances.

Instance maybe_frame_frame {M} p (R P Q : uPred M) :
  Frame p R P Q → MaybeFrame p R P Q.
Proof. done. Qed.
Instance maybe_frame_default {M} p (R P : uPred M) : MaybeFrame p R P P | 100.
Proof. apply sep_elim_r. Qed.

Class FromOr {M} (P Q1 Q2 : uPred M) := from_or : Q1 ∨ Q2 ⊢ P.
Arguments from_or {_} _ _ _ {_}.
Hint Mode FromOr + ! - - : typeclass_instances.

Class IntoOr {M} (P Q1 Q2 : uPred M) := into_or : P ⊢ Q1 ∨ Q2.
Arguments into_or {_} _ _ _ {_}.
Hint Mode IntoOr + ! - - : typeclass_instances.

Class FromExist {M A} (P : uPred M) (Φ : A → uPred M) :=
  from_exist : (∃ x, Φ x) ⊢ P.
Arguments from_exist {_ _} _ _ {_}.
Hint Mode FromExist + - ! - : typeclass_instances.

Class IntoExist {M A} (P : uPred M) (Φ : A → uPred M) :=
  into_exist : P ⊢ ∃ x, Φ x.
Arguments into_exist {_ _} _ _ {_}.
Hint Mode IntoExist + - ! - : typeclass_instances.

Class IntoForall {M A} (P : uPred M) (Φ : A → uPred M) :=
  into_forall : P ⊢ ∀ x, Φ x.
Arguments into_forall {_ _} _ _ {_}.
Hint Mode IntoForall + - ! - : typeclass_instances.

Class FromModal {M} (P Q : uPred M) := from_modal : Q ⊢ P.
Arguments from_modal {_} _ _ {_}.
Hint Mode FromModal + ! - : typeclass_instances.

Class ElimModal {M} (P P' : uPred M) (Q Q' : uPred M) :=
  elim_modal : P ∗ (P' -∗ Q') ⊢ Q.
Arguments elim_modal {_} _ _ _ _ {_}.
Hint Mode ElimModal + ! - ! - : typeclass_instances.
Hint Mode ElimModal + - ! - ! : typeclass_instances.

Lemma elim_modal_dummy {M} (P Q : uPred M) : ElimModal P P Q Q.
Proof. by rewrite /ElimModal wand_elim_r. Qed.

Class IsExcept0 {M} (Q : uPred M) := is_except_0 : ◇ Q ⊢ Q.
Arguments is_except_0 {_} _ {_}.
Hint Mode IsExcept0 + ! : typeclass_instances.

Class IsCons {A} (l : list A) (x : A) (k : list A) := is_cons : l = x :: k.
Class IsApp {A} (l k1 k2 : list A) := is_app : l = k1 ++ k2.
Global Hint Mode IsCons + ! - - : typeclass_instances.
Global Hint Mode IsApp + ! - - : typeclass_instances.

Instance is_cons_cons {A} (x : A) (l : list A) : IsCons (x :: l) x l.
Proof. done. Qed.
Instance is_app_app {A} (l1 l2 : list A) : IsApp (l1 ++ l2) l1 l2.
Proof. done. Qed.
