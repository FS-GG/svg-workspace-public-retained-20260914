module SvgWorkspacePublicRetained.Client.Program

open Elmish
open SvgWorkspacePublicRetained.Client.App

Program.mkProgram init update view |> Program.run
