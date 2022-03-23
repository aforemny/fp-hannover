module LoginForm exposing (..)

import Browser
import Email exposing (EmailAddress)
import Form exposing (Form)
import Form.Error as Error exposing (Error)
import Form.View
import Html exposing (Html, text)
import Html.Attributes
import Html.Events
import Json.Decode


type alias Model =
    { form : Form.View.Model Values
    }


type Msg
    = FormChanged (Form.View.Model Values)
    | FormCancelled
    | FormSubmitted Output


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { form = Form.View.idle initialValues }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FormChanged newForm ->
            ( { model | form = newForm }, Cmd.none )

        FormCancelled ->
            let
                _ =
                    Debug.log "cancelled" ()
            in
            ( model, Cmd.none )

        FormSubmitted output ->
            let
                _ =
                    Debug.log "output" output
            in
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div [ Html.Attributes.style "padding" "10px" ]
        [ Html.node "link"
            [ Html.Attributes.rel "stylesheet"
            , Html.Attributes.href "https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css"
            ]
            []
        , asHtml
            { onChange = FormChanged
            , onBack = FormCancelled
            , back = "Cancel"
            , action = "Send"
            , loading = "Loading..."
            , validation = Form.View.ValidateOnBlur
            }
            (form
                |> Form.map FormSubmitted
            )
            model.form
        ]


asHtml config =
    Form.View.custom
        (htmlViewConfig { back = config.back, onBack = config.onBack })
        { onChange = config.onChange
        , action = config.action
        , loading = config.loading
        , validation = config.validation
        }


htmlViewConfig :
    { onBack : msg
    , back : String
    }
    -> Form.View.CustomConfig msg (Html msg)
htmlViewConfig { onBack, back } =
    Form.View.htmlViewConfig
        |> (\config ->
                { config
                    | emailField = viewInputField "email"
                    , passwordField = viewInputField "password"
                    , form =
                        viewForm
                            { back = back
                            , onBack = onBack
                            }
                }
           )


viewForm :
    { onBack : msg
    , back : String
    }
    -> Form.View.FormConfig msg (Html msg)
    -> Html msg
viewForm { onBack, back } config =
    Html.form
        (config.onSubmit
            |> Maybe.map (Html.Events.onSubmit >> List.singleton)
            |> Maybe.withDefault []
        )
        (List.concat
            [ config.fields
            , [ case config.state of
                    Form.View.Error error ->
                        Html.text error

                    Form.View.Success success ->
                        Html.text success

                    _ ->
                        Html.text ""
              , Html.div [ Html.Attributes.class "buttons" ]
                    [ Html.button [ Html.Attributes.class "button is-primary" ]
                        [ if config.state == Form.View.Loading then
                            Html.text config.loading

                          else
                            Html.text config.action
                        ]
                    , Html.button
                        [ Html.Attributes.class "button is-secondary"
                        , Html.Events.preventDefaultOn "click" (Json.Decode.succeed ( onBack, True ))
                        ]
                        [ Html.text back
                        ]
                    ]
              ]
            ]
        )


viewInputField : String -> Form.View.TextFieldConfig msg -> Html msg
viewInputField type_ config =
    Html.div [ Html.Attributes.class "control" ]
        [ Html.label []
            [ Html.div [] [ text config.attributes.label ]
            , Html.input
                ([ Html.Attributes.class "input"
                 , Html.Events.onInput config.onChange
                 , Html.Attributes.disabled config.disabled
                 , Html.Attributes.value config.value
                 , Html.Attributes.placeholder config.attributes.placeholder
                 , Html.Attributes.type_ type_
                 ]
                    ++ List.filterMap identity
                        [ Maybe.map Html.Events.onBlur config.onBlur
                        ]
                )
                []
            ]
        , Html.div []
            [ text
                (case ( config.showError, config.error ) of
                    ( True, Just error ) ->
                        errorToString error

                    _ ->
                        ""
                )
            ]
        ]


type alias Values =
    { email : String
    , password : String
    , rememberMe : Bool
    }


initialValues : Values
initialValues =
    { email = ""
    , password = ""
    , rememberMe = False
    }


type alias Output =
    { email : EmailAddress
    , password : String
    , rememberMe : Bool
    }


form : Form Values Output
form =
    let
        emailField_ : Form Values EmailAddress
        emailField_ =
            emailField
                |> Form.mapValues
                    { value = \values -> values.email
                    , update = \email values -> { values | email = email }
                    }

        passwordField : Form Values String
        passwordField =
            Form.passwordField
                { parser = Ok
                , value = .password
                , update = \password values -> { values | password = password }
                , error =
                    \values ->
                        if String.length values.password < 8 then
                            Just "Password too short"

                        else
                            Nothing
                , attributes =
                    { label = "Password"
                    , placeholder = ""
                    }
                }

        rememberMeCheckbox : Form Values Bool
        rememberMeCheckbox =
            Form.checkboxField
                { parser = Ok
                , value = .rememberMe
                , update = \rememberMe values -> { values | rememberMe = rememberMe }
                , error = always Nothing
                , attributes =
                    { label = "Remember me"
                    }
                }
    in
    (Form.succeed Output
        |> Form.append emailField_
        |> Form.append passwordField
        |> Form.append rememberMeCheckbox
    )
        |> Form.section "Section title"


emailField : Form String EmailAddress
emailField =
    Form.emailField
        { parser = Email.parse >> Result.mapError (\_ -> "Email address invalid")
        , value = identity
        , update = \email _ -> email
        , error = always Nothing
        , attributes =
            { label = "Email"
            , placeholder = "a@b.c"
            }
        }


errorToString : Error -> String
errorToString error =
    case error of
        Error.RequiredFieldIsEmpty ->
            "this field is required"

        Error.ValidationFailed errorDescription ->
            errorDescription

        Error.External s ->
            s
