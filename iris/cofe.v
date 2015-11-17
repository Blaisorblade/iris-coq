Require Export prelude.prelude.
Obligation Tactic := idtac.

(** Unbundeled version *)
Class Dist A := dist : nat → relation A.
Instance: Params (@dist) 3.
Notation "x ={ n }= y" := (dist n x y)
  (at level 70, n at next level, format "x  ={ n }=  y").
Hint Extern 0 (?x ={_}= ?x) => reflexivity.
Hint Extern 0 (_ ={_}= _) => symmetry; assumption.
Ltac cofe_subst :=
  repeat match goal with
  | _ => progress simplify_equality'
  | H: @dist _ ?d ?n ?x _ |- _ => setoid_subst_aux (@dist _ d n) x
  | H: @dist _ ?d ?n _ ?x |- _ => symmetry in H;setoid_subst_aux (@dist _ d n) x
  end.

Record chain (A : Type) `{Dist A} := {
  chain_car :> nat → A;
  chain_cauchy n i : n ≤ i → chain_car n ={n}= chain_car i
}.
Arguments chain_car {_ _} _ _.
Arguments chain_cauchy {_ _} _ _ _ _.
Class Compl A `{Dist A} := compl : chain A → A.

Class Cofe A `{Equiv A, Compl A} := {
  equiv_dist x y : x ≡ y ↔ ∀ n, x ={n}= y;
  dist_equivalence n :> Equivalence (dist n);
  dist_S n x y : x ={S n}= y → x ={n}= y;
  dist_0 x y : x ={0}= y;
  conv_compl (c : chain A) n : compl c ={n}= c n
}.
Hint Extern 0 (_ ={0}= _) => apply dist_0.
Class Contractive `{Dist A, Dist B} (f : A -> B) :=
  contractive n : Proper (dist n ==> dist (S n)) f.

(** Bundeled version *)
Structure cofeT := CofeT {
  cofe_car :> Type;
  cofe_equiv : Equiv cofe_car;
  cofe_dist : Dist cofe_car;
  cofe_compl : Compl cofe_car;
  cofe_cofe : Cofe cofe_car
}.
Arguments CofeT _ {_ _ _ _}.
Add Printing Constructor cofeT.
Existing Instances cofe_equiv cofe_dist cofe_compl cofe_cofe.

