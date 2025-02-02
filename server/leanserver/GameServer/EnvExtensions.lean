import Lean
import GameServer.Graph
import GameServer.AbstractCtx

/-! # Environment extensions

The game framework stores almost all its game building data in environment extensions
defined in this file.
-/


open Lean

/-! ## Hints -/

/--
A hint to help the user with a specific goal state
-/
structure GoalHintEntry where
  goal : AbstractCtxResult
  /-- Text of the hint as an expression of type `Array Expr → MessageData` -/
  text : Expr
  /--  If true, then hint should be hidden and only be shown on player's request -/
  hidden : Bool := false
  /--  If true, then the goal must contain only the assumptions specified in `goal` and no others -/
  strict : Bool := false

instance : Repr GoalHintEntry := {
  reprPrec := fun a n => reprPrec a.text n
}

/-! ## Tactic/Definition/Lemma documentation -/

inductive InventoryType := | Tactic | Lemma | Definition
deriving ToJson, FromJson, Repr, BEq, Hashable, Inhabited

instance : ToString InventoryType := ⟨fun t => match t with
| .Tactic => "Tactic"
| .Lemma => "Lemma"
| .Definition => "Definition"
⟩

structure InventoryDocEntry where
  name : Name
  type : InventoryType
  displayName : String
  category : String
  content : String
  deriving ToJson, Repr, Inhabited

