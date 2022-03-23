module MarkdownField.Form exposing
    ( Form
    , textField
    , succeed, append, optional, disable, andThen, meta
    , map, mapValues
    , Field(..), FilledField, fill
    , markdownField
    )

{-| Build [composable forms](#Form) comprised of [fields](#fields).


# Definition

@docs Form


# Fields

@docs textField, emailField, passwordField, textareaField, numberField, rangeField, checkboxField
@docs radioField, selectField


# Composition

All the functions in [the previous section](#fields) produce a `Form` with a **single**
field. You might then be wondering: "How do I create a `Form` with multiple fields?!"
Well, as the name of this package says: `Form` is composable! This section explains how you
can combine different forms into bigger and more complex ones.

@docs succeed, append, optional, disable, group, section, andThen, meta, list


# Mapping

@docs map, mapValues


# Output

This section describes how to fill a `Form` with its `values` and obtain its
different fields and its `output`. This is mostly used to write custom view code.

If you just want to render a simple form as `Html`, check [`Form.View`](Form-View) first as it
might suit your needs.

@docs Field, FilledField, fill

-}

import Form.Base as Base
import Form.Base.CheckboxField as CheckboxField exposing (CheckboxField)
import Form.Base.FormList as FormList exposing (FormList)
import Form.Base.NumberField as NumberField exposing (NumberField)
import Form.Base.RadioField as RadioField exposing (RadioField)
import Form.Base.RangeField as RangeField exposing (RangeField)
import Form.Base.SelectField as SelectField exposing (SelectField)
import Form.Base.TextField as TextField exposing (TextField)
import Form.Error exposing (Error)
import Form.Field as Field



-- Definition


{-| A `Form` collects and validates user input using fields. When a form is filled with `values`,
it produces some `output` if validation succeeds.

For example, a `Form String EmailAddress` is a form that is filled with a `String` and produces
an `EmailAddress` when valid. This form could very well be an [`emailField`](#emailField)!

A `Form` is only the **definition** of your form logic! It only represents the shape of a form! It lives on its own, decoupled from its values, the rendering strategy and view state.

If you like to learn by example, you can check out [this excellent introduction to the package by Alex Korban][korban].

[korban]: https://korban.net/posts/elm/2018-11-27-build-complex-forms-validation-elm/

-}
type alias Form values output =
    Base.Form values output (Field values)



-- Fields


{-| Create a form that contains a single text field.

It requires some configuration:

  - `parser` specifies how to validate the field. It needs a function that processes the value of
    the field and produces a `Result` of either:
      - a `String` describing an error
      - a correct `output`
  - `value` describes how to obtain the field value from the form `values`
  - `update` describes how the current form `values` should be updated with a new field value
  - `attributes` let you define the specific attributes of the field (`label` and `placeholder`
    in this case, see [`TextField.Attributes`](Form-Base-TextField#Attributes))

It might seem like a lot of configuration, but don't be scared! In practice, it isn't!
For instance, you could use this function to build a `nameField` that only succeeds when the
inputted name has at least 2 characters, like this:

    nameField : Form { r | name : String } String
    nameField =
        Form.textField
            { parser =
                \name ->
                    if String.length name < 2 then
                        Err "the name must have at least 2 characters"

                    else
                        Ok name
            , value = .name
            , update =
                \newValue values ->
                    { values | name = newValue }
            , attributes =
                { label = "Name"
                , placeholder = "Type your name..."
                }
            }

As you can see:

  - a `parser` is just a simple validation function
  - you can define `value` using [record accessors](http://elm-lang.org/docs/records#access)
  - the `update` function updates the `values` of the form with the `newValue`
  - `attributes` are most of the time a simple record

-}
textField :
    { parser : String -> Result String output
    , value : values -> String
    , update : String -> values -> values
    , error : values -> Maybe String
    , attributes : TextField.Attributes
    }
    -> Form values output
textField =
    TextField.form Text


markdownField : String -> Form values ()
markdownField md =
    let
        customField _ =
            { state = Markdown md
            , result = Ok ()
            , isEmpty = False
            }
    in
    Base.custom customField



-- Composition


{-| Create an **empty** form that always succeeds when filled, returning the given `output`.

It might seem pointless on its own, but it becomes useful when used in combination with other
functions. The docs for [`append`](#append) have some great examples.

-}
succeed : output -> Form values output
succeed =
    Base.succeed


{-| Append a form to another one while **capturing** the `output` of the first one.

For instance, we could build a signup form:

    signupEmailField : Form { r | email : String } EmailAddress
    signupEmailField =
        Form.emailField
            { -- ...
            }

    signupPasswordField : Form { r | password : String } Password
    signupPasswordField =
        Form.passwordField
            { -- ...
            }

    signupForm :
        Form
            { email : String
            , password : String
            }
            ( EmailAddress, Password )
    signupForm =
        Form.succeed Tuple.pair
            |> Form.append signupEmailField
            |> Form.append signupPasswordField

In this pipeline, `append` is being used to feed the `Tuple.pair` function and combine two forms
into a bigger form that outputs `( EmailAddress, Password )` when submitted.

**Note:** You can use [`succeed`](#succeed) smartly to **skip** some values.
This is useful when you want to append some fields in your form to perform validation, but
you do not care about the `output` they produce. An example of this is a "repeat password" field:

    passwordForm :
        Form
            { password : String
            , repeatPassword : String
            }
            Password
    passwordForm =
        Form.succeed (\password repeatedPassword -> password)
            |> Form.append passwordField
            |> Form.append repeatPasswordField

-}
append : Form values a -> Form values (a -> b) -> Form values b
append =
    Base.append


{-| Make a form optional. An optional form succeeds when:

  - All of its fields are **empty**, producing `Nothing`
  - All of its fields are **correct**, producing `Just` the `output`

Let's say we want to optionally ask for a website name and address:

    websiteForm =
        Form.optional
            (Form.succeed Website
                |> Form.append websiteNameField
                |> Form.append websiteAddressField
            )

This `websiteForm` will only be valid if **both** fields are blank, or **both** fields
are filled correctly.

-}
optional : Form values output -> Form values (Maybe output)
optional =
    Base.optional


{-| Disable a form.

You can combine this with [`meta`](#meta) to disable parts of a form based on its
own values.

-}
disable : Form values output -> Form values output
disable =
    Base.disable


{-| Fill a form `andThen` fill another one.

This is useful to build dynamic forms. For instance, you could use the output of a `selectField`
to choose between different forms, like this:

    type Msg
        = CreatePost Post.Body
        | CreateQuestion Question.Title Question.Body

    type ContentType
        = Post
        | Question

    type alias Values =
        { type_ : String
        , title : String
        , body : String
        }

    contentForm : Form Values Msg
    contentForm =
        Form.selectField
            { parser =
                \value ->
                    case value of
                        "post" ->
                            Ok Post

                        "question" ->
                            Ok Question

                        _ ->
                            Err "invalid content type"
            , value = .type_
            , update = \newValue values -> { values | type_ = newValue }
            , attributes =
                { label = "Which type of content do you want to create?"
                , placeholder = "Choose a type of content"
                , options = [ ( "post", "Post" ), ( "question", "Question" ) ]
                }
            }
            |> Form.andThen
                (\contentType ->
                    case contentType of
                        Post ->
                            let
                                bodyField =
                                    Form.textareaField
                                        { -- ...
                                        }
                            in
                            Form.succeed CreatePost
                                |> Form.append bodyField

                        Question ->
                            let
                                titleField =
                                    Form.textField
                                        { -- ...
                                        }

                                bodyField =
                                    Form.textareaField
                                        { -- ...
                                        }
                            in
                            Form.succeed CreateQuestion
                                |> Form.append titleField
                                |> Form.append bodyField
                )

-}
andThen : (a -> Form values b) -> Form values a -> Form values b
andThen =
    Base.andThen


{-| Build a form that depends on its own `values`.

This is useful when you need some fields to perform validation based on
the values of other fields. An example of this is a "repeat password" field:

    repeatPasswordField :
        Form
            { r
                | password : String
                , repeatPassword : String
            }
            ()
    repeatPasswordField =
        Form.meta
            (\values ->
                Form.passwordField
                    { parser =
                        \value ->
                            if value == values.password then
                                Ok ()

                            else
                                Err "the passwords do not match"
                    , value = .repeatPassword
                    , update =
                        \newValue values ->
                            { values | repeatPassword = newValue }
                    , attributes =
                        { label = "Repeat password"
                        , placeholder = "Type your password again..."
                        }
                    }
            )

-}
meta : (values -> Form values output) -> Form values output
meta =
    Base.meta



-- Mapping


{-| Transform the `output` of a form.

This function can help you to keep forms decoupled from specific view messages:

    Form.map SignUp signupForm

-}
map : (a -> b) -> Form values a -> Form values b
map =
    Base.map


{-| Transform the `values` of a form.

This can be useful when you need to nest forms:

    type alias SignupValues =
        { email : String
        , password : String
        , address : AddressValues
        }

    addressForm : Form AddressValues Address

    signupForm : Form SignupValues Msg
    signupForm =
        Form.succeed SignUp
            |> Form.append emailField
            |> Form.append passwordField
            |> Form.append
                (Form.mapValues
                    { value = .address
                    , update = \newAddress values -> { values | address = newAddress }
                    }
                    addressForm
                )

-}
mapValues : { value : a -> b, update : b -> a -> a } -> Form b output -> Form a output
mapValues { value, update } form =
    Base.meta
        (\values ->
            form
                |> Base.mapValues value
                |> Base.mapField (mapFieldValues update values)
        )


mapFieldValues : (a -> b -> b) -> b -> Field a -> Field b
mapFieldValues update values field =
    let
        mapUpdate fn value =
            update (fn value) values

        newUpdate oldValues =
            update oldValues values
    in
    case field of
        Text field_ ->
            Text (Field.mapValues newUpdate field_)

        Markdown s ->
            Markdown s



-- Output


{-| Represents a form field.

If you are writing custom view code you will probably need to pattern match this type,
using the result of [`fill`](#fill).

-}
type Field values
    = Text (TextField values)
    | Markdown String


{-| Represents a filled field.
-}
type alias FilledField values =
    Base.FilledField (Field values)


{-| Fill a form with some `values`.

It returns:

  - a list of the fields of the form, alongside their errors
  - the result of the filled form, which can either be:
      - a non-empty list of validation errors
      - the correct `output`
  - whether the form is empty or not

-}
fill :
    Form values output
    -> values
    ->
        { fields : List (FilledField values)
        , result : Result ( Error, List Error ) output
        , isEmpty : Bool
        }
fill =
    Base.fill
