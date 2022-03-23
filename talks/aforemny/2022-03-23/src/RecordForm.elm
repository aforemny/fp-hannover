module RecordForm exposing (..)

import Basics.Extra exposing (curry, uncurry)
import Browser
import Dict exposing (Dict)
import Dict.Extra as Dict
import Form exposing (Form)
import Form.View
import Html exposing (Html, text)
import List.Extra as List


type Record a
    = Record (List ( String, a ))


type Value
    = StringValue String
    | IntValue String
    | RecordValue (Record Value)
    | ListValue Value (List Value)


type Output
    = StringOutput String
    | IntOutput Int
    | RecordOutput (Record Output)
    | ListOutput {- TODO -} Value (List Output)


record : Record Value
record =
    Record
        [ ( "aString", StringValue "" )
        , ( "aInt", IntValue "" )
        , ( "aRecord"
          , RecordValue
                (Record
                    [ ( "aString", StringValue "" )
                    , ( "aInt", IntValue "" )
                    ]
                )
          )
        , ( "aList_String", ListValue (StringValue "") [] )
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { form : Form.View.Model Values
    }


type Msg
    = FormChanged (Form.View.Model Values)
    | FormSubmitted (Record Output)


init _ =
    ( { form = Form.View.idle initialValues
      }
    , Cmd.none
    )


subscriptions _ =
    Sub.none


update msg model =
    case msg of
        FormChanged newForm ->
            let
                _ =
                    Debug.log "values" newForm.values
            in
            ( { model | form = newForm }, Cmd.none )

        FormSubmitted rec ->
            let
                _ =
                    Debug.log "formSubmitted" rec
            in
            ( model, Cmd.none )


view model =
    case Ok record {- Record.parse src -} of
        Ok r ->
            Form.View.asHtml
                { onChange = FormChanged
                , action = "Go"
                , loading = "Loading..."
                , validation = Form.View.ValidateOnBlur
                }
                (recordForm r
                    |> Form.map FormSubmitted
                )
                model.form

        Err s ->
            Html.div []
                [ Html.h1 [] [ text "(ノಠ益ಠ)ノ彡┻━┻" ]
                , Html.p [] [ text s ]
                ]


type alias Values =
    { strings : Dict (List String) String
    }


initialValues : Values
initialValues =
    { strings = Dict.empty
    }


recordForm : Record Value -> Form Values (Record Output)
recordForm =
    recordFormHelper List.singleton


valueForm : (String -> List String) -> ( String, Value ) -> Form Values ( String, Output )
valueForm a kv =
    case kv of
        ( k, StringValue def ) ->
            stringForm (a k)
                |> Form.map (StringOutput >> Tuple.pair k)
                |> Form.mapValues
                    { value = .strings >> Dict.get (a k) >> Maybe.withDefault def
                    , update = \string values -> { values | strings = Dict.insert (a k) string values.strings }
                    }

        ( k, IntValue def ) ->
            intForm (a k)
                |> Form.map (IntOutput >> Tuple.pair k)
                |> Form.mapValues
                    { value = .strings >> Dict.get (a k) >> Maybe.withDefault def
                    , update = \string values -> { values | strings = Dict.insert (a k) string values.strings }
                    }

        ( k, RecordValue r ) ->
            recordFormHelper ((++) (a k) << List.singleton) r
                |> Form.section (String.join "." (a k))
                |> Form.map (RecordOutput >> Tuple.pair k)
                |> Form.mapValues
                    { value =
                        \outerValues ->
                            { strings =
                                outerValues.strings
                                    |> Dict.filterMap
                                        (\ks v ->
                                            if List.isPrefixOf (a k) ks then
                                                Just v

                                            else
                                                Nothing
                                        )
                                    |> Dict.mapKeys (List.drop (List.length (a k)))
                            }
                    , update =
                        \innerValues outerValues ->
                            { outerValues
                                | strings =
                                    Dict.union outerValues.strings
                                        (innerValues.strings |> Dict.mapKeys ((++) (a k)))
                            }
                    }

        ( k, ListValue t def ) ->
            listForm t a k
                |> Form.map (ListOutput t >> Tuple.pair k)
                |> splitValues
                |> focusValues a k


listForm : Value -> (String -> List String) -> String -> Form (List Values) (List Output)
listForm t a k =
    Form.list
        { value = identity
        , update = \values _ -> values
        , default = { initialValues | strings = Dict.singleton [ "0" ] "" }
        , attributes =
            { label = k
            , add = Just "add"
            , delete = Just "delete"
            }
        }
        (\l -> valueForm List.singleton ( String.fromInt l, t ))
        |> Form.map (List.map Tuple.second)


splitValues : Form (List Values) output -> Form Values output
splitValues =
    let
        rekey =
            List.map Tuple.second
                >> List.indexedMap Tuple.pair
                >> List.map (Tuple.mapFirst (String.fromInt >> List.singleton))

        strings x =
            { strings = x }
    in
    Form.mapValues
        { value =
            \outerValues ->
                outerValues.strings
                    |> Dict.toList
                    |> rekey
                    |> List.map (uncurry Dict.singleton)
                    |> List.map strings
        , update =
            \innerValues outerValues ->
                innerValues
                    |> List.map .strings
                    |> List.concatMap Dict.toList
                    |> rekey
                    |> Dict.fromList
                    |> strings
        }


focusValues : (String -> List String) -> String -> Form Values output -> Form Values output
focusValues a k =
    Form.mapValues
        { value =
            \outerValues ->
                { strings =
                    outerValues.strings
                        |> Dict.filterMap
                            (\ks v ->
                                if List.isPrefixOf (a k) ks then
                                    Just v

                                else
                                    Nothing
                            )
                        |> Dict.mapKeys (List.drop (List.length (a k)))
                }
        , update =
            \innerValues outerValues ->
                { outerValues
                    | strings = Dict.union (innerValues.strings |> Dict.mapKeys ((++) (a k))) outerValues.strings
                }
        }


recordFormHelper : (String -> List String) -> Record Value -> Form Values (Record Output)
recordFormHelper a (Record kvs) =
    Form.map Record
        (List.foldr
            (\f fs ->
                Form.succeed (::)
                    |> Form.append f
                    |> Form.append fs
            )
            (Form.succeed [])
            (List.map (valueForm a) kvs)
        )


stringForm : List String -> Form String String
stringForm label =
    Form.textField
        { parser = Ok
        , value = identity
        , update = \input values -> input
        , error = always Nothing
        , attributes =
            { label = String.join "." label ++ " (String)"
            , placeholder = ""
            }
        }


intForm : List String -> Form String Int
intForm label =
    Form.textField
        { parser =
            \input ->
                case String.toInt input of
                    Just int ->
                        Ok int

                    Nothing ->
                        Err "Please enter an integer"
        , value = identity
        , update = \input values -> input
        , error = always Nothing
        , attributes =
            { label = String.join "." label ++ " (Int)"
            , placeholder = ""
            }
        }
