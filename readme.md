Snag.js 0.1.0
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
