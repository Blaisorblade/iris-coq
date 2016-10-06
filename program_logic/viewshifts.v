From iris.program_logic Require Export invariants.
From iris.proofmode Require Import tactics.

Definition vs `{irisG Λ Σ} (E1 E2 : coPset) (P Q : iProp Σ) : iProp Σ :=
  (□ (P → |={E1,E2}=> Q))%I.
Arguments vs {_ _ _} _ _ _%I _%I.

Instance: Params (@vs) 5.
Notation "P ={ E1 , E2 }=> Q" := (vs E1 E2 P Q)
  (at level 99, E1,E2 at level 50, Q at level 200,
   format "P  ={ E1 , E2 }=>  Q") : uPred_scope.
Notation "P ={ E }=> Q" := (P ={E,E}=> Q)%I
  (at level 99, E at level 50, Q at level 200,
   format "P  ={ E }=>  Q") : uPred_scope.

Notation "P ={ E1 , E2 }▷=> Q" := (P ={E1,E2}=> ▷ |={E2,E1}=> Q)%I
  (at level 99, E1, E2 at level 50, Q at level 200,
   format "P ={ E1 , E2 }▷=>  Q") : uPred_scope.
Notation "P ={ E }▷=> Q" := (P ={E,E}▷=> Q)%I
  (at level 99, E at level 50, Q at level 200,
   format "P ={ E }▷=>  Q") : uPred_scope.

Section vs.
Context `{irisG Λ Σ}.
Implicit Types P Q R : iProp Σ.
Implicit Types N : namespace.

Global Instance vs_ne E1 E2 n: Proper (dist n ==> dist n ==> dist n) (vs E1 E2).
Proof. solve_proper. Qed.

Global Instance vs_proper E1 E2 : Proper ((≡) ==> (≡) ==> (≡)) (vs E1 E2).
Proof. apply ne_proper_2, _. Qed.

Lemma vs_mono E1 E2 P P' Q Q' :
  (P ⊢ P') → (Q' ⊢ Q) → (P' ={E1,E2}=> Q') ⊢ P ={E1,E2}=> Q.
Proof. by intros HP HQ; rewrite /vs -HP HQ. Qed.

Global Instance vs_mono' E1 E2 : Proper (flip (⊢) ==> (⊢) ==> (⊢)) (vs E1 E2).
Proof. solve_proper. Qed.

Lemma vs_false_elim E1 E2 P : False ={E1,E2}=> P.
Proof. iIntros "[]". Qed.
Lemma vs_timeless E P : TimelessP P → ▷ P ={E}=> P.
Proof. by iIntros (?) "> ?". Qed.

Lemma vs_transitive E1 E2 E3 P Q R :
  (P ={E1,E2}=> Q) ∧ (Q ={E2,E3}=> R) ⊢ P ={E1,E3}=> R.
Proof.
  iIntros "#[HvsP HvsQ] !# HP".
  iVs ("HvsP" with "HP") as "HQ". by iApply "HvsQ".
Qed.

Lemma vs_reflexive E P : P ={E}=> P.
Proof. by iIntros "HP". Qed.

Lemma vs_impl E P Q : □ (P → Q) ⊢ P ={E}=> Q.
Proof. iIntros "#HPQ !# HP". by iApply "HPQ". Qed.

Lemma vs_frame_l E1 E2 P Q R : (P ={E1,E2}=> Q) ⊢ R ★ P ={E1,E2}=> R ★ Q.
Proof. iIntros "#Hvs !# [$ HP]". by iApply "Hvs". Qed.

Lemma vs_frame_r E1 E2 P Q R : (P ={E1,E2}=> Q) ⊢ P ★ R ={E1,E2}=> Q ★ R.
Proof. iIntros "#Hvs !# [HP $]". by iApply "Hvs". Qed.

Lemma vs_mask_frame_r E1 E2 Ef P Q :
  E1 ⊥ Ef → (P ={E1,E2}=> Q) ⊢ P ={E1 ∪ Ef,E2 ∪ Ef}=> Q.
Proof.
  iIntros (?) "#Hvs !# HP". iApply pvs_mask_frame_r; auto. by iApply "Hvs".
Qed.

Lemma vs_inv N E P Q R :
  nclose N ⊆ E → inv N R ★ (▷ R ★ P ={E ∖ nclose N}=> ▷ R ★ Q) ⊢ P ={E}=> Q.
Proof.
  iIntros (?) "#[? Hvs] !# HP". iInv N as "HR" "Hclose".
  iVs ("Hvs" with "[HR HP]") as "[? $]"; first by iFrame.
  by iApply "Hclose".
Qed.

Lemma vs_alloc N P : ▷ P ={N}=> inv N P.
Proof. iIntros "HP". by iApply inv_alloc. Qed.
End vs.
