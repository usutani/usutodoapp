# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  window.Todo = Backbone.Model.extend
    EMPTY: "empty todo..."
    
    initialize: -> unless this.get("content") then this.set("content": @EMPTY)
    
    toggle: -> this.save(done: not this.get("done"))
    
    clear: ->
      this.destroy()
      this.view.remove()
  
  window.TodoList = Backbone.Collection.extend
    model: Todo
    url: "todos"
    
    done: -> this.filter (todo) -> todo.get('done')
    
    remaining: -> this.without.apply(this, this.done())
    
    nextOrder: ->
      return 1 unless this.length
      this.last().get('order') + 1
    
    comparator: (todo) -> todo.get('order')
  
  window.Todos = new TodoList
  
  window.TodoView = Backbone.View.extend
    tagName:  "li"
    events:
      "touchend div.todo-content"   : "toggleDone"
      "touchend span.todo-edit"     : "edit"
      "keypress .todo-input"        : "updateOnEnter"
    
    initialize: ->
      _.bindAll(this, 'render', 'close')
      @model.bind('change', this.render)
      @model.view = this
    
    render: ->
      out = this.divTodo()
      out += '<div class="display">'
      out += '<div class="check"' + this.isChecked() + '/>'
      out += '<div class="todo-content"></div>'
      out += '<span class="todo-edit"></span>'
      out += '</div>'
      out += '<div class="edit">'
      out += '<input class="todo-input" type="text" value="" />'
      out += '</div>'
      out += '</div>'
      $(this.el).html(out)
      this.setContent()
      this
    
    divTodo: ->
      return '<div class="todo done">' if this.isDone()
      return '<div class="todo">'
    
    isChecked: -> if this.isDone() then ' checked="checked"' else ''
    
    isDone: -> this.model.get('done')
    
    setContent: ->
      content = this.model.get('content')
      this.$('.todo-content').text(content)
      this.input = this.$('.todo-input')
      this.input.bind('blur', this.close)
      this.input.val(content)
    
    toggleDone: -> this.model.toggle()
    
    edit: ->
      $(this.el).addClass("editing")
      this.input.focus()
    
    close: ->
      this.model.save(content: this.input.val())
      $(this.el).removeClass("editing")
    
    updateOnEnter: (e) -> this.close() if e.keyCode is 13 
    
    remove: -> $(this.el).remove()
    
    clear: -> this.model.clear()
  
  window.AppView = Backbone.View.extend
    el: $("#todoapp")
    
    events:
      "keypress #new-todo":     "createOnEnter"
      "keyup #new-todo":        "showTooltip"
      "touchend .todo-clear a": "clearCompleted"
    
    initialize: ->
      _.bindAll(this, 'addOne', 'addAll', 'render')
      this.input    = this.$("#new-todo")
      Todos.bind('add',     this.addOne)
      Todos.bind('reset',   this.addAll)
      Todos.bind('all',     this.render)
      Todos.fetch()
    
    render: ->
      total = Todos.length
      done = Todos.done().length
      remaining = Todos.remaining().length
      this.todostats(total, done, remaining)
    
    todostats:(total, done, remaining) ->
      if total
        out = '<div id="todo-stats">'
        out += '<span class="todo-count">'
        out += '<span class="number">'
        out += remaining + '</span>'
        out += '<span class="word"> item(s) left.</span>'
        out += '</span>' + this.todoclear(done) + '</div>'
      else
        out = '<div id="todo-stats" />'
      $('#todo-stats').replaceWith(out)
    
    todoclear: (done) ->
      return '' unless done
      out = '<div class="todo-clear">'
      out += '<a href="">Clear completed item(s).</a></div>'
      out
    
    addOne: (todo) ->
      view = new TodoView(model: todo)
      this.$("#todo-list").append(view.render().el)
    
    addAll: -> Todos.each(this.addOne)
    
    newAttributes: ->
      content: this.input.val()
      order:   Todos.nextOrder()
      done:    no
    
    createOnEnter: (e) ->
      return if e.keyCode isnt 13
      Todos.create(this.newAttributes())
      this.input.val('')
    
    clearCompleted: ->
      _.each(Todos.done(), (todo) -> todo.clear())
      false
    
    showTooltip: (e) ->
      tooltip = this.$(".ui-tooltip-top")
      val = this.input.val()
      tooltip.fadeOut()
      clearTimeout(this.tooltipTimeout) if this.tooltipTimeout
      return if val is '' or val is this.input.attr('placeholder')
      show = -> tooltip.show().fadeIn()
      this.tooltipTimeout = _.delay(show, 1000)
  
  window.App = new AppView
