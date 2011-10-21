Snag.js 0.1.0

A stupidly simple (to use) javascript drag and drop<br />
(c) 2010 Mike Knoop, Snapier LLC<br />
Snag may be freely distributed under the MIT license.<br />
For all details and documentation:<br />
http://github.com/mikeknoop/snag

This file compiles with CoffeeScript (http://jashkenas.github.com/coffee-script/)

In your CSS, create two global classes:<br />
	<code>.dragging</code> 		-	these styles applied to the element while being dragged<br />
	<code>.drag-placeholder</code>	-	defines the styles of the placeholder (the "shadow" drop target)<br />

Enable dragging between parent elements who have the "drag-parent-ex-1" class:<br />
	<code>$(document).ready -><br />
		dd = new SnagDragDrop("drag-parent-ex-1")</code><br />

Dependencies:<br />
	jQuery (tested with > 1.6.2)<br />
