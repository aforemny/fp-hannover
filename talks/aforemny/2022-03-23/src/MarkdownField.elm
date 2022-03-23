module MarkdownField exposing (..)

import Browser
import Html exposing (Html, text)
import MarkdownField.Form as Form exposing (Form)
import MarkdownField.Form.View as View


type alias Model =
    { form : View.Model Values
    }


type Msg
    = FormChanged (View.Model Values)
    | FormSubmitted String


type alias Values =
    String


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
    ( { form = View.idle ""
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FormChanged newForm ->
            ( { model | form = newForm }, Cmd.none )

        FormSubmitted s ->
            let
                _ =
                    Debug.log "s" s
            in
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    View.asHtml
        { onChange = FormChanged
        , action = "Post"
        , loading = "Loading..."
        , validation = View.ValidateOnBlur
        }
        ((Form.succeed
            (\s _ -> s)
            |> Form.append
                (Form.textField
                    { attributes =
                        { label = "My label"
                        , placeholder = "My placeholder"
                        }
                    , error = always Nothing
                    , parser = Ok
                    , update = \input _ -> input
                    , value = identity
                    }
                )
            |> Form.append (Form.markdownField "Hello *world*__!__")
         )
            |> Form.map FormSubmitted
        )
        model.form
