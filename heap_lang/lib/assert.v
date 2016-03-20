From iris.heap_lang Require Export derived.
From iris.heap_lang Require Import wp_tactics substitution notation.

Definition Assert {X} (e : expr X) : expr X :=
  if: e then #() else #0 #0. (* #0 #0 is unsafe *)

Instance do_wsubst_assert {X Y} x es (H : X `included` x :: Y) e er :
  WSubst x es H e er → WSubst x es H (Assert e) (Assert er) | 1.
Proof. intros; red. by rewrite /Assert /wsubst -/wsubst; f_equal/=. Qed.
Instance do_wexpr_assert {X Y} (H : X `included` Y) e er :
  WExpr H e er → WExpr H (Assert e) (Assert er) | 1.
Proof. intros; red. by rewrite /Assert /wexpr -/wexpr; f_equal/=. Qed.

Lemma wp_assert {Σ} (Φ : val → iProp heap_lang Σ) :
  ▷ Φ #() ⊢ WP Assert #true {{ Φ }}.
Proof. by rewrite -wp_if_true -wp_value. Qed.

Lemma wp_assert' {Σ} (Φ : val → iProp heap_lang Σ) e :
  WP e {{ λ v, v = #true ∧ ▷ Φ #() }} ⊢ WP Assert e {{ Φ }}.
Proof.
  rewrite /Assert. wp_focus e; apply wp_mono=>v.
  apply uPred.const_elim_l=>->. apply wp_assert.
Qed.