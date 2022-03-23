# composable forms

> "Build type-safe composable forms in Elm"
>
> Composable: they can be extended and embedded in other forms.
> Type-safe: everything is safely tied together with compiler guarantees.
> Maintainable: you do not need view code nor a msg for each form field.
> Concise: field validation and update logic are defined in a single place.
> Consistent: validation errors are always up-to-date with the current field values.
> Extensible: you can create your own custom fields and write custom view code.

_(quoted from [hecrj/composable-form](https://package.elm-lang.org/packages/hecrj/composable-form/8.0.1/))_

## Session's summary

- Crowd-code `Form.Login` example from [README](https://package.elm-lang.org/packages/hecrj/composable-form/8.0.1/)
- Take a look at the [examples](https://hecrj.github.io/composable-form/) and explain the concepts as they occur
- Take a look at the [API documentation](https://package.elm-lang.org/packages/hecrj/composable-form/8.0.1/Form) of those concepts
- Customize `Form.Login` to use [Bulma](https://bulma.io) ([Form.View](https://package.elm-lang.org/packages/hecrj/composable-form/8.0.1/Form-View))
- Discuss limitations of composable-forms
  - Cancel button
    - Not a limitation: extend LoginForm by cancel button
  - Multiple pages
    - Not a limitation: multiple pages work well as multiple forms
  - Optional-aware fields
    - Limitation within library, could possibly be implemented analog to disabled fields
  - Custom fields
    - Not a limitation: possible within framework
    - Explain [Form.Base](https://package.elm-lang.org/packages/hecrj/composable-form/8.0.1/Form-Base)
- Explain that a top-down approach to customization is preferable to a buttom-up approach
  - I would recommend copying and adjusting `Form` and `Form.View`, and working from there. Mostly, because there is a lot of boilerplate to be writtin for the `Form.View` module when starting bottom-up.
- Take a look at some interesting examples
  - Automatic summary ([AutoSummary.elm](./src/AutoSummary.elm))
    - Use a form to automatically include a summary of itself
  - Markdown field ([MarkdownField.elm](./src/MarkdownField.elm))
    - Create a custom markdown field which just shows arbitrary markdown (no actual input)
  - Record form ([RecordForm.elm](./src/RecordForm.elm))
    - Show how one could write a `Form`-generator which takes an arbitrary Elm record and generates a form for it