(** General properties *)
Section cofe.
  Context `{Cofe A}.
  Global Instance cofe_equivalence : Equivalence ((≡) : relation A).
  Proof.
    split.
    * by intros x; rewrite equiv_dist.
    * by intros x y; rewrite !equiv_dist.
    * by intros x y z; rewrite !equiv_dist; intros; transitivity y.
  Qed.
  Global Instance dist_ne n : Proper (dist n ==> dist n ==> iff) (dist n).
  Proof.
    intros x1 x2 ? y1 y2 ?; split; intros.
    * by transitivity x1; [done|]; transitivity y1.
    * by transitivity x2; [done|]; transitivity y2.
  Qed.
  Global Instance dist_proper n : Proper ((≡) ==> (≡) ==> iff) (dist n).
  Proof.
    intros x1 x2 Hx y1 y2 Hy.
    by rewrite equiv_dist in Hx, Hy; rewrite (Hx n), (Hy n).
  Qed.
  Global Instance dist_proper_2 n x : Proper ((≡) ==> iff) (dist n x).
  Proof. by apply dist_proper. Qed.
  Lemma dist_le x y n n' : x ={n}= y → n' ≤ n → x ={n'}= y.
  Proof. induction 2; eauto using dist_S. Qed.
  Instance ne_proper `{Cofe B} (f : A → B)
    `{!∀ n, Proper (dist n ==> dist n) f} : Proper ((≡) ==> (≡)) f | 100.
  Proof. by intros x1 x2; rewrite !equiv_dist; intros Hx n; rewrite (Hx n). Qed.
  Instance ne_proper_2 `{Cofe B, Cofe C} (f : A → B → C)
    `{!∀ n, Proper (dist n ==> dist n ==> dist n) f} :
    Proper ((≡) ==> (≡) ==> (≡)) f | 100.
  Proof.
     unfold Proper, respectful; setoid_rewrite equiv_dist.
     by intros x1 x2 Hx y1 y2 Hy n; rewrite Hx, Hy.
  Qed.
  Lemma compl_ne (c1 c2: chain A) n : c1 n ={n}= c2 n → compl c1 ={n}= compl c2.
  Proof. intros. by rewrite (conv_compl c1 n), (conv_compl c2 n). Qed.
  Lemma compl_ext (c1 c2 : chain A) : (∀ i, c1 i ≡ c2 i) → compl c1 ≡ compl c2.
  Proof. setoid_rewrite equiv_dist; naive_solver eauto using compl_ne. Qed.
  Global Instance contractive_ne `{Cofe B} (f : A → B) `{!Contractive f} n :
    Proper (dist n ==> dist n) f | 100.
  Proof. by intros x1 x2 ?; apply dist_S, contractive. Qed.
  Global Instance contractive_proper `{Cofe B} (f : A → B) `{!Contractive f} :
    Proper ((≡) ==> (≡)) f | 100 := _.
End cofe.

(** Fixpoint *)
Program Definition fixpoint_chain `{Cofe A, Inhabited A} (f : A → A)
  `{!Contractive f} : chain A := {| chain_car i := Nat.iter i f inhabitant |}.
Next Obligation.
  intros A ???? f ? x n; induction n as [|n IH]; intros i ?; [done|].
  destruct i as [|i]; simpl; try lia; apply contractive, IH; auto with lia.
Qed.
Program Definition fixpoint `{Cofe A, Inhabited A} (f : A → A)
  `{!Contractive f} : A := compl (fixpoint_chain f).

Section fixpoint.
  Context `{Cofe A, Inhabited A} (f : A → A) `{!Contractive f}.
  Lemma fixpoint_unfold : fixpoint f ≡ f (fixpoint f).
  Proof.
    apply equiv_dist; intros n; unfold fixpoint.
    rewrite (conv_compl (fixpoint_chain f) n).
    by rewrite (chain_cauchy (fixpoint_chain f) n (S n)) at 1 by lia.
  Qed.
  Lemma fixpoint_ne (g : A → A) `{!Contractive g} n :
    (∀ z, f z ={n}= g z) → fixpoint f ={n}= fixpoint g.
  Proof.
    intros Hfg; unfold fixpoint.
    rewrite (conv_compl (fixpoint_chain f) n),(conv_compl (fixpoint_chain g) n).
    induction n as [|n IH]; simpl in *; [done|].
    rewrite Hfg; apply contractive, IH; auto using dist_S.
  Qed.
  Lemma fixpoint_proper (g : A → A) `{!Contractive g} :
    (∀ x, f x ≡ g x) → fixpoint f ≡ fixpoint g.
  Proof. setoid_rewrite equiv_dist; naive_solver eauto using fixpoint_ne. Qed.
End fixpoint.
Global Opaque fixpoint.

(** Function space *)
Structure cofeMor (A B : cofeT) : Type := CofeMor {
  cofe_mor_car :> A → B;
  cofe_mor_ne n : Proper (dist n ==> dist n) cofe_mor_car
}.
Arguments CofeMor {_ _} _ {_}.
Add Printing Constructor cofeMor.
Existing Instance cofe_mor_ne.

Instance cofe_mor_proper `(f : cofeMor A B) : Proper ((≡) ==> (≡)) f := _.
Instance cofe_mor_equiv {A B : cofeT} : Equiv (cofeMor A B) := λ f g,
  ∀ x, f x ≡ g x.
Instance cofe_mor_dist (A B : cofeT) : Dist (cofeMor A B) := λ n f g,
  ∀ x, f x ={n}= g x.
