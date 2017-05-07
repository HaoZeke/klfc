{-# LANGUAGE UnicodeSyntax, NoImplicitPrelude #-}

module Lookup.Windows
    ( WinShiftstate
    , modifierAndWinShiftstate
    , winShiftstateFromShiftstate
    , shiftstateFromWinShiftstate
    , isAltRToAltGr
    , altGrToControlAlt
    , altGrToLControlRAlt
    , posAndScancode
    , posAndVkString
    , posAndVkInt
    , modifierAndString
    , PklAction(..)
    , actionAndPklAction
    , modifierAndPklAction
    ) where

import BasePrelude
import Prelude.Unicode hiding ((∈))
import Data.Foldable.Unicode ((∈))
import qualified Data.Set.Unicode as S
import Util (lookupR, dec2bin)
import WithPlus (WithPlus(..))
import qualified WithPlus as WP (fromList)

import qualified Data.Set as S

import qualified Layout.Action as A
import qualified Layout.Modifier as M
import qualified Layout.Pos as P
import Layout.Types
import qualified Lookup.Linux as LL (posAndScancode)

type WinShiftstate = Int
modifierAndWinShiftstate ∷ [(Modifier, WinShiftstate)]
modifierAndWinShiftstate =
    [ (M.Shift, 1)
    , (M.Control, 2)
    , (M.Alt, 4)
    ]

winShiftstateFromShiftstate ∷ Shiftstate → WinShiftstate
winShiftstateFromShiftstate = sum ∘ mapMaybe (`lookup` modifierAndWinShiftstate) ∘ toList

shiftstateFromWinShiftstate ∷ WinShiftstate → Shiftstate
shiftstateFromWinShiftstate = WP.fromList ∘ catMaybes ∘ zipWith toModifier (iterate (⋅2) 1) ∘ dec2bin
    where toModifier _ 0 = Nothing
          toModifier n _ = lookupR n modifierAndWinShiftstate

isAltRToAltGr ∷ SingletonKey → Bool
isAltRToAltGr (SingletonKey P.Alt_R (Modifiers Shift [M.AltGr])) = True
isAltRToAltGr _ = False

altGrToControlAlt ∷ Shiftstate → Shiftstate
altGrToControlAlt xs@(WithPlus s)
  | M.AltGr ∈ xs = WithPlus (S.delete M.AltGr s S.∪ S.fromList [M.Control, M.Alt])
  | otherwise    = xs

altGrToLControlRAlt ∷ Shiftstate → Shiftstate
altGrToLControlRAlt xs@(WithPlus s)
  | M.AltGr ∈ xs = WithPlus (S.delete M.AltGr s S.∪ S.fromList [M.Control_L, M.Alt_R])
  | otherwise    = xs

posAndScancode ∷ [(Pos, Int)]
posAndScancode =
    [ (P.Win_L, 0x15B)
    , (P.Alt_R, 0x138)
    , (P.Win_R, 0x15C)
    , (P.Menu, 0x15D)
    , (P.Control_R, 0x11D)
    , (P.Insert, 0x152)
    , (P.Delete, 0x153)
    , (P.Home, 0x147)
    , (P.End, 0x14F)
    , (P.PageUp, 0x149)
    , (P.PageDown, 0x151)
    , (P.Up, 0x148)
    , (P.Left, 0x14B)
    , (P.Down, 0x150)
    , (P.Right, 0x14D)
    , (P.KP_Enter, 0x11C)

    , (P.Power, 0x15E)
    , (P.Sleep, 0x15F)
    , (P.Wake, 0x163)
    , (P.Mute, 0x120)
    , (P.VolumeUp, 0x130)
    , (P.VolumeDown, 0x12E)
--    , (P.Cut, 0x117)
--    , (P.Copy, 0x118)
--    , (P.Paste, 0x10A)
    , (P.Help, 0x13B)
--    , (P.Undo, 0x108)
--    , (P.Redo, 0x107)
    , (P.PlayPause, 0x122)
    , (P.Stop, 0x124)
    , (P.Previous, 0x110)
    , (P.Next, 0x119)
    , (P.Eject, 0x12C)
    , (P.Mail, 0x11E)
    , (P.Browser, 0x132)
    ] ⧺ LL.posAndScancode

posAndVkString ∷ [(Pos, String)]
posAndVkString =
    [ (P.Esc, "ESCAPE")
    , (P.F1, "F1")
    , (P.F2, "F2")
    , (P.F3, "F3")
    , (P.F4, "F4")
    , (P.F5, "F5")
    , (P.F6, "F6")
    , (P.F7, "F7")
    , (P.F8, "F8")
    , (P.F9, "F9")
    , (P.F10, "F10")
    , (P.F11, "F11")
    , (P.F12, "F12")
    , (P.PrintScreen, "SNAPSHOT")
    , (P.ScrollLock, "SCROLL")
    , (P.Pause, "PAUSE")

    , (P.Tilde, "OEM_3")
    , (P.N1, "1")
    , (P.N2, "2")
    , (P.N3, "3")
    , (P.N4, "4")
    , (P.N5, "5")
    , (P.N6, "6")
    , (P.N7, "7")
    , (P.N8, "8")
    , (P.N9, "9")
    , (P.N0, "0")
    , (P.Minus, "OEM_MINUS")
    , (P.Plus, "OEM_PLUS")
    , (P.Backspace, "BACK")

    , (P.Tab, "TAB")
    , (P.Q, "Q")
    , (P.W, "W")
    , (P.E, "E")
    , (P.R, "R")
    , (P.T, "T")
    , (P.Y, "Y")
    , (P.U, "U")
    , (P.I, "I")
    , (P.O, "O")
    , (P.P, "P")
    , (P.Bracket_L, "OEM_4")
    , (P.Bracket_R, "OEM_6")
    , (P.Backslash, "OEM_5")

    , (P.CapsLock, "OEM_CAPITAL")
    , (P.A, "A")
    , (P.S, "S")
    , (P.D, "D")
    , (P.F, "F")
    , (P.G, "G")
    , (P.H, "H")
    , (P.J, "J")
    , (P.K, "K")
    , (P.L, "L")
    , (P.Semicolon, "OEM_1")
    , (P.Apastrophe, "OEM_7")
    , (P.Enter, "RETURN")

    , (P.Shift_L, "LSHIFT")
    , (P.Iso, "OEM_102")
    , (P.Z, "Z")
    , (P.X, "X")
    , (P.C, "C")
    , (P.V, "V")
    , (P.B, "B")
    , (P.N, "N")
    , (P.M, "M")
    , (P.Comma, "OEM_COMMA")
    , (P.Period, "OEM_PERIOD")
    , (P.Slash, "OEM_2")
    , (P.Shift_R, "RSHIFT")

    , (P.Control_L, "LCONTROL")
    , (P.Win_L, "LWIN")
    , (P.Alt_L, "LALT")
    , (P.Space, "SPACE")
    , (P.Alt_R, "RAlt")
    , (P.Win_R, "RWIN")
    , (P.Menu, "APPS")
    , (P.Control_R, "RCONTROL")

    , (P.Insert, "INSERT")
    , (P.Delete, "DELETE")
    , (P.Home, "HOME")
    , (P.End, "END")
    , (P.PageUp, "PRIOR")
    , (P.PageDown, "NEXT")
    , (P.Up, "UP")
    , (P.Left, "LEFT")
    , (P.Down, "DOWN")
    , (P.Right, "RIGHT")

    , (P.NumLock, "NUMLOCK")
    , (P.KP_Div, "DIVIDE")
    , (P.KP_Mult, "MULTIPLY")
    , (P.KP_Min, "SUBTRACT")
    , (P.KP_7, "NUMPAD7")
    , (P.KP_8, "NUMPAD8")
    , (P.KP_9, "NUMPAD9")
    , (P.KP_Plus, "ADD")
    , (P.KP_4, "NUMPAD4")
    , (P.KP_5, "NUMPAD5")
    , (P.KP_6, "NUMPAD6")
    , (P.KP_1, "NUMPAD1")
    , (P.KP_2, "NUMPAD2")
    , (P.KP_3, "NUMPAD3")
    , (P.KP_Enter, "RETURN")
    , (P.KP_0, "NUMPAD0")
    , (P.KP_Dec, "DECIMAL")

    , (P.PlayPause, "MEDIA_PLAY_PAUSE")
    , (P.Previous, "MEDIA_PREV_TRACK")
    , (P.Next, "MEDIA_NEXT_TRACK")
    , (P.Stop, "MEDIA_STOP")
    , (P.Mute, "VOLUME_MUTE")
    , (P.VolumeDown, "VOLUME_DOWN")
    , (P.VolumeUp, "VOLUME_UP")

    , (P.Browser_Back, "BROWSER_BACK")
    , (P.Browser_Forward, "BROWSER_FORWARD")
    , (P.Browser_Refresh, "BROWSER_REFRESH")
    , (P.Browser_Stop, "BROWSER_STOP")
    , (P.Browser_Search, "BROWSER_SEARCH")
    , (P.Browser_Favorites, "BROWSER_FAVORITES")

    , (P.Calculator, "LAUNCH_APP2")
    , (P.MediaPlayer, "LAUNCH_MEDIA_SELECT")
    , (P.Browser, "BROWSER_HOME")
    , (P.Mail, "LAUNCH_MAIL")
    , (P.Help, "HELP")
    , (P.Launch1, "LAUNCH_APP1")
    , (P.Launch2, "LAUNCH_APP2")

    , (P.Sleep, "SLEEP")

    , (P.F13, "F13")
    , (P.F14, "F14")
    , (P.F15, "F15")
    , (P.F16, "F16")
    , (P.F17, "F17")
    , (P.F18, "F18")
    , (P.F19, "F19")
    , (P.F20, "F20")
    , (P.F21, "F21")
    , (P.F22, "F22")
    , (P.F23, "F23")
    , (P.F24, "F24")
    ]

posAndVkInt ∷ [(Pos, Int)]
posAndVkInt =
    [ (P.Esc, 0x1B)
    , (P.F1, 0x70)
    , (P.F2, 0x71)
    , (P.F3, 0x72)
    , (P.F4, 0x73)
    , (P.F5, 0x74)
    , (P.F6, 0x75)
    , (P.F7, 0x76)
    , (P.F8, 0x77)
    , (P.F9, 0x78)
    , (P.F10, 0x79)
    , (P.F11, 0x7A)
    , (P.F12, 0x7B)
    , (P.PrintScreen, 0x2C)
    , (P.ScrollLock, 0x91)
    , (P.Pause, 0x13)

    , (P.Tilde, 0xC0)
    , (P.N1, 0x31)
    , (P.N2, 0x32)
    , (P.N3, 0x33)
    , (P.N4, 0x34)
    , (P.N5, 0x35)
    , (P.N6, 0x36)
    , (P.N7, 0x37)
    , (P.N8, 0x38)
    , (P.N9, 0x39)
    , (P.N0, 0x30)
    , (P.Minus, 0xBD)
    , (P.Plus, 0xBB)
    , (P.Backspace, 0x08)

    , (P.Tab, 0x09)
    , (P.Q, 0x51)
    , (P.W, 0x57)
    , (P.E, 0x45)
    , (P.R, 0x52)
    , (P.T, 0x54)
    , (P.Y, 0x59)
    , (P.U, 0x55)
    , (P.I, 0x49)
    , (P.O, 0x4F)
    , (P.P, 0x50)
    , (P.Bracket_L, 0xDB)
    , (P.Bracket_R, 0xDD)
    , (P.Backslash, 0xDC)

    , (P.CapsLock, 0x14)
    , (P.A, 0x41)
    , (P.S, 0x53)
    , (P.D, 0x44)
    , (P.F, 0x46)
    , (P.G, 0x47)
    , (P.H, 0x48)
    , (P.J, 0x4A)
    , (P.K, 0x4B)
    , (P.L, 0x4C)
    , (P.Semicolon, 0xBA)
    , (P.Apastrophe, 0xDE)
    , (P.Enter, 0x0D)

    , (P.Shift_L, 0xA0)
    , (P.Iso, 0xE2)
    , (P.Z, 0x5A)
    , (P.X, 0x58)
    , (P.C, 0x43)
    , (P.V, 0x56)
    , (P.B, 0x42)
    , (P.N, 0x4E)
    , (P.M, 0x4D)
    , (P.Comma, 0xBC)
    , (P.Period, 0xBE)
    , (P.Slash, 0xBF)
    , (P.Shift_R, 0xA1)

    , (P.Control_L, 0xA2)
    , (P.Win_L, 0x5B)
    , (P.Alt_L, 0xA4)
    , (P.Space, 0x20)
    , (P.Alt_R, 0xA5)
    , (P.Win_R, 0x5C)
    , (P.Menu, 0x5D)
    , (P.Control_R, 0xA3)

    , (P.Insert, 0x2D)
    , (P.Delete, 0x2E)
    , (P.Home, 0x24)
    , (P.End, 0x23)
    , (P.PageUp, 0x21)
    , (P.PageDown, 0x22)
    , (P.Up, 0x26)
    , (P.Left, 0x25)
    , (P.Down, 0x28)
    , (P.Right, 0x27)

    , (P.NumLock, 0x90)
    , (P.KP_Div, 0x6F)
    , (P.KP_Mult, 0x6A)
    , (P.KP_Min, 0x6D)
    , (P.KP_7, 0x67)
    , (P.KP_8, 0x68)
    , (P.KP_9, 0x69)
    , (P.KP_Plus, 0x6B)
    , (P.KP_4, 0x64)
    , (P.KP_5, 0x65)
    , (P.KP_6, 0x66)
    , (P.KP_1, 0x61)
    , (P.KP_2, 0x62)
    , (P.KP_3, 0x63)
    , (P.KP_Enter, 0x0D)
    , (P.KP_0, 0x60)
    , (P.KP_Dec, 0x6E)

    , (P.PlayPause, 0xB3)
    , (P.Previous, 0xB1)
    , (P.Next, 0xB0)
    , (P.Stop, 0xB2)
    , (P.Mute, 0xAD)
    , (P.VolumeDown, 0xAE)
    , (P.VolumeUp, 0xAF)

    , (P.Browser_Back, 0xA6)
    , (P.Browser_Forward, 0xA7)
    , (P.Browser_Refresh, 0xA8)
    , (P.Browser_Stop, 0xA9)
    , (P.Browser_Search, 0xAA)
    , (P.Browser_Favorites, 0xAB)

    , (P.Calculator, 0xB7)
    , (P.MediaPlayer, 0xB5)
    , (P.Browser, 0xAC)
    , (P.Mail, 0xB4)
    , (P.Help, 0x2F)
    , (P.Launch1, 0xB6)
    , (P.Launch2, 0xB7)

    , (P.Sleep, 0x5F)

    , (P.F13, 0x7C)
    , (P.F14, 0x7D)
    , (P.F15, 0x7E)
    , (P.F16, 0x7F)
    , (P.F17, 0x80)
    , (P.F18, 0x81)
    , (P.F19, 0x82)
    , (P.F20, 0x83)
    , (P.F21, 0x84)
    , (P.F22, 0x85)
    , (P.F23, 0x86)
    , (P.F24, 0x87)
    ]

modifierAndString ∷ [(Modifier, String)]
modifierAndString =
    [ (M.Shift, "+")
    , (M.Shift_L, "<+")
    , (M.Shift_R, ">+")
    , (M.Control, "^")
    , (M.Control_L, "<^")
    , (M.Control_R, ">^")
    , (M.Alt, "!")
    , (M.Alt_L, "<!")
    , (M.Alt_R, ">!")
    , (M.Win, "#")
    , (M.Win_L, "<#")
    , (M.Win_R, ">#")
    ]

data PklAction
    = Simple String
    | RedirectLetter Letter [Modifier]
    deriving (Eq, Show, Read)

actionAndPklAction ∷ [(Action, PklAction)]
actionAndPklAction =
    [ (A.Esc, Simple "Esc")
    , (A.F1, Simple "F1")
    , (A.F2, Simple "F2")
    , (A.F3, Simple "F3")
    , (A.F4, Simple "F4")
    , (A.F5, Simple "F5")
    , (A.F6, Simple "F6")
    , (A.F7, Simple "F7")
    , (A.F8, Simple "F8")
    , (A.F9, Simple "F9")
    , (A.F10, Simple "F10")
    , (A.F11, Simple "F11")
    , (A.F12, Simple "F12")
    , (A.PrintScreen, Simple "PrintScreen")
--    , (A.SysRq, Simple "")
    , (A.ScrollLock, Simple "ScrollLock")
    , (A.Pause, Simple "Pause")
    , (A.ControlBreak, Simple "CtrlBreak")
    , (A.Insert, Simple "Ins")
    , (A.Delete, Simple "Del")
    , (A.Home, Simple "Home")
    , (A.End, Simple "End")
    , (A.PageUp, Simple "PgUp")
    , (A.PageDown, Simple "PgDn")
    , (A.Up, Simple "Up")
    , (A.Left, Simple "Left")
    , (A.Down, Simple "Down")
    , (A.Right, Simple "Right")
    , (A.Backspace, Simple "BackSpace")
    , (A.Tab, Simple "Tab")
    , (A.Enter, Simple "Enter")
    , (A.Menu, Simple "AppsKey")
    , (A.Power, Simple "Power")
    , (A.Sleep, Simple "Sleep")
    , (A.Wake, Simple "Wake")
    , (A.Undo, RedirectLetter (Char 'z') [M.Control])
    , (A.Redo, RedirectLetter (Char 'z') [M.Shift,M.Control])
    , (A.Cut, RedirectLetter (Char 'x') [M.Control])
    , (A.Copy, RedirectLetter (Char 'c') [M.Control])
    , (A.Paste, RedirectLetter (Char 'v') [M.Control])
    , (A.Save, RedirectLetter (Char 's') [M.Control])
    , (A.CloseTab, RedirectLetter (Char 'w') [M.Control])
    , (A.PlayPause, Simple "Media_Play_Pause")
    , (A.Previous, Simple "Media_Prev")
    , (A.Next, Simple "Media_Next")
    , (A.Stop, Simple "Media_Stop")
    , (A.Mute, Simple "Volume_Mute")
    , (A.VolumeDown, Simple "Volume_Down")
    , (A.VolumeUp, Simple "Volume_Up")
--    , (A.BrightnessDown, Simple "")
--    , (A.BrightnessUp, Simple "")
    , (A.Button_Default, Simple "LBotton")
    , (A.Button_L, Simple "LButton")
    , (A.Button_M, Simple "MButton")
    , (A.Button_R, Simple "RButton")
    , (A.WheelDown, Simple "WheelDown")
    , (A.WheelUp, Simple "WheelUp")
    , (A.WheelLeft, Simple "WheelLeft")
    , (A.WheelRight, Simple "WheelRight")
--    , (A.DoubleClick, Simple "")
    , (A.MouseLeft, Simple "Click Rel -17,0,0")
    , (A.MouseRight, Simple "Click Rel 17,0,0")
    , (A.MouseUp, Simple "Click Rel 0,-17,0")
    , (A.MouseDown, Simple "Click Rel 0,17,0")
    , (A.MouseUpLeft, Simple "Click Rel -17,-17,0")
    , (A.MouseUpRight, Simple "Click Rel 17,-17,0")
    , (A.MouseDownLeft, Simple "Click Rel -17,17,0")
    , (A.MouseDownRight, Simple "Click Rel 17,17,0")

    , (A.Browser_Back, Simple "Browser_Back")
    , (A.Browser_Forward, Simple "Browser_Forward")
    , (A.Browser_Refresh, Simple "Browser_Refresh")
    , (A.Browser_Stop, Simple "Browser_Stop")
    , (A.Browser_Search, Simple "Browser_Search")
    , (A.Browser_Favorites, Simple "Browser_Favorites")

    , (A.Calculator, Simple "Launch_App2")
    , (A.MediaPlayer, Simple "Launch_Media")
    , (A.Browser, Simple "Browser_Home")
    , (A.Mail, Simple "Launch_Mail")
    , (A.MyComputer, Simple "Launch_App1")
    , (A.Launch1, Simple "Launch_App1")
    , (A.Launch2, Simple "Launch_App2")

    , (A.KP_Div, Simple "NumpadDiv")
    , (A.KP_Mult, Simple "NumpadMult")
    , (A.KP_Min, Simple "NumpadSub")
    , (A.KP_7, Simple "Numpad7")
    , (A.KP_8, Simple "Numpad8")
    , (A.KP_9, Simple "Numpad9")
    , (A.KP_Plus, Simple "NumpadAdd")
    , (A.KP_4, Simple "Numpad4")
    , (A.KP_5, Simple "Numpad5")
    , (A.KP_6, Simple "Numpad6")
    , (A.KP_1, Simple "Numpad1")
    , (A.KP_2, Simple "Numpad2")
    , (A.KP_3, Simple "Numpad3")
    , (A.KP_Enter, Simple "NumpadEnter")
    , (A.KP_0, Simple "Numpad0")
    , (A.KP_Dec, Simple "NumpadDot")

    , (A.KP_Home, Simple "NumpadHome")
    , (A.KP_Up, Simple "NumpadUp")
    , (A.KP_PageUp, Simple "NumpadPgUp")
    , (A.KP_Left, Simple "NumpadLeft")
    , (A.KP_Begin, Simple "NumpadClear")
    , (A.KP_Right, Simple "NumpadRight")
    , (A.KP_End, Simple "NumpadEnd")
    , (A.KP_Down, Simple "NumpadDown")
    , (A.KP_PageDown, Simple "NumpadPgDn")
    , (A.KP_Insert, Simple "NumpadIns")
    , (A.KP_Delete, Simple "NumpadDel")
    ]

modifierAndPklAction ∷ [(Modifier, PklAction)]
modifierAndPklAction =
    [ (M.Shift, Simple "Shift")
    , (M.Shift_L, Simple "LShift")
    , (M.Shift_R, Simple "RShift")
    , (M.CapsLock, Simple "CapsLock")
    , (M.Win, Simple "LWin")
    , (M.Win_L, Simple "LWin")
    , (M.Win_R, Simple "RWin")
    , (M.Alt, Simple "Alt")
    , (M.Alt_L, Simple "LAlt")
    , (M.Alt_R, Simple "RAlt")
    , (M.Control, Simple "Ctrl")
    , (M.Control_L, Simple "LCtrl")
    , (M.Control_R, Simple "RCtrl")
    , (M.NumLock, Simple "NumLock")
    ]
