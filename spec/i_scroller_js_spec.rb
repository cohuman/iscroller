ENV["JOHNSON_HEAP_SIZE"] = '0x40000000' #1 GB
require 'spec'
require 'harmony'

describe "iScroller.js" do
  ROOT = File.expand_path(File.dirname(__FILE__) + '/../')
  
  def js(cmd)
    @dom.execute_js(cmd)
  end
  
  before do
    @dom = Harmony::Page.new( "
    <html>
    <body>
    <div id='scroller'>
      <span>foo</span>
      <ul>
        <li>bar</li>
        <li>baz</li>
      </ul>
    </div>
    </body>
    </html>
    " )

    js_files = [
      ROOT + '/spec/spec_helper.js',
      ROOT + '/lib/class_inheritance.js',
      ROOT + '/lib/jquery-1.4.2.min.js',
      ROOT + '/lib/jquery-ui-1.8.4.custom.min.js',
      ROOT + '/iScroller.js'
    ]

    @dom.load( *(js_files ) )

    js("
      var fakeEvent = {
        changedTouches : {
          length : 1,
          item : function(){return {}}
        }
      };

      iScroller.prototype.calculateDimensions = function(){
        //don't do it because the dom doesn't have real dimensions
      }

      var scroller = new iScrollerY($('#scroller'));
      
      scroller.setViewContentPosition(-250);
      scroller.scrollerDimension = 500;
      scroller.viewContentDimension = 1000;

      // scroll is at bottom boundary
      function bottomOut(){
        scroller.setViewContentPosition(-500);
        scroller.scrollerDimension = 500;
        scroller.viewContentDimension = 1000;
      }
            
      // scroll is at top boundary
      function topOut(){
        scroller.setViewContentPosition(0);
        scroller.scrollerDimension = 500;
        scroller.viewContentDimension = 1000;
      }

    ")    
  end
  
  describe 'listening' do
    it 'should listen for touchstart events' do
      js("
        scroller.touchStart = addEventFunction('touch started');
        e = $.Event('touchstart');
        e.originalEvent = fakeEvent;

        scroller.viewContent.trigger(e);
        events
      ").should include 'touch started'
    end
    
    it 'should listen for touchend events' do
      js("
        scroller.coast = addEventFunction('touch ended');
        e = $.Event('touchend');
        e.originalEvent = fakeEvent;

        scroller.viewContent.trigger(e);
        events
      ").should include 'touch ended'
    end
    
    it 'should scroll on touchmove' do
      js("
        scroller.scroll = addEventFunction('scrolling');
        e = $.Event('touchmove');
        e.originalEvent = fakeEvent;
         
        scroller.viewContent.trigger(e);
        events
      ").should include 'scrolling'
    end
  end

  describe  'initialization' do
    it 'should store the start point of the touchstart' do
      js("
        scroller.touchStart(200);
        scroller.start;
      ").should == 200
    end
    
    it 'should rebuild the dom' do
      js("
        scroller.viewContent
      ").should_not be_nil
    end
    
    it 'should store the scroller viewContent height' do
      (js("
        scroller.viewContentDimension
      ") > 0).should be_true
    end
  end
  
  describe 'scroll()' do
    
    describe 'in bounds' do
      before do
        js("
          scroller.coast = function(){
            //don't coast
          }
          scroller.touchStart(150);
        ")
      end

      it 'scrolls up' do
        js("
          scroller.scroll(125);
          scroller.viewContentPosition()
        ").should == -275

        js("
          scroller.scroll(100);
          scroller.viewContentPosition()
        ").should == -300
      end
      
      it 'scrolls down' do
         js("
            scroller.scroll(175);
            scroller.viewContentPosition()
          ").should == -225

          js("
            scroller.scroll(200);
            scroller.viewContentPosition()
          ").should == -200
      end
      
    end
    
    describe 'out of bounds penalizes movement' do
      it 'viewContent is same size as scroller' do
        
        top = js("
          scroller.setViewContentPosition(0);
          scroller.scrollerDimension = 50;
          scroller.viewContentDimension = 50;
          scroller.touchStart(25);
          scroller.scroll(-50);
          scroller.viewContentPosition()
        ")
        
        (top > -75).should be_true
        (top < 0).should be_true
      end
      
       it 'viewContent is slightly smaller than scroller' do

          top = js("
            scroller.setViewContentPosition(0);
            scroller.scrollerDimension = 275;
            scroller.viewContentDimension = 267;
            scroller.touchStart(25);
            scroller.scroll(-50);
            scroller.viewContentPosition()
          ")

          (top > -75).should be_true
          (top < 0).should be_true
        end
      
      
      it 'finger swipe down but already at the top of the list' do
         top = js("
            topOut();
            scroller.touchStart(150);
          
            scroller.scroll(175);
            scroller.viewContentPosition()
          ")
          
          (top < 25).should be_true
          (top > 0).should be_true
      end
    
      it 'finger swipe up but no more list' do
        top = js("
            bottomOut();
            scroller.touchStart(100);
            scroller.scroll(75);
            scroller.viewContentPosition()
          ")
          
          (top > -525).should be_true
          (top < -500).should be_true
      end
    end
  end
  
  describe "bounceBack()" do    

    it "does nothing if within bounds" do
      js("
        var viewContentTop = scroller.viewContentPosition();
        scroller.bounceBack();
        scroller.viewContentPosition() == viewContentTop
      ").should be_true
    end
    
    describe 'out of bounds' do
      it 'bounces back if above the top' do
        js("
          topOut();
          scroller.setViewContentPosition(10);
          scroller.bounceBack();
          scroller.viewContent.stop(false, true);
          scroller.viewContentPosition()
        ").should == 0
      end
      
      it 'bounces back if below the bottom' do
        js("
          bottomOut();
          scroller.setViewContentPosition(-510);
          scroller.bounceBack();
          scroller.viewContent.stop(false, true);
          scroller.viewContentPosition()
        ").should == -500
      end
    end
    
  end
  
  describe "coast()" do
    it 'jumps to the end of the animation' do
     js("
        scroller.setViewContentPosition(0);
        scroller.viewContent.stop = function(stopAnimation, jumpToEnd){
          if (!stopAnimation && jumpToEnd){
            addEvent('added to the end');
          }
          return scroller.viewContent;
        }
        scroller.touchStart(50);
        scroller.coast(100);
        events
      ").should include('added to the end')
    end
    
    it 'coasts longer for faster swipes' do
      js("  
          scroller.touchStart(50);
          scroller.viewContent.stop = function(){
            return scroller.viewContent;
          }
          
          var quickSwipe;  
          scroller.startTime = new Date(new Date().getTime() - 1000).getTime();
          scroller.viewContent.animate = function(opts){
              quickSwipe = opts.top;
          }
          
          scroller.coast(100);
          
         var slowSwipe;
         scroller.startTime = new Date(new Date().getTime() - 2000).getTime();
         scroller.viewContent.animate = function(opts){
              slowSwipe = opts.top;
          }

          scroller.coast(100);
          quickSwipe > slowSwipe
        ").should be_true
    end
  end
  
end