Program Definition fun_chain `(c : chain (cofeMor A B)) (x : A) : chain B :=
  {| chain_car n := c n x |}.
Next Obligation. intros A B c x n i ?. by apply (chain_cauchy c). Qed.
Program Instance cofe_mor_compl (A B : cofeT) : Compl (cofeMor A B) := λ c,
  {| cofe_mor_car x := compl (fun_chain c x) |}.
Next Obligation.
  intros A B c n x y Hxy.
  rewrite (conv_compl (fun_chain c x) n), (conv_compl (fun_chain c y) n).
  simpl; rewrite Hxy; apply (chain_cauchy c); lia.
Qed.
Instance cofe_mor_cofe (A B : cofeT) : Cofe (cofeMor A B).
Proof.
  split.
  * intros X Y; split; [intros HXY n k; apply equiv_dist, HXY|].
    intros HXY k; apply equiv_dist; intros n; apply HXY.
  * intros n; split.
    + by intros f x.
    + by intros f g ? x.
    + by intros f g h ?? x; transitivity (g x).
  * by intros n f g ? x; apply dist_S.
  * by intros f g x.
  * intros c n x; simpl.
    rewrite (conv_compl (fun_chain c x) n); apply (chain_cauchy c); lia.
Qed.
Instance cofe_mor_car_ne A B n :
  Proper (dist n ==> dist n ==> dist n) (@cofe_mor_car A B).
Proof. intros f g Hfg x y Hx; rewrite Hx; apply Hfg. Qed.
Instance cofe_mor_car_proper A B :
  Proper ((≡) ==> (≡) ==> (≡)) (@cofe_mor_car A B) := ne_proper_2 _.
Lemma cofe_mor_ext {A B} (f g : cofeMor A B) : f ≡ g ↔ ∀ x, f x ≡ g x.
Proof. done. Qed.
Canonical Structure cofe_mor (A B : cofeT) : cofeT := CofeT (cofeMor A B).
Infix "-n>" := cofe_mor (at level 45, right associativity).
Instance cofe_more_inhabited (A B : cofeT)
  `{Inhabited B} : Inhabited (A -n> B) := populate (CofeMor (λ _, inhabitant)).

(** Identity and composition *)
Definition cid {A} : A -n> A := CofeMor id.
Instance: Params (@cid) 1.
Definition ccompose {A B C}
  (f : B -n> C) (g : A -n> B) : A -n> C := CofeMor (f ∘ g).
Instance: Params (@ccompose) 3.
Infix "◎" := ccompose (at level 40, left associativity).
Lemma ccompose_ne {A B C} (f1 f2 : B -n> C) (g1 g2 : A -n> B) n :
  f1 ={n}= f2 → g1 ={n}= g2 → f1 ◎ g1 ={n}= f2 ◎ g2.
Proof. by intros Hf Hg x; simpl; rewrite (Hg x), (Hf (g2 x)). Qed.

(** Pre-composition as a functor *)
Local Instance ccompose_l_ne' {A B C} (f : B -n> A) n :
  Proper (dist n ==> dist n) (λ g : A -n> C, g ◎ f).
Proof. by intros g1 g2 ?; apply ccompose_ne. Qed.
Definition ccompose_l {A B C} (f : B -n> A) : (A -n> C) -n> (B -n> C) :=
  CofeMor (λ g : A -n> C, g ◎ f).
Instance ccompose_l_ne {A B C} : Proper (dist n ==> dist n) (@ccompose_l A B C).
Proof. by intros n f1 f2 Hf g x; apply ccompose_ne. Qed.

(** unit *)
Instance unit_dist : Dist unit := λ _ _ _, True.
Instance unit_compl : Compl unit := λ _, ().
Instance unit_cofe : Cofe unit.
Proof. by repeat split; try exists 0. Qed.

(** Product *)
Instance prod_dist `{Dist A, Dist B} : Dist (A * B) := λ n,
  prod_relation (dist n) (dist n).
Program Definition fst_chain `{Dist A, Dist B} (c : chain (A * B)) : chain A :=
  {| chain_car n := fst (c n) |}.
Next Obligation. by intros A ? B ? c n i ?; apply (chain_cauchy c n). Qed.
Program Definition snd_chain `{Dist A, Dist B} (c : chain (A * B)) : chain B :=
  {| chain_car n := snd (c n) |}.
Next Obligation. by intros A ? B ? c n i ?; apply (chain_cauchy c n). Qed.
Instance prod_compl `{Compl A, Compl B} : Compl (A * B) := λ c,
  (compl (fst_chain c), compl (snd_chain c)).
Instance prod_cofe `{Cofe A, Cofe B} : Cofe (A * B).
Proof.
  split.
  * intros x y; unfold dist, prod_dist, equiv, prod_equiv, prod_relation.
    rewrite !equiv_dist; naive_solver.
  * apply _.
  * by intros n [x1 y1] [x2 y2] [??]; split; apply dist_S.
  * by split.
  * intros c n; split. apply (conv_compl (fst_chain c) n).
    apply (conv_compl (snd_chain c) n).
Qed.
Canonical Structure prodC (A B : cofeT) : cofeT := CofeT (A * B).
Instance prod_map_ne `{Dist A, Dist A', Dist B, Dist B'} n :
  Proper ((dist n ==> dist n) ==> (dist n ==> dist n) ==>
           dist n ==> dist n) (@prod_map A A' B B').
