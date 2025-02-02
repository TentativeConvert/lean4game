import Adam.Metadata

import Mathlib.Data.Set.Basic

set_option tactic.hygienic false

Game "Adam"
World "SetTheory"
Level 8

Title "Schnittmenge und Vereinigung"

Introduction
"
Ansonsten gibt es jegliche Lemmas in

`import Mathlib.Data.Set.Basic`

die beim Umgang mit diesen Operationen weiterhelfen. Schaue in der Bibliothek auf
der Seite nach Lemmas, die dir hier weiterhelfen!
"

open Set

Statement
""
    (A B : Set ℕ) : univ \ (A ∩ B) = (univ \ A) ∪ (univ \ B) ∪ (A \ B) := by
  rw [diff_inter]
  rw [union_assoc]
  rw [←union_diff_distrib]
  rw [univ_union]

NewTactic constructor intro rw assumption rcases simp tauto trivial
NewLemma Set.diff_inter Set.union_assoc Set.union_diff_distrib Set.univ_union
