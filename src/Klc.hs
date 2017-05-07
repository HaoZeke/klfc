{-# LANGUAGE UnicodeSyntax, NoImplicitPrelude #-}
{-# LANGUAGE FlexibleContexts #-}

module Klc
    ( KlcConfig(..)
    , printKlcData
    , toKlcData
    ) where

import BasePrelude
import Prelude.Unicode
import Data.Monoid.Unicode ((⊕))
import Util (HumanReadable(..), ifNonEmpty, concatMapM, tellMaybeT, privateChars, getPrivateChar)

import Control.Monad.Reader (MonadReader, asks)
import Control.Monad.State (MonadState, evalStateT)
import Control.Monad.Trans (lift)
import Control.Monad.Trans.Maybe (MaybeT(..))
import Control.Monad.Writer (WriterT, runWriter, execWriterT, tell)
import Lens.Micro.Platform (view, over)

import Layout.DeadKey (deadKeyToChainedDeadKey)
import Layout.Key (letterToDeadKey, letterToLigatureString, setDeadNullChar, filterKeyOnShiftstatesM)
import Layout.Layout (addDefaultKeys, unifyShiftstates)
import qualified Layout.Pos as P
import Layout.Types
import Lookup.Windows
import PresetDeadKey (presetDeadKeyToDeadKey)
import PresetLayout (defaultKeys)

data KlcConfig = KlcConfig
    { __chainedDeads ∷ Bool
    }

prepareLayout ∷ (Logger m, MonadState [Char] m) ⇒ Layout → m Layout
prepareLayout =
    addDefaultKeys defaultKeys >>>
    _singletonKeys
        emptySingletonKeys >=>
    _keys
        (over (traverse ∘ _shiftlevels ∘ traverse ∘ traverse) altGrToControlAlt >>>
        traverse (filterKeyOnShiftstatesM supportedShiftstate) >=>
        over (traverse ∘ _letters ∘ traverse) deadToCustomDead >>>
        (traverse ∘ _letters ∘ traverse) setDeadNullChar)

emptySingletonKeys ∷ Logger m ⇒ [SingletonKey] → m [SingletonKey]
emptySingletonKeys [] = pure []
emptySingletonKeys xs = xs <$ tell ["singleton keys are not supported in KLC"]

deadToCustomDead ∷ Letter → Letter
deadToCustomDead (Dead d) = CustomDead Nothing (presetDeadKeyToDeadKey d)
deadToCustomDead l = l

supportedShiftstate ∷ Logger m ⇒ Shiftstate → m Bool
supportedShiftstate = fmap and ∘ traverse supportedModifier ∘ toList

supportedModifier ∷ Logger m ⇒ Modifier → m Bool
supportedModifier modifier
  | modifier ∈ map fst modifierAndWinShiftstate = pure True
  | otherwise = False <$ tell [show' modifier ⊕ " is not supported in KLC"]


-- KLC DATA

data KlcKey = KlcKey
    { __klcPos ∷ String
    , __klcShortcutPos ∷ String
    , __klcCapslock ∷ Bool
    , __klcLetters ∷ [String]
    , __klcComment ∷ String
    } deriving (Show, Read)
printKlcKey ∷ KlcKey → String
printKlcKey (KlcKey pos shortcutPos caps letters comment) = intercalate "\t" $
    [ pos
    , shortcutPos
    , show (fromEnum caps)
    ] ⧺ dropWhileEnd (≡ "-1") letters
    ⧺ [ifNonEmpty ("// " ⊕) comment]

printKlcKeys ∷ [KlcKey] → [String]
printKlcKeys = map printKlcKey

data KlcLigature = KlcLigature
    { __ligPos ∷ String
    , __ligShiftstate ∷ Int
    , __ligString ∷ String
    } deriving (Show, Read)
printKlcLigature ∷ KlcLigature → String
printKlcLigature (KlcLigature pos shiftstate s) = intercalate "\t" $
    [ pos
    , show shiftstate
    ] ⧺ map (printf "%04x") s
    ⧺ [ifNonEmpty ("// " ⊕) s]

printKlcLigatures ∷ [KlcLigature] → [String]
printKlcLigatures [] = []
printKlcLigatures xs = "" : "LIGATURE" : "" : map printKlcLigature xs

data ResultChar = Normal Char | DeadChar String Char deriving (Show, Read)
resultCharToString ∷ ResultChar → String
resultCharToString (Normal c) = [c]
resultCharToString (DeadChar name _) = name
data KlcDeadKey = KlcDeadKey
    { __klcDeadName ∷ String
    , __klcBaseChar ∷ Char
    , __klcCharMap ∷ [(Char, ResultChar)]
    } deriving (Show, Read)
printKlcDeadKey ∷ KlcDeadKey → [String]
printKlcDeadKey (KlcDeadKey name baseChar charMap) =
    "" :
    ("DEADKEY " ⊕ printf "%04x" baseChar ⊕ "\t// " ⊕ name) :
    "" :
    map (uncurry showPair) charMap
  where
    showPair k v = intercalate "\t" [printf "%04x" k, showResultChar v, "// " ⊕ [k] ⊕ " → " ⊕ resultCharToString v]
    showResultChar (Normal c) = printf "%04x" c
    showResultChar (DeadChar _ c) = printf "%04x@" c

printKlcDeadKeys ∷ [KlcDeadKey] → [String]
printKlcDeadKeys = concatMap printKlcDeadKey

data KlcData = KlcData
    { __klcInformation ∷ Information
    , __klcShiftstates ∷ [WinShiftstate]
    , __klcKeys ∷ [KlcKey]
    , __klcLigatures ∷ [KlcLigature]
    , __klcDeadKeys ∷ [KlcDeadKey]
    } deriving (Show, Read)
printKlcData ∷ KlcData → String
printKlcData (KlcData info winShiftstates keys ligatures deadKeys) = unlines $
    [ "KBD\t" ⊕ view _name info ⊕ "\t" ⊕ show (view _fullName info) ] ⧺
    [ "\nCOPYRIGHT\t" ⊕ show copyright | copyright ← maybeToList $ view _copyright info ] ⧺
    [ "\nCOMPANY\t"   ⊕ show company   | company   ← maybeToList $ view _company   info ] ⧺
    [ "\nLOCALEID\t"  ⊕ show localeId  | localeId  ← maybeToList $ view _localeId  info ] ⧺
    [ "\nVERSION\t"   ⊕ version        | version   ← maybeToList $ view _version   info ] ⧺
    [ ""
    , "SHIFTSTATE"
    , ""
    ] ⧺ map show winShiftstates ⧺
    [ ""
    , "LAYOUT"
    , ""
    ] ⧺ printKlcKeys keys
    ⧺ printKlcLigatures ligatures
    ⧺ printKlcDeadKeys deadKeys ⧺
    [ ""
    , ""
    , "ENDKBD"
    ]


-- TO KLC DATA

toKlcData ∷ (Logger m, MonadReader KlcConfig m)
          ⇒ Layout → m KlcData
toKlcData = flip evalStateT privateChars <<<
    prepareLayout >=>
    toKlcData'

toKlcData' ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
           ⇒ Layout → m KlcData
toKlcData' layout =
    KlcData
      <$> pure (view _info layout)
      <*> pure (map winShiftstateFromShiftstate states)
      <*> (catMaybes <$> traverse toKlcKey keys)
      <*> toKlcLigatures states layout
      <*> toKlcDeadKeys keys
  where
    (keys, states) = unifyShiftstates (view _keys layout)

toKlcKey ∷ Logger m ⇒ Key → m (Maybe KlcKey)
toKlcKey key = runMaybeT $
    KlcKey
      <$> printPos (view _pos key)
      <*> printShortcutPos (view _shortcutPos key)
      <*> pure (view _capslock key)
      <*> lift (traverse printLetter (view _letters key))
      <*> pure comment
  where
    comment = "QWERTY " ⊕ toString (view _pos key) ⊕ ifNonEmpty (": " ⊕) (intercalate ", " letterComments)
    letterComments = map toString (dropWhileEnd unsupported (view _letters key))
    unsupported = (≡) "-1" ∘ fst ∘ runWriter ∘ printLetter

printPos ∷ Logger m ⇒ Pos → MaybeT m String
printPos pos
  | not isSupportedKlcPos = e
  | otherwise = maybe e pure $ printf "%02x" <$> lookup pos posAndScancode
  where
    e = tellMaybeT [show' pos ⊕ " is not supported in KLC"]
    isSupportedKlcPos = pos ∈
        [P.Tilde .. P.Plus] ⧺
        [P.Q .. P.Bracket_R] ⧺
        [P.A .. P.Apastrophe] ⧺
        [P.Z .. P.Slash] ⧺
        [P.Backslash, P.Iso, P.Space, P.KP_Dec]

printShortcutPos ∷ Logger m ⇒ Pos → MaybeT m String
printShortcutPos pos = maybe e pure $ lookup pos posAndVkString
  where e = tellMaybeT [show' pos ⊕ " is not supported in KLC"]

printLetter ∷ Logger m ⇒ Letter → m String
printLetter (Char c)
    | isAscii c ∧ isAlphaNum c = pure [c]
    | otherwise = pure (printf "%04x" c)
printLetter (Ligature _ _) = pure "%%"
printLetter (Dead d) = printLetter (CustomDead Nothing (presetDeadKeyToDeadKey d))
printLetter (CustomDead _ (DeadKey _ (Just c) _)) = (⧺"@") <$> printLetter (Char c)
printLetter l@(CustomDead _ (DeadKey _ Nothing _ )) = "-1" <$ tell [show' l ⊕ " has no base character in KLC"]
printLetter LNothing = pure "-1"
printLetter l = "-1" <$ tell [show' l ⊕ " is not supported in KLC"]

toKlcLigatures ∷ Logger m ⇒ [Shiftstate] → Layout → m [KlcLigature]
toKlcLigatures shiftstates = concatMapM (toKlcLigature shiftstates) ∘ view _keys

toKlcLigature ∷ Logger m ⇒ [Shiftstate] → Key → m [KlcLigature]
toKlcLigature shiftstates key = fmap catMaybes ∘ sequence $ do
    (shiftstate, letter) ← shiftstates `zip` view _letters key
    maybeToList $ toLigature pos (winShiftstateFromShiftstate shiftstate) <$> letterToLigatureString letter
  where
    pos = view _pos key

toLigature ∷ Logger m ⇒ Pos → Int → String → m (Maybe KlcLigature)
toLigature pos shiftState s = runMaybeT $
    KlcLigature
      <$> printShortcutPos pos
      <*> pure shiftState
      <*> pure s

toKlcDeadKeys ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
              ⇒ [Key] → m [KlcDeadKey]
toKlcDeadKeys =
    concatMap (nub ∘ mapMaybe letterToDeadKey ∘ view _letters) >>>
    concatMapM (chainedDeadKeyToKlcDeadKeys <=< deadKeyToChainedDeadKey)

chainedDeadKeyToKlcDeadKeys ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
                            ⇒ ChainedDeadKey → m [KlcDeadKey]
chainedDeadKeyToKlcDeadKeys = execWriterT ∘ chainedDeadKeyToKlcDeadKeys'

chainedDeadKeyToKlcDeadKeys' ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
                             ⇒ ChainedDeadKey → WriterT [KlcDeadKey] m Char
chainedDeadKeyToKlcDeadKeys' (ChainedDeadKey name baseChar actionMap) = do
    c ← maybe getPrivateChar pure baseChar
    charMap ← catMaybes <$> traverse (printAction name) actionMap
    c <$ tell [KlcDeadKey name c charMap]

printAction ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
            ⇒ String → (Char, ActionResult) → WriterT [KlcDeadKey] m (Maybe (Char, ResultChar))
printAction name (c, result) = do
    output ← printActionResult name result
    pure $ (,) c <$> output

printActionResult ∷ (Logger m, MonadState [Char] m, MonadReader KlcConfig m)
                  ⇒ String → ActionResult → WriterT [KlcDeadKey] m (Maybe ResultChar)
printActionResult _ (OutString [x]) = pure (Just (Normal x))
printActionResult name (OutString "") =
    Nothing <$ lift (tell ["unsupported empty output string in dead key ‘" ⊕ name ⊕ "’ in KLC"])
printActionResult name (OutString xs) =
    Nothing <$ lift (tell ["too large output string ‘" ⊕ xs ⊕ "’ in dead key ‘" ⊕ name ⊕ "’ in KLC"])
printActionResult name (Next cdk) = do
    chainedDeads ← asks __chainedDeads
    case chainedDeads of
      True → Just ∘ DeadChar (__cdkName cdk) <$> chainedDeadKeyToKlcDeadKeys' cdk
      False → Nothing <$ (lift ∘ tell)
          [ "chained dead keys are not enabled by default in KLC. " ⧺
            "Use --klc-chained-deads to enable it. " ⧺
            "This requires alternative compilation, see <http://archives.miloush.net/michkap/archive/2011/04/16/10154700.html>."
          , "chained dead key ‘" ⊕ name ⊕ "’ is not enabled in KLC"
          ]
