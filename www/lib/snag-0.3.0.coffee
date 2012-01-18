###

	Snag.js 0.3.0
	A simple javascript drag and drop
	(c) 2010 Mike Knoop
	Snag may be freely distributed under the MIT license.
	For all details and documentation:
	http://github.com/mikeknoop/snag

	This file compiles with CoffeeScript (http://jashkenas.github.com/coffee-script/)

	In your CSS, create three global classes:
		.dd-item				-	this class automatically added to each child element tracked
		.dragging			-	these styles applied to the element while being dragged
		.drag-placeholder	-	defines the styles of the placeholder (the "shadow" drop target)

	Enable dragging between parent elements who share "drag=true" data attribute:
		$(document).ready ->
			dd = new SnagDragDrop(['div[data-drag=true]''])

	Snag will trigger event named 'change:dom' to the parent droppables when elements within have changed.
	Trigger the event 'rescan:snag' on $(document) to tell Snag to re-analyze the page (such as after an AJAX load).

	Dependencies:
		jQuery 1.7 (tested with > 1.7)
	
###

if (typeof define == "function" and define.amd)
	define('snag', ['jquery'], ($) -> return factory($))

factory = ($) ->
	class Snag
		# @selectors				-	(array) of selectors to enable drag/drop between
		# @dragEl					-	el which is being dragged
		# @dropTargetParent		-	el name of parent target to drop draggables into
		#							if null, mouse is not over a DroppableTarget
		# @dropInsertTo			-	el name of target to insert (before/after)
		# @dropBeforeOrAfter		-	string, 'before' or 'after' or null
		# @uid_i						-	unique id counter

		constructor: (@selectors) ->
			@uid_i = 0
			@dropTargetParent = null
			@dropInsertTo = null
			@dropBeforeOrAfter = null
			@dragEl = null
			@attachHooks(@selectors)

		attachHooks: (selectors) -> 
			dd = this
			$(document).on 'mousedown.snag', (e) ->
				dd.mouseDown(e)
			$(document).on 'mouseup.snag', (e) ->
				dd.mouseUp(e)
			# create a global listener for snag rescan events
			@createListener(selectors)
			# now trigger one such event to initialize everything
			$(document).trigger('rescan:snag')

		mouseDown: (e) ->
			# mouseDown/Up fixes cursor change when dragging
			return false if @dragEl?

		mouseUp: (e) ->
			# mouseDown/Up fixes cursor change when dragging
			return false if @dragEl?

		createListener: (selectors) ->
			dd = @
			$(document).on 'rescan:snag', (e) ->
				# means we need to re-discover all selectors, check their children
				# to ensure they still match their parent, and if not, create new
				# droppableItems for them
				# first unbind old event handlers for all dd-items which may no longer exist
				$(document).off('.snag.item')
				for selector in dd.selectors
					$(selector).each ->
						$(@).data('drag-context').removeHandlers() if $(@).data('drag-context')?
						$(@).data('drag-context', null)
						$(@).data('drag-context', new DroppableTarget(dd, @, selector))
					$(selector).each ->
						# do this seperately because order of the DroppableTarget/Item is important
						# mouse callback handlers are sensitive of order
						$(@).children().each ->
							$(@).data('drag-context').removeHandlers() if $(@).data('drag-context')?
							$(@).data('drag-context', null)
							$(@).data('drag-context', new DraggableItem(dd, @, selector))

		getUniqueId: ->
			@uid_i = @uid_i+1
			d = new Date().getTime()
			uid = d+@uid_i
			return uid

	class DraggableItem
		# defines an item which can be manipulated
		# uid			-	unique id
		# selector		-	selector of the drag/drop list this item is attached to
		# @ddList		-	dragdrop list this item can be dragged to
		# @el			-	DOM element this object is attached to
		# @dragging		-	bool, currently being dragged
		# @mouseOffsetX	-	int, offset x from top-left corner of element (to keep dragged element relative to mouse)
		# @mouseOffsetY	-	int, offset y "
		# @originalParent	-	parent element, used to know where to snap back to if not dropped onto a DroppableTarget
		# @leftButtonDown 	- 	helps eliminate mouse tracking errors
		# @previousParent	-	parent who owned the element prior to the most recent drag event

		constructor: (@ddList, @el, @selector) ->
			@uid = @ddList.getUniqueId()
			@selector = @selector
			@dragging = false
			@addedDraggingClassCounter = 0
			@attachCallbacks(@el)
			@attachCss(@el)
			@originalParent = $(el).parent()
			@previousParent = @originalParent
			@leftButtonDown = false
		
		removeHandlers: () ->
			$(@el).off()
			$(document).off('mousemove.snag.item.'+@uid)
			$(document).off('mouseup.snag.item.'+@uid)

		attachCallbacks: (el) ->
			di = this
			$(el).on('mousedown', (e) ->
				di.beginDrag(e, el)
			)
			# mouseup is bound dynamically when dragging begins (see beginDrag)
			# bind the movement callback (to actually change the el position)
			$(document).on('mousemove.snag.item.'+@uid, (e) ->
				di.updateDrag(e, el)
			)

		attachCss: (el) ->
			# attach drag specific styles needed to work
			# $(el).addClass(@ddList.className+'-item')
			$(el).removeClass('dd-item').addClass('dd-item')

		beginDrag: (e, el) ->
			di = this
			@dragging = true
			@ddList.dragEl = el
			# add handler for ending drag
			$(document).on('mouseup.snag.item.'+@uid, (e) ->
				di.endDrag(e, el)
			)
			# left mouse button was pressed, set flag
			@leftButtonDown = true if (e.which == 1) 
			# save mouse offset plus a hard offset to account for cursor size
			@mouseOffsetX = e.pageX - $(el).offset().left + parseInt($(el).css('margin-left').replace('px', ''))
			@mouseOffsetY = e.pageY - $(el).offset().top + parseInt($(el).css('margin-top').replace('px', ''))
			# now append (and remove from current parent) to body
			$(el).appendTo('body')

			# a counter is used since mousemove is manually invoked right after this,
			# yet we dont want to actually add the styles until the user actually moves the mouse
			@addedDraggingClassCounter = 0
			$(el).css('position', 'absolute')
			# set initial position on page
			$(el).css('left', e.pageX - @mouseOffsetX)
			$(el).css('top', e.pageY - @mouseOffsetY)

			$(document).trigger('mousemove', e)

		endDrag: (e, el) ->
			di = this
			@dragging = false
			$(document).off('mouseup.'+@uid)
			# remove end drag handler
			# left mouse button was released, clear flag
			@leftButtonDown = false if (e.which == 1)
			# remove absolute positioning and styles
			$(el).removeClass("dragging")
			$(el).css('position', '')
			# reset position
			$(el).css('left', '')
			$(el).css('top', '')
			parent = @attachDropElement($(el), false)
			@ddList.dragEl = null #make sure this is after the attachDropElement call
			$(document).trigger('mousemove', e);
			# fire events on both origin and destination el if different
			if ($(@previousParent).get(0) != $(parent).get(0))
				$(@previousParent).trigger('change:dom')
				$(parent).trigger('change:dom')
			# update prev parent
			@previousParent = parent

			# invoke a click if the counter == 0 or 1 (meaning the item wasnt dragged)
			if @addedDraggingClassCounter == 0 or @addedDraggingClassCounter == 1
				#$(@previousParent).find('.drag-placeholder').trigger('click')
				$(el).trigger('click')
				
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

			if @addedDraggingClassCounter > 1
				# adds absolute positioning and shadow/rotation styles
				$(el).addClass('dragging')
			else if @addedDraggingClassCounter < 2
				@addedDraggingClassCounter = @addedDraggingClassCounter + 1

			mouseX = e.pageX
			mouseY = e.pageY
			$(el).css('left', mouseX - @mouseOffsetX)
			$(el).css('top', mouseY - @mouseOffsetY)
			# adds a placeholder "grey box" into the dom to show where the item will be dropped
			# to do this generally, copy the draggable element
			ph = $(document.createElement($(@ddList.dragEl).get(0).tagName))
			ph.addClass("dd-item drag-placeholder")
			# @copyDataAttributes(@ddList.dragEl, ph)
			parent = @attachDropElement(ph, true)

		attachDropElement: (el, deb) ->
			if (@ddList.dropTargetParent == null)
				# not dropped on a DroppableTarget, append back to original parent
				parent = @originalParent
				$(el).appendTo(parent)
			else
				# mouse is over a DroppableTarget, where to attach target?
				# the second conditional checks the case where the last element is being
				if (@ddList.dropInsertTo != null and $(@ddList.dragEl).get(0) != $(@ddList.dropInsertTo).get(0))
					# implies we have an element to append before or after
					parent = @ddList.dropInsertTo
					if (@ddList.dropBeforeOrAfter == 'before')
						# append before a specific child inside the parent
						el.insertBefore(@ddList.dropInsertTo)
					else if (@ddList.dropBeforeOrAfter == 'after')
						# append after
						el.insertAfter(@ddList.dropInsertTo)
				else
					# no element selected to insert after, append to top level parent
					parent = @ddList.dropTargetParent
					el.appendTo(parent)
			return parent

		tweakMouseMoveEvent: (e) ->
			# helper function for preventing mouse tracking errors
			#Check from jQuery UI for IE versions < 9
			leftButtonDown = false if ($.browser.msie && !(document.documentMode >= 9) && !event.button)
			# If left button is not set, set which to 0
			# This indicates no buttons pressed
			e.which = 0 if (e.which == 1 && !leftButtonDown)
	
		copyDataAttributes: (src, target) ->
			# copies all data attributes from a source el to target el
			a = $(src).get(0).attributes
			d = $(target).eq(0)
			d.attr(a[i].name, a[i].value) for c, i in $(src).get(0).attributes when not a[i].name.indexOf('data-')

	class DroppableTarget
		# defines a target which can have things dropped into it
		# selectors   	-	selector of this element
		# uid				-	unique id
		# @ddList		-	dragdrop list this item can be dragged to
		# @el				-	DOM element this object is attached to
		# @inTarget		-	bool, mouse is in the target
		# @maxItems		-	int, max items this droppable can hold

		constructor: (@ddList, @el, @selector) ->
			@name = $(@el).attr('id')
			@uid = @ddList.getUniqueId()
			@selector = @selector
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
		
		removeHandlers: () ->
			$(document).off('mousemove.snag.item.'+@uid)
			$(document).off('mousemove.snag.item.'+@uid)

		attachCallbacks: (el) ->
			dt = this
			$(document).on('mousemove.snag.item.'+@uid, (e, trigger) ->
				c1 = $(dt.ddList.dragEl)?.data('drag-context')?.selector
				c2 = dt.selector
				if (c1 == c2)
					if trigger?
						e.pageX = trigger.pageX
						e.pageY = trigger.pageY
					dt.checkInTarget(e, el)
					dt.findElInsertAfter(e, el)
				else
					$(el).children('.drag-placeholder').remove()
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
		
	return Snag