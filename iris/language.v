Require Import prelude.prelude.

Class Language (E V St : Type) := {
  of_val : V → E;
  to_val : E → option V;
  atomic : E → Prop;
  prim_step : E → St → E → St → option E → Prop;
  to_of_val v : to_val (of_val v) = Some v;
  of_to_val e v : to_val e = Some v → of_val v = e;
  values_stuck e σ e' σ' ef : prim_step e σ e' σ' ef → to_val e = None;
  atomic_not_value e : atomic e → to_val e = None;
  atomic_step e1 σ1 e2 σ2 ef :
    atomic e1 →
    prim_step e1 σ1 e2 σ2 ef →
    is_Some (to_val e2)
}.

Section language.
  Context `{Language E V St}.

  Definition cfg : Type := (list E * St)%type.
  Inductive step (ρ1 ρ2 : cfg) : Prop :=
    | step_atomic e1 σ1 e2 σ2 ef t1 t2 :
       ρ1 = (t1 ++ e1 :: t2, σ1) →
       ρ1 = (t1 ++ e2 :: t2 ++ option_list ef, σ2) →
       prim_step e1 σ1 e2 σ2 ef →
       step ρ1 ρ2.

  Definition steps := rtc step.
  Definition stepn := nsteps step.

  Record is_ctx (K : E → E) := IsCtx {
    is_ctx_value e : is_Some (to_val (K e)) → is_Some (to_val e);
    is_ctx_step_preserved e1 σ1 e2 σ2 ef :
      prim_step e1 σ1 e2 σ2 ef → prim_step (K e1) σ1 (K e2) σ2 ef;
    is_ctx_step e1' σ1 e2 σ2 ef :
      to_val e1' = None → prim_step (K e1') σ1 e2 σ2 ef →
      ∃ e2', e2 = K e2' ∧ prim_step e1' σ1 e2' σ2 ef
  }.
End language.

