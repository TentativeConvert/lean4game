import NNG.Metadata
import NNG.MyNat.Addition

Game "NNG"
World "Function"
Level 8
Title ""

open MyNat

Introduction
"

"

Statement
""
    (P Q : Type) : (P → Q) → ((Q → Empty) → (P → Empty)) := by
  intros f h p
  apply h
  apply f
  exact p

Conclusion
"

"
