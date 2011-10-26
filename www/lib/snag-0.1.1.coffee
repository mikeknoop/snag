###

	Snag.js 0.1.1
	A stupidly simple (to use) javascript drag and drop
	(c) 2010 Mike Knoop, Snapier LLC
	Snag may be freely distributed under the MIT license.
	For all details and documentation:
	http://github.com/mikeknoop/snag

	This file compiles with CoffeeScript (http://jashkenas.github.com/coffee-script/)

	In your CSS, create two global classes:
		.dragging			-	these styles applied to the element while being dragged
		.drag-placeholder	-	defines the styles of the placeholder (the "shadow" drop target)

	Enable dragging between parent elements who have the "drag-parent-ex-1" class:
		$(document).ready ->
			dd = new SnagDragDrop("drag-parent-ex-1")

	Dependencies:
		jQuery (tested with > 1.6.2)
	
###

class SnagDragDrop
	# @className			-	name of the class to enable drag/drop between
	# @dragEl				-	el which is being dragged
	# @dropTargetParent		-	el name of parent target to drop draggables into
	#							if null, mouse is not over a DroppableTarget
	# @dropInsertTo			-	el name of target to insert (before/after)
	# @dropBeforeOrAfter	-	string, 'before' or 'after' or null
	# @uid_i				-	unique id counter

	constructor: (@className) ->
		@uid_i = 0
		@attachHooks(@className)
		@dropTargetParent = null
		@dropInsertTo = null
		@dropBeforeOrAfter = null
		@dragEl = null

	attachHooks: (className) -> 
		# attach drop hooks to eahc className and
		# drag hooks to each child of className
		@attachDroppable(className)
		@attachDraggable(className)
		dd = this
		$(document).bind('mousedown.'+@className, (e) ->
			dd.mouseDown(e)
		)
		$(document).bind('mouseup.'+@className, (e) ->
			dd.mouseUp(e)
		)

	mouseDown: (e) ->
		# mouseDown/Up fixes cursor change when dragging
		return false if @dragEl?

	mouseUp: (e) ->
		# mouseDown/Up fixes cursor change when dragging
		return false if @dragEl?

	attachDroppable: (className) ->
		ddList = this
		$(".#{className}").each ->
			$(this).data('drag-context', new DroppableTarget(ddList, this))
			
	attachDraggable: (className) ->
		ddList = this
		$(".#{className}").children().each ->
			$(this).data('drag-context', new DraggableItem(ddList, this))

	getUniqueId: ->
		@uid_i = @uid_i+1
		d = new Date().getTime()
		uid = d+@uid_i
		return uid

class DraggableItem
	# defines an item which can be manipulated
	# uid			-	unique id
	# @ddList		-	dragdrop list this item can be dragged to
	# @el			-	DOM element this object is attached to
	# @dragging		-	bool, currently being dragged
	# @mouseOffsetX	-	int, offset x from top-left corner of element (to keep dragged element relative to mouse)
	# @mouseOffsetY	-	int, offset y "
	# @originalParent	-	parent element, used to know where to snap back to if not dropped onto a DroppableTarget
	# @leftButtonDown 	- 	helps eliminate mouse tracking errors

	constructor: (@ddList, @el) ->
		@uid = @ddList.getUniqueId()
		@dragging = false
		@attachCallbacks(@el)
		@attachCss(@el)
		@originalParent = $(el).parent()
		@leftButtonDown = false
	
	attachCallbacks: (el) ->
		di = this
		$(el).bind('mousedown', (e) ->
			di.beginDrag(e, el)
		)
		# mouseup is bound dynamically when dragging begins (see beginDrag)
		# bind the movement callback (to actually change the el position)
		$(document).bind('mousemove.'+@uid, (e) ->
			di.updateDrag(e, el)
		)

	attachCss: (el) ->
		# attach drag specific styles needed to work
		$(el).addClass(@ddList.className+'-item')

	beginDrag: (e, el) ->
		di = this
		@dragging = true
		@ddList.dragEl = el
		# add handler for ending drag
		$(document).bind('mouseup.'+@uid, (e) ->
			di.endDrag(e, el)
		)
		# left mouse button was pressed, set flag
		@leftButtonDown = true if (e.which == 1) 
		# save mouse offset plus a hard osset to account for cursor size
		@mouseOffsetX = e.pageX - $(el).offset().left + 15
		@mouseOffsetY = e.pageY - $(el).offset().top + 10
		# now append (and remove from current parent) to body
		$(el).appendTo('body')
		# adds absolute positioning and shadow/rotation styles
		$(el).addClass('dragging')
		$(el).css('position', 'absolute')
		# set initial position on page
		$(el).css('left', e.pageX - @mouseOffsetX)
		$(el).css('top', e.pageY - @mouseOffsetY)
		$(document).trigger('mousemove', e);

	endDrag: (e, el) ->
		di = this
		@dragging = false
		@dragEl = null
		$(document).unbind('mouseup.'+@uid)
		# remove end drag handler
		# left mouse button was released, clear flag
		@leftButtonDown = false if (e.which == 1)
		# remove absolute positioning and styles
		$(el).removeClass("dragging")
		$(el).css('position', '')
		# reset position
		$(el).css('left', '')
		$(el).css('top', '')
		@attachDropElement($(el))
		$(document).trigger('mousemove', e);
	
	updateDrag: (e, el) ->
		return if not @dragging
		# item is being dragged (mouse moved while in dragging state)
		# update the coord of this element relative to offset
		#mouseX = @mouseOffsetX - e.pageX
		#mouseY = @mouseOffsetY - e.pageY
		@tweakMouseMoveEvent(e)	# help eliminate tracking errors
		if (e.which == 1)
			# if the mouse is up, dragging shouldn't be happening (edge case)
			@endDrag(e, el)
			return false
		mouseX = e.pageX
		mouseY = e.pageY
		$(el).css('left', mouseX - @mouseOffsetX)
		$(el).css('top', mouseY - @mouseOffsetY)
		# adds a placeholder "grey box" into the dom to show where the item will be dropped
		# to do this generally, copy the draggable element
		ph = $(document.createElement($(@ddList.dragEl).get(0).tagName))
		ph.addClass("#{@ddList.className}-item drag-placeholder")
		@attachDropElement(ph)

	attachDropElement: (el) ->
		if (@ddList.dropTargetParent == null)
			# not dropped on a DroppableTarget, append back to original parent
			$(el).appendTo(@originalParent)
		else
			# mouse is over a DroppableTarget, where to attach target?
			# the second conditional checks the case where the last element is being
			if (@ddList.dropInsertTo != null and @ddList.dragEl != @ddList.dropInsertTo)
				# implies we have an element to append before or after
				if (@ddList.dropBeforeOrAfter == 'before')
					# append before a specific child inside the parent
					el.insertBefore(@ddList.dropInsertTo)
				else if (@ddList.dropBeforeOrAfter == 'after')
					# append after
					el.insertAfter(@ddList.dropInsertTo)
			else
				# no element selected to insert after, append to top level parent
				el.appendTo(@ddList.dropTargetParent)


	tweakMouseMoveEvent: (e) ->
		# helper function for preventing mouse tracking errors
		#Check from jQuery UI for IE versions < 9
		leftButtonDown = false if ($.browser.msie && !(document.documentMode >= 9) && !event.button)
		# If left button is not set, set which to 0
		# This indicates no buttons pressed
		e.which = 0 if (e.which == 1 && !leftButtonDown)

class DroppableTarget
	# defines a target which can have things dropped into it
	# uid			-	unique id
	# @ddList		-	dragdrop list this item can be dragged to
	# @el			-	DOM element this object is attached to
	# @inTarget		-	bool, mouse is in the target
	# @maxItems		-	int, max items this droppable can hold

	constructor: (@ddList, @el) ->
		@uid = @ddList.getUniqueId()
		@attachCallbacks(@el)
		@attachCss(@el)
		@inTarget = false
		@ddList.dropTargetParent = null
		@ddList.dropInsertTo = null
		@ddList.dropBeforeOrAfter = null
		if $(el).data('max-items')?
			@maxItems = $(el).data('max-items')
		else
			@maxItems = null
	
	attachCallbacks: (el) ->
		dt = this
		$(document).bind('mousemove.'+@uid, (e, trigger) ->
			if trigger?
				e.pageX = trigger.pageX
				e.pageY = trigger.pageY
			dt.checkInTarget(e, el)
			dt.findElInsertAfter(e, el)
		)

	checkInTarget: (e, el) ->
		if @isInBoundary(e, el)
			if (not @inTarget)
				@inTarget = true
				@enter(e, el)
		else if (@inTarget)
			@inTarget = false
			@leave(e, el)

	isInBoundary: (e, el) ->
		# given a mouse X and Y, check if it is within this droppable target
		mX = e.pageX
		mY = e.pageY
		x = $(el).offset().left
		y = $(el).offset().top
		dX = $(el).outerWidth()
		dY = $(el).outerHeight()
		if (mX >= x && mX <= x+dX && mY >= y && mY <= y+dY)
			return true
		else
			return false
	
	findElInsertAfter: (e, el) ->
		# loop over each child and check if it's in boundary
		dt = this
		event = e
		# do a special check on last element before removing placeholder
		# because the moues might "appear" to hover over last element
		# when in reality there is no item below it due to the plcaeholders
		# being removed (also make sure not to match the placeholder)
		$(el).children('*:not(.drag-placeholder)').last().each ->
			if (dt.isInBoundary(event, this))
				dt.ddList.dropInsertTo = this
				dt.ddList.dropBeforeOrAfter = 'after'
		# now remove the placeholder and see if the mouse if over any of the
		# draggable elements (indicating we should place the placeholder in 
		# that spot)
		$(el).children('.drag-placeholder').remove()
		$(el).children().each ->
			if (dt.isInBoundary(event, this))
				dt.ddList.dropInsertTo = this
				dt.ddList.dropBeforeOrAfter = 'before'

	attachCss: (el) ->
		# attach drag specific styles neede to work
		$(el).css('position', 'relative')
	
	isMaxed: ->
		if ($(@el).children().length < @maxItems or @maxItems == null)
			return false
		else
			return true

	enter: (e, el) ->
		if (not @isMaxed())
			@ddList.dropTargetParent = @el

	leave: (e, el) ->
		@ddList.dropTargetParent = null
		@ddList.dropInsertTo = null
		@ddList.dropBeforeOrAfter = null

# monitor services list
$(document).ready ->
	dd = new SnagDragDrop("dd-service")