/-- Environment extension for inventory documentation. -/
initialize inventoryDocExt : SimplePersistentEnvExtension InventoryDocEntry (Array InventoryDocEntry) ←
  registerSimplePersistentEnvExtension {
    name := `inventory_doc
    addEntryFn := Array.push
    addImportedFn := Array.concatMap id
  }

def getInventoryDoc? {m : Type → Type} [Monad m] [MonadEnv m] (n : Name) (type : InventoryType) :
    m (Option InventoryDocEntry) := do
  return (inventoryDocExt.getState (← getEnv)).find? (fun x => x.name == n && x.type == type)

open Elab Command in
/-- Print a registered tactic doc for debugging purposes. -/
elab "#print_doc" : command => do
  for entry in inventoryDocExt.getState (← getEnv) do
    dbg_trace "[{entry.type}] {entry.name} : {entry.content}"


/-! ## Environment extensions for game specification-/

/-- Register a (non-persistent) environment extension to hold the current level -/
initialize curGameExt : EnvExtension (Option Name) ← registerEnvExtension (pure none)
/-- Register a (non-persistent) environment extension to hold the current level -/
initialize curWorldExt : EnvExtension (Option Name) ← registerEnvExtension (pure none)
/-- Register a (non-persistent) environment extension to hold the current level -/
initialize curLevelExt : EnvExtension (Option Nat) ← registerEnvExtension (pure none)

inductive Layer :=
| Game | World | Level

variable {m: Type → Type} [Monad m] [MonadEnv m]

def setCurGameId (game : Name) : m Unit :=
  modifyEnv (curGameExt.setState · (some game))

def setCurWorldId (world : Name) : m Unit :=
  modifyEnv (curWorldExt.setState · (some world))

def setCurLevelIdx (level : Nat) : m Unit :=
  modifyEnv (curLevelExt.setState · (some level))

def getCurLayer [MonadError m] : m Layer := do
  match curGameExt.getState (← getEnv), curWorldExt.getState (← getEnv), curLevelExt.getState (← getEnv) with
  | some _, some _, some _ => return Layer.Level
  | some _, some _, none => return Layer.World
  | some _, none, none => return Layer.Game
  | _, _, _ => throwError "Invalid Layer"

def getCurGameId [MonadError m] : m Name := do
  match curGameExt.getState (← getEnv) with
  | some game => return game
  | none => throwError "Current game not set"

def getCurWorldId [MonadError m] : m Name := do
  match curWorldExt.getState (← getEnv) with
  | some world => return world
  | none => throwError "Current world not set"

def getCurLevelIdx [MonadError m] : m Nat := do
  match curLevelExt.getState (← getEnv) with
  | some level => return level
  | none => throwError "Current level not set"

/-! ## Levels -/

structure LevelId where
  game : Name
  world : Name
  level : Nat
deriving Inhabited

structure ComputedInventoryItem where
  name : Name
  displayName : String
  category : String
  locked : Bool
  disabled : Bool
deriving ToJson, FromJson, Repr, Inhabited

structure InventoryInfo where
  -- new inventory items introduced by this level:
  new : Array Name
  -- inventory items exceptionally forbidden in this level:
  disabled : Array Name
  -- only these inventory items are allowed in this level (ignored if empty):
  only : Array Name
  -- inventory items in this level (computed by `MakeGame`):
  computed : Array ComputedInventoryItem
deriving ToJson, FromJson, Repr, Inhabited

def getCurLevelId [MonadError m] : m LevelId := do
  return { game := ← getCurGameId, world := ← getCurWorldId, level := ← getCurLevelIdx}

/-- Instance to make GameLevel Repr work -/
instance : Repr Elab.Command.Scope := ⟨fun s _ => repr s.currNamespace⟩

structure GameLevel where
  index: Nat
  title: String := default
  /-- introduction: Theory block shown all the time -/
  introduction: String := default
  /-- The mathematical statemtent in mathematician-readable form -/
  description: String := default
  /-- conclusion displayed when level is completed. -/
  conclusion: String := default
  tactics: InventoryInfo := default
  definitions: InventoryInfo := default
  lemmas: InventoryInfo := default
  lemmaTab: Option String := none
  hints: Array GoalHintEntry := default
  /-- The statement in Lean. -/
  goal : TSyntax `Lean.Parser.Command.declSig := default
  scope : Elab.Command.Scope := default
  descrText: String := default
  descrFormat : String := default
  -- The module to be imported when playing this level:
  module : Name := default
  deriving Inhabited, Repr

/-! ## World -/

structure World where
  name: Name
  title: String := ""
  introduction: String := ""
  conclusion : String := ""
  levels: HashMap Nat GameLevel := {}
deriving Inhabited

instance : ToJson World := ⟨
  fun world => Json.mkObj [
    ("name", toJson world.name),
    ("title", world.title),
    ("introduction", world.introduction)]
⟩

/-! ## Game -/

structure Game where
  name : Name
  title : String := ""
  introduction : String := ""
  conclusion : String := ""
  authors : List String := []
  worlds : Graph Name World := {}
deriving Inhabited, ToJson

/-! ## Game environment extension -/

def HashMap.merge [BEq α] [Hashable α] (old : HashMap α β) (new : HashMap α β) (merge : β → β → β) :
  HashMap α β :=
new.fold (fun acc a b =>
  if let some bOld := acc.find? a
  then acc.insert a (merge bOld b)
  else acc.insert a b) old

def GameLevel.merge (old : GameLevel) (new : GameLevel) : GameLevel :=
  new -- simply override old level

def World.merge (old : World) (new : World) : World :=
{ new with
  levels := HashMap.merge old.levels new.levels GameLevel.merge}

def Game.merge (old : Game) (new : Game) : Game :=
{ new with
  worlds := {
    nodes := HashMap.merge old.worlds.nodes new.worlds.nodes World.merge
    edges := Id.run do
      let mut res := old.worlds.edges
      for e in new.worlds.edges do
        if ¬ res.contains e then
          res := res.push e
      return res
  } }

initialize gameExt : PersistentEnvExtension (Name × Game) (Name × Game) (HashMap Name Game) ←
  do registerPersistentEnvExtension {
    name          := `gameExt,
    mkInitial     := pure {},
    addImportedFn := fun ess => do
      let mut games := {}
      for es in ess do
        for (name, game) in es do
          match games.find? name with
          | some oldgame =>
            games := games.insert name (Game.merge oldgame game)
          | none =>
            games := games.insert name game
      return games
    addEntryFn    := (λ s n => s.insert n.1 n.2),
    exportEntriesFn := HashMap.toArray,
    statsFn := fun s => format "number of local entries: " ++ format s.size
}

def getGame? (n : Name) : m (Option Game) := do
  return (gameExt.getState (← getEnv)).find? n

def insertGame (n : Name) (g : Game) : m Unit := do
  modifyEnv (gameExt.addEntry · (n, g))

def getLevel? (levelId : LevelId) : m (Option GameLevel) := do
  let some game ← getGame? levelId.game
    | return none
  let some world := game.worlds.nodes.find? levelId.world
    | return none
  let some level := world.levels.find? levelId.level
    | return none
  return level

def getCurGame [MonadError m] : m Game := do
  let some game ← getGame? (← getCurGameId)
    | throwError m!"Game {← getCurGameId} does not exist"
  return game

def modifyCurGame (fn : Game → m Game) [MonadError m] : m Unit := do
  let game ← getCurGame
  insertGame game.name (← fn game)

def addWorld (world : World) [MonadError m] : m Unit := do
  modifyCurGame fun game => do
    return {game with worlds := game.worlds.insertNode world.name world}

def getCurWorld [MonadError m] : m World := do
  let some world := (← getCurGame).worlds.nodes.find? (← getCurWorldId)
    | throwError m!"World {← getCurWorldId} does not exist"
  return world

def modifyCurWorld (fn : World → m World) [MonadError m] : m Unit := do
  modifyCurGame fun game => do
    let world ← getCurWorld
    return {game with worlds := {game.worlds with nodes := game.worlds.nodes.insert world.name (← fn world) }}

def addLevel (level : GameLevel) [MonadError m] : m Unit := do
  modifyCurWorld fun world => do
    return {world with levels := world.levels.insert level.index level}

def getCurLevel [MonadError m] : m GameLevel := do
  let some level := (← getCurWorld).levels.find? (← getCurLevelIdx)
    | throwError m!"Level {← getCurLevelIdx} does not exist"
  return level

def modifyCurLevel (fn : GameLevel → m GameLevel) [MonadError m] : m Unit := do
  modifyCurWorld fun world => do
    let level ← getCurLevel
    return {world with levels := world.levels.insert level.index (← fn level)}

def modifyLevel (levelId : LevelId) (fn : GameLevel → m GameLevel) [MonadError m] : m Unit := do
  let some game ← getGame? levelId.game
    | throwError m!"Game {levelId.game} does not exist"
  let some world := (← getCurGame).worlds.nodes.find? levelId.world
    | throwError m!"World {levelId.world} does not exist"
  let some level := world.levels.find? levelId.level
    | throwError m!"Level {levelId.level} does not exist"
  let level' ← fn level
  let world' := {world with levels := world.levels.insert levelId.level level'}
  let game' := {game with worlds := game.worlds.insertNode levelId.world world'}
  insertGame levelId.game game'
