# Collection to keep the todos
Todos = new Meteor.Collection("todos")

# Session var to keep current filter type ("all", "active", "completed")
Session.set "filter", null

# Session var to keep todo which is currently in editing mode, if any
Session.set "editing_todo", null

# JS code for the client (browser)
if Meteor.is_client

  #///////////////////////////////////////////////////////////////////////
  # The following two functions are taken from the official Meteor
  # "Todos" example
  # The original code can be viewed at: https://github.com/meteor/meteor
  #///////////////////////////////////////////////////////////////////////

  # Returns an event_map key for attaching "ok/cancel" events to
  # a text input (given by selector)
  okcancel_events = (selector) ->
    "keyup #{selector}, keydown #{selector}, focusout #{selector}"


  # Creates an event handler for interpreting "escape", "return", and "blur"
  # on a text field and calling "ok" or "cancel" callbacks.
  make_okcancel_handler = (options) ->
    (evt) ->
      if evt.type is "keydown" and evt.which is 27
        # escape = cancel
        options.cancel?.call this, evt
      else if evt.type is "keyup" and evt.which is 13 or evt.type is "focusout"
        # blur/return/enter = ok/submit if non-empty
        value = String(evt.target.value or "")
        if value
          options.ok?.call this, value, evt
        else
          options.cancel?.call this, evt

  # Some helpers

  # Get the number of todos completed
  todos_completed_helper = ->
    Todos.find(completed: true).count()


  # Get the number of todos not completed
  todos_not_completed_helper = ->
    Todos.find(completed: false).count()

  #//
  # Logic for the 'todoapp' partial which represents the whole app
  #//

  # Helper to get the number of todos
  Template.todoapp.todos = ->
    Todos.find().count()

  Template.todoapp.events = {}

  # Register key events for adding new todo
  Template.todoapp.events[okcancel_events("#new-todo")] = make_okcancel_handler
    ok: (title, evt) ->
      Todos.insert
        title: $.trim(title)
        completed: false
        created_at: new Date().getTime()

      evt.target.value = ""

  #//
  # Logic for the 'main' partial which wraps the actual todo list
  #//

  # Get the todos considering the current filter type
  Template.main.todos = ->
    filter = {}
    switch Session.get("filter")
      when "active"
        filter.completed = false
      when "completed"
        filter.completed = true
    Todos.find filter, {sort: {created_at: 1}}


  Template.main.todos_not_completed = todos_not_completed_helper

  # Register click event for toggling complete/not complete button
  Template.main.events = "click input#toggle-all": (evt) ->
    completed = true
    completed = false  unless Todos.find(completed: false).count()
    Todos.find({}).forEach (todo) ->
      Todos.update {_id: todo._id},
        $set: {completed: completed}


  #//
  # Logic for the 'todo' partial representing a todo
  #//

  # True of current todo is completed, false otherwise
  Template.todo.todo_completed = -> @completed


  # Get the current todo which is in editing mode, if any
  Template.todo.todo_editing = -> Session.equals "editing_todo", @_id


  # Register events for toggling todo's state, editing mode and destroying a todo
  Template.todo.events =
    "click input.toggle": ->
      Todos.update @_id, $set: {completed: not @completed}

    "dblclick .view": ->
      Session.set "editing_todo", @_id

    "click button.destroy": ->
      Todos.remove @_id

  # Register key events for updating title of an existing todo
  Template.todo.events[okcancel_events("li.editing input.edit")] = make_okcancel_handler
    ok: (value) ->
      Session.set "editing_todo", null
      Todos.update @_id, $set: {title: $.trim(value)}

    cancel: ->
      Session.set "editing_todo", null
      Todos.remove @_id

  #//
  # Logic for the 'footer' partial
  #//
  Template.footer.todos_completed = todos_completed_helper
  Template.footer.todos_not_completed = todos_not_completed_helper

  # True if exactly one todo is not completed, false otherwise
  # Used for handling pluralization of "item"/"items" word
  Template.footer.todos_one_not_completed = ->
    Todos.find(completed: false).count() is 1

  Template.footer.filter = ->
    all: "all"
    active: "active"
    completed: "completed"

  # True if the requested filter type is currently selected,
  # false otherwise
  Template.footer.filter_selected = (type) ->
    return Session.equals("filter", null)  if type is "all"
    Session.equals "filter", type

  # Register click events for selecting filter type and
  # clearing completed todos
  Template.footer.events =
    "click button#clear-completed": ->
      Todos.remove completed: true

    "click #filters a.all": (evt) ->
      evt.preventDefault()
      Session.set "filter", null

    "click #filters a.active": (evt) ->
      evt.preventDefault()
      Session.set "filter", "active"

    "click #filters a.completed": (evt) ->
      evt.preventDefault()
      Session.set "filter", "completed"
