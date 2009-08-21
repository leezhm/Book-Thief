/*

BookThief V1.0 - A simple page flip class primarily built to be used for simple banners
Created by Karl (karlbright) Brightman - wilqo.com
karl@wilqo.com

*/

package com.wilqo {
  import caurina.transitions.Tweener;
  import flash.display.GradientType;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.filters.DropShadowFilter;
  import flash.geom.Matrix;
  import flash.net.navigateToURL;
  import flash.net.URLRequest;
  import flash.utils.setInterval;
  import flash.utils.clearInterval;
  
  public class BookThief extends Sprite {
    
    private const HOTSPOT_RADIUS:Number = 30;
    private const LINE_ANGLE:Number = 45;
    private const MASK_COLOR:Number = 0xFF0000;
    private const MASK_OPACITY:Number = .5;
    private const BACK_OPACITY:Number = 1;
    private const PEEL_RATE:Number = 3;
    private const TUG_DISTANCE:Number = 30;
    private const TUG_BASE:Object = {time:1,transition:"linear",onUpdate:movePages}
    
    private const DEBUG_MODE:Boolean = false;
    private const LINE_OPACITY:Number = 0;
    
    private var spine:Number;
    private var edge:Number;
    private var halfPage:Number;
    private var peelInterval:Number;
    private var curl:Number = 20;
    private var revealDelay:Number;
    private var tug:Boolean;
    private var tugInterval:Number;
    private var revealInterval:Number;
    private var backColor:Number;
    private var shadeColors:Array = [0x000000,0xFFFFFF];
    private var shadeAlphas:Array = [1,1];
    
    private var url:String;
    private var source:MovieClip;
    private var line:Sprite;
    private var hotspot:Sprite;
    private var leftMask:Sprite
    private var rightMask:Sprite;
    private var sourceMask:Sprite;
    private var backContainer:Sprite;
    private var back:Sprite;
    private var shade:Sprite;
    private var shadeMaskContainer:Sprite;
    private var shadeMask:Sprite;
    
    public static const PEEL_COMPLETE:String = "peelComplete";
    public static const PEEL_CANCELLED:String = "peelCancelled";
    public static const PEEL_START:String = "peelStart";
    public static const PEEL_STOP:String = "peelStop";
    
    public function BookThief(mc:MovieClip,url:String,tug:Boolean=true,delay:Number=0,backColor:Number=0x666666,sc:Array=null,sa:Array=null) {
      this.url=url;
      this.backColor=backColor;
      this.tug=tug;
      this.revealDelay=delay;
      if(sc != null) this.shadeColors=sc;
      if(sa != null) this.shadeAlphas=sa;
      
      fixSource(mc);
      setNumbers();
      drawLine();
      drawLineMasks();
      drawBack();
      drawShade();
      positionLine();
      setMasks();
      
      init();
    }
    
    private function fixSource(mc:MovieClip) {
      source = mc;
      this.x = source.x;
      this.y = source.y;
      source.x = source.y = 0;
      source.parent.removeChild(source);
      addChild(source);
    }
    
    private function setNumbers():void {
      spine = source.y + source.height + 1;
      edge = source.y;
      halfPage = spine-(edge+spine)/3;
    }
    
    private function drawLine():void {
      line = new Sprite();
      line.graphics.lineStyle(1,0x000000);
      line.graphics.moveTo(0,25);
      line.graphics.lineTo(0,0-source.height-25);
      line.alpha = LINE_OPACITY;
      hotspot = new Sprite();
      hotspot.graphics.lineStyle(1,0x000000);
      hotspot.graphics.beginFill(0x000000,0);
      hotspot.graphics.drawCircle(0,0,HOTSPOT_RADIUS);
    }
    
    private function drawLineMasks():void {
      leftMask = new Sprite();
      leftMask.graphics.beginFill(MASK_COLOR,MASK_OPACITY);
      leftMask.graphics.drawRect(-source.height,-source.width*1.5,source.height,source.width*1.5);
      leftMask.graphics.endFill();
      leftMask.visible = DEBUG_MODE;
      line.addChild(leftMask);
      
      rightMask = new Sprite();
      rightMask.graphics.beginFill(MASK_COLOR,MASK_OPACITY);
      rightMask.graphics.drawRect(0,-source.width*1.5,source.height,source.width*1.5);
      rightMask.graphics.endFill();
      rightMask.visible = DEBUG_MODE;
      line.addChild(rightMask);
      
      sourceMask = new Sprite();
      sourceMask.graphics.beginFill(MASK_COLOR,MASK_OPACITY);
      sourceMask.graphics.drawRect(0,-(source.width*2),source.height*4,source.width*4);
      sourceMask.graphics.endFill();
      sourceMask.visible = DEBUG_MODE;
      line.addChild(sourceMask);
    }
    
    private function positionLine():void { line.rotation = LINE_ANGLE; }
    
    private function drawBack():void {
      backContainer = new Sprite();      
      back = new Sprite();
      back.graphics.beginFill(backColor,1);
      back.graphics.drawRect(-source.height,-source.width,source.height,source.width);
      back.graphics.endFill();
      
      var backDropShadow:DropShadowFilter = new DropShadowFilter();
      var backFilters:Array = new Array();
      backFilters.push(backDropShadow);
      backDropShadow.angle = -90;
      backDropShadow.alpha = .5;
      backDropShadow.color = 0x000000;
      backDropShadow.blurY = backDropShadow.blurX = 8;
      backDropShadow.distance = 2;
      back.filters = backFilters;
      
      addChild(backContainer);
      backContainer.addChild(back);
    }
    
    private function drawShade():void {
      shadeMaskContainer = new Sprite();
      shadeMask = new Sprite();
      shadeMask.graphics.beginFill(MASK_COLOR,MASK_OPACITY);
      shadeMask.graphics.drawRect(-source.height,-source.width,source.height,source.width);
      shadeMask.graphics.endFill();
      addChild(shadeMaskContainer);
      shadeMaskContainer.addChild(shadeMask);
      
      shade = new Sprite();
      shade.graphics.beginGradientFill(GradientType.LINEAR,[0x000000,0xFFFFFF],[.3,0],[30,255]);
      shade.graphics.drawRect(0,-(source.width*1.5),source.height,source.width*1.5);
      shade.graphics.endFill();
      line.addChild(shade);
    }
    
    private function setMasks():void {
      if(!DEBUG_MODE) {
        source.mask = sourceMask;
        back.mask = rightMask;
        shade.mask = shadeMask;
      }
    }
    
    private function startPeel(e:Event=null):void {
      dispatchEvent(new Event(PEEL_START,true));
      addEventListener(MouseEvent.MOUSE_UP,stopPeel);
      addEventListener(MouseEvent.MOUSE_MOVE,dragPeel);
      clearInterval(revealInterval);
      clearInterval(tugInterval);
      Tweener.removeTweens(line);
    }
    
    private function stopPeel(e:Event=null):void {
      dispatchEvent(new Event(PEEL_STOP,true));
      removeEventListener(MouseEvent.MOUSE_UP,stopPeel);
      removeEventListener(MouseEvent.MOUSE_MOVE,dragPeel);
      line.y>halfPage ? completePeel() : cancelPeel();
    }
    
    private function doCurl(e:Event=null):void { Tweener.addTween(line,{y:curl,time:(curl+line.y)/150,transition:"linear",onUpdate:movePages}); }
    private function setTugInterval():void { if(tug) tugInterval = setInterval(tugCurl,2500); }
    private function tugCurl():void { clearInterval(tugInterval); tugForward(); }
    private function tugForward():void { Tweener.addTween(line, {base:TUG_BASE, y:TUG_DISTANCE, onComplete:tugBack}); }
    private function tugBack():void { Tweener.addTween(line, {base:TUG_BASE, y:curl,onComplete:setTugInterval}); }
    
    private function dragPeel(e:Event):void {
      movePeel(mouseY);
    }
    
    private function movePeel(y:Number,comp:Function=null):void {
      var cy:Number = y;
      if(cy>spine) {
        cy = spine;
      } else  if(cy<curl) {
        cy = curl;
      }
      Tweener.addTween(line,{y:cy,time:.5,onUpdate:movePages,onComplete:comp});
    }
    
    private function movePages():void {
      back.alpha = 1;
      backContainer.y = line.y;
      backContainer.rotation = 90+((LINE_ANGLE*2)*((line.y-spine)/source.height));
      back.x = -(edge-line.y);
      shadeMaskContainer.y = line.y;
      shadeMaskContainer.rotation = 90+((LINE_ANGLE*2)*((line.y-spine)/source.height));
      shadeMask.x = -(edge-line.y);
      line.rotation = LINE_ANGLE*(line.y+spine)/source.height;
    }
    
    private function completePeel():void {
      clearInterval(revealInterval);
      movePeel(spine,function(){
        dispatchEvent(new Event(PEEL_COMPLETE,true));
      });
    }
    
    private function cancelPeel():void {
      movePeel(curl,function(){
        setTugInterval();
        dispatchEvent(new Event(PEEL_CANCELLED,true));
      });
    }

    private function addEvents():void {
      hotspot.addEventListener(MouseEvent.MOUSE_DOWN,startPeel);
      addEventListener(BookThief.PEEL_COMPLETE,onPeelComplete);
    }
    
    private function onPeelComplete(e:Event):void {
      back.visible = false;
      stage.addEventListener(MouseEvent.CLICK,function(){navigateToURL(new URLRequest(url));});
      clearInterval(tugInterval);
    }
    
    private function setRevealDelay():void {
      if(!revealDelay==0) {
        revealInterval = setInterval(completePeel,revealDelay);
      }
    }
    
    private function init():void {
      addChild(line);
      line.addChild(hotspot);
      doCurl();
      addEvents();
      setTugInterval();
      setRevealDelay();
    }
    
  }
}