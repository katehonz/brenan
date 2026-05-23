## Client-Side Form + Validation Demo
## Compile: nim js -p:src -o:examples/form_client.js examples/form_client.nim

import nimleptos
import nimleptos/client/reactive_dom
import nimleptos/client/dom_interop
import nimleptos/reactive/signal
import nimleptos/reactive/effects
import std/dom

when defined(js):
  type
    FormState = object
      name: string
      email: string
      message: string

  let (formState, setFormState) = createSignal(FormState(name: "", email: "", message: ""))
  let (errors, setErrors) = createSignal(seq[string](@[]))
  let (submitted, setSubmitted) = createSignal(false)

  proc validate(state: FormState): seq[string] =
    result = @[]
    if state.name.len < 2:
      result.add("Name must be at least 2 characters.")
    if state.email.len == 0 or '@' notin state.email:
      result.add("Email is invalid.")
    if state.message.len < 5:
      result.add("Message must be at least 5 characters.")

  proc formApp(): seq[DomElement] =
    let heading = createElement("h1")
    heading.textContent = "Contact Form"

    # Name input
    let nameLabel = createElement("label")
    nameLabel.textContent = "Name:"
    let nameInput = createElement("input")
    nameInput.setAttribute("type", "text")
    nameInput.setAttribute("class", "form-input")
    nameInput.addEventListener("input", proc(e: Event) =
      let val = $cast[InputElement](e.target).value
      let s = formState()
      setFormState(FormState(name: val, email: s.email, message: s.message))
      setSubmitted(false)
    )

    # Email input
    let emailLabel = createElement("label")
    emailLabel.textContent = "Email:"
    let emailInput = createElement("input")
    emailInput.setAttribute("type", "email")
    emailInput.setAttribute("class", "form-input")
    emailInput.addEventListener("input", proc(e: Event) =
      let val = $cast[InputElement](e.target).value
      let s = formState()
      setFormState(FormState(name: s.name, email: val, message: s.message))
      setSubmitted(false)
    )

    # Message textarea
    let msgLabel = createElement("label")
    msgLabel.textContent = "Message:"
    let msgInput = createElement("textarea")
    msgInput.setAttribute("class", "form-input")
    msgInput.addEventListener("input", proc(e: Event) =
      let val = $cast[TextAreaElement](e.target).value
      let s = formState()
      setFormState(FormState(name: s.name, email: s.email, message: val))
      setSubmitted(false)
    )

    # Error list
    let errorList = createElement("ul")
    errorList.setAttribute("class", "error-list")
    discard createEffect(proc() =
      let errs = errors()
      clearChildren(errorList)
      for err in errs:
        let li = createElement("li")
        li.textContent = err
        errorList.appendChild(li)
    )

    # Submit button
    let submitBtn = createElement("button")
    submitBtn.textContent = "Submit"
    submitBtn.setAttribute("class", "btn")
    submitBtn.addEventListener("click", proc(e: Event) =
      let errs = validate(formState())
      setErrors(errs)
      if errs.len == 0:
        setSubmitted(true)
    )

    # Success message
    let successEl = createElement("p")
    successEl.setAttribute("class", "success-msg")
    let successText = reactiveTextNode(proc(): string =
      if submitted(): "Thank you, " & formState().name & "! We will contact you soon."
      else: ""
    )
    successEl.appendChild(successText)

    return @[
      heading,
      nameLabel, nameInput,
      emailLabel, emailInput,
      msgLabel, msgInput,
      errorList,
      submitBtn,
      successEl
    ]

  mountReactiveApp("#app", formApp)
