var iScroller = Class.extend({
	init : function(dom){
		this.dom = $(dom);
		this.rebuildDom();
		this.addListeners();
		this.sensitivity = 10;
	},

	addListeners : function(){
		var self = this;
		this.viewContent.unbind();
		
		this.viewContent.bind('touchstart', function(e){
			var c = self.coordinates(e);
			self.touchStart(c[self.axis]);
		});

		this.viewContent.bind('touchmove', function(e){
			var c = self.coordinates(e);
			self.scroll(c[self.axis]);
		});

		this.viewContent.bind('touchend', function(e){
			var c = self.coordinates(e);
			self.coast(c[self.axis]);
		});	
		
		$(window).bind('orientationchange', function(){
			self.calculateDimensions();
		});
	},

	rebuildDom : function(){
		this.dom.children().wrapAll('<div class="view_content"></div>');
		this.viewContent = this.dom.find('.view_content');
		this.viewContent.css('position', 'relative');
		this.viewContent.css(this.dimension, 'auto');
		this.calculateDimensions();
	},
	
	calculateDimensions : function(){
		this.viewContentDimension = this.calcViewContentDimension();
		this.scrollerDimension = this.calcScrollerDimension();
	},

	touchStart : function(d){
		this.start = d;
		this.current = this.start;
		this.startTime = new Date().getTime();
	},

	scroll : function(d){
		var diff = d - this.current;
		if (Math.abs(d - this.start) < this.sensitivity){
			return;
		}
		this.current += diff;			
		var direction = (diff >= 0 ? 1 : -1);
		var desiredPosition = this.viewContentPosition() + diff; 
		var boundary = this.boundaryCheck(desiredPosition);
		
		if (boundary != null){	
			diff = direction * 100 * (1 - Math.exp(-0.01 * Math.abs(d - this.start)));			
			this.setViewContentPosition(boundary + diff)
		} else {
			this.setViewContentPosition(this.viewContentPosition() + diff);
		}
	},

	coast : function(d){
		var diff = d - this.start;
		if (Math.abs(diff) < this.sensitivity){
			return;
		}
		
		var swipeDurationInSeconds = (new Date().getTime() - this.startTime) / 1000;
		var coast = 2 * (diff) * Math.exp(-swipeDurationInSeconds);	

		var self = this;

		this.viewContent.stop(false, true).animate(
			this.animateProperties(this.viewContentPosition() + coast),
			{
				duration: 1000,
				easing: 'easeOutCubic',
				step : function(){
					self.bounceBack();
				}
			}
		);
	},

	boundaryCheck : function(viewContentPosition){
		this.calculateDimensions();

		var boundary = null;
		var nothingToScroll = this.viewContentDimension <= this.scrollerDimension;
		var overExtension = this.viewContentDimension - this.scrollerDimension;

		if (nothingToScroll){
			boundary = 0;
		} else {
			if (viewContentPosition >= 0){ // preextended
				boundary = 0
			} else if (-viewContentPosition > overExtension) { //overextended
				boundary = -overExtension
			}			
		}

		return boundary;
	},

	bounceBack : function(){		
		var boundary = this.boundaryCheck(this.viewContentPosition());

		if (boundary != null) {
			this.viewContent.stop().animate(
				this.animateProperties(boundary),
				{
					duration: 500,
					easing : 'easeOutCubic'
				}
			);
		}
	},

	viewContentPosition : function(){
		var pos = this.viewContent.css(this.cssAxis);
		return pos == "auto" ? 0 : +(pos.replace("px", ""));
	},

	setViewContentPosition : function(val){
		this.viewContent.css(this.cssAxis, val)
	},

	coordinates : function(e){
		var changedTouches = e.originalEvent.changedTouches;			
		var lastTouch = changedTouches.item(changedTouches.length - 1);
		return {x: lastTouch.screenX, y : lastTouch.screenY};
	}
});

var iScrollerY = iScroller.extend({
	init : function(dom){
		this.axis = 'y';
		this.dimension = 'height';
		this.cssAxis = 'top';
		this._super(dom);
	},
	
	animateProperties : function(val){
		return { top : val };
	},

	calcViewContentDimension : function(){
		return this.viewContent.innerHeight();
	},

	calcScrollerDimension : function(){
		return this.dom.innerHeight();
	}
});

var iScrollerX = iScroller.extend({
	init : function(dom){
		this.axis = 'x';
		this.dimension = 'width';
		this.cssAxis = 'left';
		this._super(dom);
	},
	
	animateProperties : function(val){
		return { left : val };
	},

	calcViewContentDimension : function(){
		return this.viewContent.attr('scrollWidth');
	},

	calcScrollerDimension : function(){
		return this.dom.innerWidth();		
	}
});
