/*

	Snag.js 0.2.0
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

	Enable dragging between parent elements who share "drag1" class:
		$(document).ready ->
			dd = new SnagDragDrop(["drag1"])

	Snag will trigger event named 'change:dom' to the parent droppables when elements within have changed.
	Trigger the event 'snag:rescan' on $(document) to tell Snag to re-analyze the page (such as after an AJAX load).

	Dependencies:
		jQuery 1.7 (tested with > 1.7)
	
*/
var DraggableItem, DroppableTarget, SnagDragDrop;
SnagDragDrop = (function() {
  function SnagDragDrop(classNames) {
    this.classNames = classNames;
    this.uid_i = 0;
    this.dropTargetParent = null;
    this.dropInsertTo = null;
    this.dropBeforeOrAfter = null;
    this.dragEl = null;
    this.attachHooks(this.className);
  }
  SnagDragDrop.prototype.attachHooks = function(classNames) {
    var dd;
    dd = this;
    $(document).on('mousedown.SnagDragDrop', function(e) {
      return dd.mouseDown(e);
    });
    $(document).on('mouseup.snag', function(e) {
      return dd.mouseUp(e);
    });
    this.createListener(classNames);
    return $(document).trigger('snag:rescan');
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
  SnagDragDrop.prototype.createListener = function(classNames) {
    var dd;
    dd = this;
    return $(document).on('snag:rescan', function(e) {
      var className, _i, _len, _ref, _results;
      _ref = dd.classNames;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        className = _ref[_i];
        _results.push($("." + className).each(function() {
          var _ref2;
          if (!($(this).data('drag-context') != null) || ((_ref2 = $(this).data('drag-context')) != null ? _ref2.className : void 0) !== className) {
            if ($(this).data('drag-context') != null) {
              $(this).data('drag-context').removeHandlers();
            }
            $(this).data('drag-context', null);
            $(this).data('drag-context', new DroppableTarget(dd, this, className));
          }
          return $(this).children().each(function() {
            var _ref3;
            if (!($(this).data('drag-context') != null) || ((_ref3 = $(this).data('drag-context')) != null ? _ref3.className : void 0) !== className) {
              if ($(this).data('drag-context') != null) {
                $(this).data('drag-context').removeHandlers();
              }
              $(this).data('drag-context', null);
              return $(this).data('drag-context', new DraggableItem(dd, this, className));
            }
          });
        }));
      }
      return _results;
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
  function DraggableItem(ddList, el, className) {
    this.ddList = ddList;
    this.el = el;
    this.className = className;
    this.uid = this.ddList.getUniqueId();
    this.className = this.className;
    this.dragging = false;
    this.attachCallbacks(this.el);
    this.attachCss(this.el);
    this.originalParent = $(el).parent();
    this.previousParent = this.originalParent;
    this.leftButtonDown = false;
  }
  DraggableItem.prototype.removeHandlers = function() {
    $(this.el).off();
    $(document).off('mousemove.' + this.uid);
    return $(document).off('mouseup.' + this.uid);
  };
  DraggableItem.prototype.attachCallbacks = function(el) {
    var di;
    di = this;
    $(el).on('mousedown', function(e) {
      return di.beginDrag(e, el);
    });
    return $(document).on('mousemove.' + this.uid, function(e) {
      return di.updateDrag(e, el);
    });
  };
  DraggableItem.prototype.attachCss = function(el) {
    return $(el).addClass('dd-item');
  };
  DraggableItem.prototype.beginDrag = function(e, el) {
    var di;
    di = this;
    this.dragging = true;
    this.ddList.dragEl = el;
    $(document).on('mouseup.' + this.uid, function(e) {
      return di.endDrag(e, el);
    });
    if (e.which === 1) {
      this.leftButtonDown = true;
    }
    this.mouseOffsetX = e.pageX - $(el).offset().left;
    this.mouseOffsetY = e.pageY - $(el).offset().top;
    $(el).appendTo('body');
    $(el).addClass('dragging');
    $(el).css('position', 'absolute');
    $(el).css('left', e.pageX - this.mouseOffsetX);
    $(el).css('top', e.pageY - this.mouseOffsetY);
    return $(document).trigger('mousemove', e);
  };
  DraggableItem.prototype.endDrag = function(e, el) {
    var di, parent;
    di = this;
    this.dragging = false;
    $(document).unbind('mouseup.' + this.uid);
    if (e.which === 1) {
      this.leftButtonDown = false;
    }
    $(el).removeClass("dragging");
    $(el).css('position', '');
    $(el).css('left', '');
    $(el).css('top', '');
    parent = this.attachDropElement($(el));
    this.ddList.dragEl = null;
    $(document).trigger('mousemove', e);
    if ($(this.previousParent).get(0) !== $(parent).get(0)) {
      $(this.previousParent).trigger('change:dom');
      $(parent).trigger('change:dom');
    }
    return this.previousParent = parent;
  };
  DraggableItem.prototype.updateDrag = function(e, el) {
    var mouseX, mouseY, parent, ph;
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
    ph.addClass("dd-item drag-placeholder");
    return parent = this.attachDropElement(ph);
  };
  DraggableItem.prototype.attachDropElement = function(el) {
    var parent;
    if (this.ddList.dropTargetParent === null) {
      parent = this.originalParent;
      $(el).appendTo(parent);
    } else {
      if (this.ddList.dropInsertTo !== null && $(this.ddList.dragEl).get(0) !== $(this.ddList.dropInsertTo).get(0)) {
        parent = this.ddList.dropInsertTo;
        if (this.ddList.dropBeforeOrAfter === 'before') {
          el.insertBefore(this.ddList.dropInsertTo);
        } else if (this.ddList.dropBeforeOrAfter === 'after') {
          el.insertAfter(this.ddList.dropInsertTo);
        }
      } else {
        parent = this.ddList.dropTargetParent;
        el.appendTo(parent);
      }
    }
    return parent;
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
  function DroppableTarget(ddList, el, className) {
    this.ddList = ddList;
    this.el = el;
    this.className = className;
    this.uid = this.ddList.getUniqueId();
    this.className = this.className;
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
  DroppableTarget.prototype.removeHandlers = function() {
    $(document).off('mousemove.' + this.uid);
    return $(document).off('mousemove.' + this.uid);
  };
  DroppableTarget.prototype.attachCallbacks = function(el) {
    var dt;
    dt = this;
    return $(document).on('mousemove.' + this.uid, function(e, trigger) {
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