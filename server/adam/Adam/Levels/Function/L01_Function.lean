import Adam.Metadata
import Mathlib

Game "Adam"
World "Function"
Level 1

Title "Anonyme Funktionen"

Introduction
"
Auf die Frage hin, ob sie von einem Bibliothek wisse, erzählt euch das kleine Mädchen,
dass es auf der Insel nur einen gäbe, aber sie bedrängt euch so mit einer Frage,
dass sie euch gar nicht sagt, wo dieser zu finden sei.
"

Statement "" : ∃ f : ℤ → ℤ, ∀ x, f x < x := by
  use (fun x ↦ x - 1)
  simp

Hint : ∃ f : ℤ → ℤ, ∀ x, f x < x =>
"
**Robo**: `f : ℤ → ℤ` ist die Notation für eine Funktion und `f x` ist diese Funktion
angewendet auf ein Element `(x : ℤ)`.

**Du**: War `→` nicht eben noch eine Implikation?

**Robo**: Doch, die brauchen das gleiche Zeichen für beides.

**Du**: Dann ist `f : ℤ → ℤ` also einfach abstrakt irgendeine Funktion,
wie definier ich aber jetzt konkret eine Abbildungsvorschrift?

**Robo**: Man kennt hier eine Notation für eine anonyme Funktion:
`fun (x : ℤ) ↦ x ^ 2` ist

$$
\\begin\{aligned}
  f : \\mathbb\{ℤ} &\\to \\mathbb\{ℤ} \\\\
  x &\\mapsto x ^ 2
\\end\{aligned}
$$

**Robo**: PS, `↦` ist `\\mapsto`. Aber man kann auch stattdessen `=>` benützen.
"

HiddenHint : ∃ f : ℕ → ℤ, ∀ x, f x < x =>
"
**Du**: Ja aber was mach ich damit?

**Robo**: Wie immer gehst du ein `∃` mit `use …` an.
"

-- TODO: Why does this not show?
HiddenHint : ∀ (x : ℤ), (fun (y : ℤ) => y - 1) x < x =>
"**Du**: Zu was sich das wohl vereinfacht?"

HiddenHint (x : ℤ) : (fun y => y - 1) x < x =>
"**Du**: Zu was sich das wohl vereinfacht?"

Conclusion "Das Mädchen wird kurz ruhig, dann beginnt es zu lächeln und zeigt strahlend
in eine Richtung. Ihr folgt ihrem Finger und euch fällt in weiter ferne eine pompöse Struktur
auf einem flachen Hügel auf.
"
