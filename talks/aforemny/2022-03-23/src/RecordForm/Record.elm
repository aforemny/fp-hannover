module RecordForm.Record exposing (Record(..), Type(..), parse)

import Elm.Parser
import Elm.Processing
import Elm.Syntax.Declaration
import Elm.Syntax.Node
import Elm.Syntax.TypeAnnotation
import Html
import Result


type Record
    = Record (List ( String, Type ))


type Type
    = String
    | Int
    | Unknown String


parse : String -> Result String Record
parse input_ =
    let
        input =
            ("""module Main exposing (..)

"""
                ++ String.trim input_
            )
                |> Debug.log "foo"

        unNode (Elm.Syntax.Node.Node _ x) =
            x

        aliasDeclaration declaration =
            case declaration of
                Elm.Syntax.Node.Node _ (Elm.Syntax.Declaration.AliasDeclaration typeAlias) ->
                    Just typeAlias

                _ ->
                    Nothing

        recordDefinition typeAnnotation =
            case typeAnnotation of
                Elm.Syntax.TypeAnnotation.Record recordDef ->
                    Just recordDef

                _ ->
                    Nothing

        typed typeAnnotation =
            case typeAnnotation of
                Elm.Syntax.TypeAnnotation.Typed (Elm.Syntax.Node.Node _ ( [], "String" )) _ ->
                    String

                Elm.Syntax.TypeAnnotation.Typed (Elm.Syntax.Node.Node _ ( [], "Int" )) _ ->
                    Int

                Elm.Syntax.TypeAnnotation.Typed (Elm.Syntax.Node.Node _ ( [], s )) _ ->
                    Unknown s

                _ ->
                    Unknown "..."
    in
    Elm.Parser.parse input
        |> Result.map (Elm.Processing.process Elm.Processing.init)
        |> Result.map .declarations
        |> Result.map (List.filterMap aliasDeclaration)
        |> Result.map (List.map (\typeAlias -> unNode typeAlias.typeAnnotation))
        |> Result.map (List.filterMap recordDefinition)
        |> Result.map (List.map (List.map unNode))
        |> Result.map (List.map (List.map (Tuple.mapFirst unNode)))
        |> Result.map (List.map (List.map (Tuple.mapSecond unNode)))
        |> Result.map (List.map (List.map (Tuple.mapSecond typed)))
        |> Result.map List.head
        |> Result.mapError Debug.toString
        |> Result.andThen
            (\mX ->
                case mX of
                    Nothing ->
                        Err "Nothing"

                    Just x ->
                        Ok x
            )
        |> Result.map Record