Proof. by intros f f' Hf g g' Hg ?? [??]; split; [apply Hf|apply Hg]. Qed.
Definition prodC_map {A A' B B'} (f : A -n> A') (g : B -n> B') :
  prodC A B -n> prodC A' B' := CofeMor (prod_map f g).
Instance prodC_map_ne {A A' B B'} n :
  Proper (dist n ==> dist n ==> dist n) (@prodC_map A A' B B').
Proof. intros f f' Hf g g' Hg [??]; split; [apply Hf|apply Hg]. Qed.

Instance pair_ne `{Dist A, Dist B} :
  Proper (dist n ==> dist n ==> dist n) (@pair A B) := _.
Instance fst_ne `{Dist A, Dist B} : Proper (dist n ==> dist n) (@fst A B) := _.
Instance snd_ne `{Dist A, Dist B} : Proper (dist n ==> dist n) (@snd A B) := _.
Typeclasses Opaque prod_dist.

(** Discrete cofe *)
Section discrete_cofe.
  Context `{Equiv A, @Equivalence A (≡)}.
  Instance discrete_dist : Dist A := λ n x y,
    match n with 0 => True | S n => x ≡ y end.
  Instance discrete_compl : Compl A := λ c, c 1.
  Instance discrete_cofe : Cofe A.
  Proof.
    split.
    * intros x y; split; [by intros ? []|intros Hn; apply (Hn 1)].
    * intros [|n]; [done|apply _].
    * by intros [|n].
    * done.
    * intros c [|n]; [done|apply (chain_cauchy c 1 (S n)); lia].
  Qed.
  Definition discrete_cofeC : cofeT := CofeT A.
End discrete_cofe.
Arguments discrete_cofeC _ {_ _}.

(** Later *)
Inductive later (A : Type) : Type := Later { later_car : A }.
Arguments Later {_} _.
Arguments later_car {_} _.
Section later.
  Instance later_equiv `{Equiv A} : Equiv (later A) := λ x y,
    later_car x ≡ later_car y.
  Instance later_dist `{Dist A} : Dist (later A) := λ n x y,
    match n with 0 => True | S n => later_car x ={n}= later_car y end.
  Program Definition later_chain `{Dist A} (c : chain (later A)) : chain A :=
    {| chain_car n := later_car (c (S n)) |}.
  Next Obligation. intros A ? c n i ?; apply (chain_cauchy c (S n)); lia. Qed.
  Instance later_compl `{Compl A} : Compl (later A) := λ c,
    Later (compl (later_chain c)).
  Instance later_cofe `{Cofe A} : Cofe (later A).
  Proof.
    split.
    * intros x y; unfold equiv, later_equiv; rewrite !equiv_dist.
      split. intros Hxy [|n]; [done|apply Hxy]. intros Hxy n; apply (Hxy (S n)).
    * intros [|n]; [by split|split]; unfold dist, later_dist.
      + by intros [x].
      + by intros [x] [y].
      + by intros [x] [y] [z] ??; transitivity y.
    * intros [|n] [x] [y] ?; [done|]; unfold dist, later_dist; by apply dist_S.
    * done.
    * intros c [|n]; [done|by apply (conv_compl (later_chain c) n)].
  Qed.
  Canonical Structure laterC (A : cofeT) : cofeT := CofeT (later A).

  Instance later_fmap : FMap later := λ A B f x, Later (f (later_car x)).
  Instance later_fmap_ne `{Cofe A, Cofe B} (f : A → B) :
    (∀ n, Proper (dist n ==> dist n) f) →
    ∀ n, Proper (dist n ==> dist n) (fmap f : later A → later B).
  Proof. intros Hf [|n] [x] [y] ?; do 2 red; simpl. done. by apply Hf. Qed.
  Lemma later_fmap_id {A} (x : later A) : id <$> x = x.
  Proof. by destruct x. Qed.
  Lemma later_fmap_compose {A B C} (f : A → B) (g : B → C) (x : later A) :
    g ∘ f <$> x = g <$> f <$> x.
  Proof. by destruct x. Qed.
  Definition laterC_map {A B} (f : A -n> B) : laterC A -n> laterC B :=
    CofeMor (fmap f : laterC A → laterC B).
  Instance laterC_map_contractive (A B : cofeT) : Contractive (@laterC_map A B).
  Proof. intros n f g Hf n'; apply Hf. Qed.
End later.
