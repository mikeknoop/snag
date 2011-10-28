/*

	Snag.js 0.1.2
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
	
*/
var DraggableItem, DroppableTarget, SnagDragDrop;
SnagDragDrop = (function() {
  function SnagDragDrop(className) {
    this.className = className;
    this.uid_i = 0;
    this.attachHooks(this.className);
    this.dropTargetParent = null;
    this.dropInsertTo = null;
    this.dropBeforeOrAfter = null;
    this.dragEl = null;
  }
  SnagDragDrop.prototype.attachHooks = function(className) {
    var dd;
    this.attachDroppable(className);
    this.attachDraggable(className);
    dd = this;
    $(document).bind('mousedown.' + this.className, function(e) {
      return dd.mouseDown(e);
    });
    return $(document).bind('mouseup.' + this.className, function(e) {
      return dd.mouseUp(e);
    });
  };
  SnagDragDrop.prototype.mouseDown = function(e) {
    if (this.dragEl != null) {
      return false;
    }
  };
  SnagDragDrop.prototype.mouseUp = function(e) {
    if (this.dragEl != null) {
      return false;
    }
  };
  SnagDragDrop.prototype.attachDroppable = function(className) {
    var ddList;
    ddList = this;
    return $("." + className).each(function() {
      return $(this).data('drag-context', new DroppableTarget(ddList, this));
    });
  };
  SnagDragDrop.prototype.attachDraggable = function(className) {
    var ddList;
    ddList = this;
    return $("." + className).children().each(function() {
      return $(this).data('drag-context', new DraggableItem(ddList, this));
    });
  };
  SnagDragDrop.prototype.getUniqueId = function() {
    var d, uid;
    this.uid_i = this.uid_i + 1;
    d = new Date().getTime();
    uid = d + this.uid_i;
    return uid;
  };
  return SnagDragDrop;
})();
DraggableItem = (function() {
  function DraggableItem(ddList, el) {
    this.ddList = ddList;
    this.el = el;
    this.uid = this.ddList.getUniqueId();
    this.dragging = false;
    this.attachCallbacks(this.el);
    this.attachCss(this.el);
    this.originalParent = $(el).parent();
    this.leftButtonDown = false;
  }
  DraggableItem.prototype.attachCallbacks = function(el) {
    var di;
    di = this;
    $(el).bind('mousedown', function(e) {
      return di.beginDrag(e, el);
    });
    return $(document).bind('mousemove.' + this.uid, function(e) {
      return di.updateDrag(e, el);
    });
  };
  DraggableItem.prototype.attachCss = function(el) {
    return $(el).addClass(this.ddList.className + '-item');
  };
  DraggableItem.prototype.beginDrag = function(e, el) {
    var di;
    di = this;
    this.dragging = true;
    this.ddList.dragEl = el;
    $(document).bind('mouseup.' + this.uid, function(e) {
      return di.endDrag(e, el);
    });
    if (e.which === 1) {
      this.leftButtonDown = true;
    }
    this.mouseOffsetX = e.pageX - $(el).offset().left + 15;
    this.mouseOffsetY = e.pageY - $(el).offset().top + 10;
    $(el).appendTo('body');
    $(el).addClass('dragging');
    $(el).css('position', 'absolute');
    $(el).css('left', e.pageX - this.mouseOffsetX);
    $(el).css('top', e.pageY - this.mouseOffsetY);
    return $(document).trigger('mousemove', e);
  };
  DraggableItem.prototype.endDrag = function(e, el) {
    var di;
    di = this;
    this.dragging = false;
    this.ddList.dragEl = null;
    $(document).unbind('mouseup.' + this.uid);
    if (e.which === 1) {
      this.leftButtonDown = false;
    }
    $(el).removeClass("dragging");
    $(el).css('position', '');
    $(el).css('left', '');
    $(el).css('top', '');
    this.attachDropElement($(el));
    return $(document).trigger('mousemove', e);
  };
  DraggableItem.prototype.updateDrag = function(e, el) {
    var mouseX, mouseY, ph;
    if (!this.dragging) {
      return;
    }
    this.tweakMouseMoveEvent(e);
    if (e.which === 1) {
      this.endDrag(e, el);
      return false;
    }
    mouseX = e.pageX;
    mouseY = e.pageY;
    $(el).css('left', mouseX - this.mouseOffsetX);
    $(el).css('top', mouseY - this.mouseOffsetY);
    ph = $(document.createElement($(this.ddList.dragEl).get(0).tagName));
    ph.addClass("" + this.ddList.className + "-item drag-placeholder");
    return this.attachDropElement(ph);
  };
  DraggableItem.prototype.attachDropElement = function(el) {
    if (this.ddList.dropTargetParent === null) {
      return $(el).appendTo(this.originalParent);
    } else {
      if (this.ddList.dropInsertTo !== null && this.ddList.dragEl !== this.ddList.dropInsertTo) {
        if (this.ddList.dropBeforeOrAfter === 'before') {
          return el.insertBefore(this.ddList.dropInsertTo);
        } else if (this.ddList.dropBeforeOrAfter === 'after') {
          return el.insertAfter(this.ddList.dropInsertTo);
        }
      } else {
        return el.appendTo(this.ddList.dropTargetParent);
      }
    }
  };
  DraggableItem.prototype.tweakMouseMoveEvent = function(e) {
    var leftButtonDown;
    if ($.browser.msie && !(document.documentMode >= 9) && !event.button) {
      leftButtonDown = false;
    }
    if (e.which === 1 && !leftButtonDown) {
      return e.which = 0;
    }
  };
  return DraggableItem;
})();
DroppableTarget = (function() {
  function DroppableTarget(ddList, el) {
    this.ddList = ddList;
    this.el = el;
    this.uid = this.ddList.getUniqueId();
    this.attachCallbacks(this.el);
    this.attachCss(this.el);
    this.inTarget = false;
    this.ddList.dropTargetParent = null;
    this.ddList.dropInsertTo = null;
    this.ddList.dropBeforeOrAfter = null;
    if ($(el).data('max-items') != null) {
      this.maxItems = $(el).data('max-items');
    } else {
      this.maxItems = null;
    }
  }
  DroppableTarget.prototype.attachCallbacks = function(el) {
    var dt;
    dt = this;
    return $(document).bind('mousemove.' + this.uid, function(e, trigger) {
      if (trigger != null) {
        e.pageX = trigger.pageX;
        e.pageY = trigger.pageY;
      }
      dt.checkInTarget(e, el);
      return dt.findElInsertAfter(e, el);
    });
  };
  DroppableTarget.prototype.checkInTarget = function(e, el) {
    if (this.isInBoundary(e, el)) {
      if (!this.inTarget) {
        this.inTarget = true;
        return this.enter(e, el);
      }
    } else if (this.inTarget) {
      this.inTarget = false;
      return this.leave(e, el);
    }
  };
  DroppableTarget.prototype.isInBoundary = function(e, el) {
    var dX, dY, mX, mY, x, y;
    mX = e.pageX;
    mY = e.pageY;
    x = $(el).offset().left;
    y = $(el).offset().top;
    dX = $(el).outerWidth();
    dY = $(el).outerHeight();
    if (mX >= x && mX <= x + dX && mY >= y && mY <= y + dY) {
      return true;
    } else {
      return false;
    }
  };
  DroppableTarget.prototype.findElInsertAfter = function(e, el) {
    var dt, event;
    dt = this;
    event = e;
    $(el).children('*:not(.drag-placeholder)').last().each(function() {
      if (dt.isInBoundary(event, this)) {
        dt.ddList.dropInsertTo = this;
        return dt.ddList.dropBeforeOrAfter = 'after';
      }
    });
    $(el).children('.drag-placeholder').remove();
    return $(el).children().each(function() {
      if (dt.isInBoundary(event, this)) {
        dt.ddList.dropInsertTo = this;
        return dt.ddList.dropBeforeOrAfter = 'before';
      }
    });
  };
  DroppableTarget.prototype.attachCss = function(el) {
    return $(el).css('position', 'relative');
  };
  DroppableTarget.prototype.isMaxed = function() {
    if ($(this.el).children().length < this.maxItems || this.maxItems === null) {
      return false;
    } else {
      return true;
    }
  };
  DroppableTarget.prototype.enter = function(e, el) {
    if (!this.isMaxed()) {
      return this.ddList.dropTargetParent = this.el;
    }
  };
  DroppableTarget.prototype.leave = function(e, el) {
    this.ddList.dropTargetParent = null;
    this.ddList.dropInsertTo = null;
    return this.ddList.dropBeforeOrAfter = null;
  };
  return DroppableTarget;
})();
$(document).ready(function() {
  var dd;
  return dd = new SnagDragDrop("dd-service");
});