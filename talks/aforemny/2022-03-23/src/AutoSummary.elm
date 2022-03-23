module AutoSummary exposing (..)

import AutoSummary.Form as Form exposing (Form)
import AutoSummary.Form.View as View
import Browser
import Html exposing (Html, text)


type alias Model =
    View.Model String


type Msg
    = FormSubmitted
    | FormChanged (View.Model String)


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
    ( View.idle ""
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FormChanged newForm ->
            ( newForm, Cmd.none )

        FormSubmitted ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    View.asHtml
        { action = "Go"
        , loading = "Loading..."
        , onChange = FormChanged
        , validation = View.ValidateOnBlur
        }
        form
        model


form : Form String Msg
form =
    let
        myForm =
            Form.textField
                { attributes =
                    { label = "My text field"
                    , placeholder = ""
                    }
                , error = always Nothing
                , parser = Ok
                , update = \input -> always input
                , value = identity >> Debug.log "value"
                }
    in
    Form.succeed (\_ _ -> FormSubmitted)
        |> Form.append myForm
        |> Form.append (Form.summary myForm)
