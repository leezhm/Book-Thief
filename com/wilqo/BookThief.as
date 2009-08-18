/*

BookThief V1.0 - A simple page flip class primarily built to be used for simple banners
Created by Karl (karlbright) Brightman - wilqo.com
karl@wilqo.com

*/

package com.wilqo {
  import caurina.transitions.Tweener;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.net.navigateToURL;
  import flash.net.URLRequest;
  import flash.utils.setInterval;
  import flash.utils.clearInterval;
  
  public class BookThief extends Sprite {
    
    private const HOTSPOT_RADIUS:Number = 30;
    private const LINE_ANGLE:Number = 45;
    private const MASK_COLOR:Number = 0xFF0000;
    private const MASK_OPACITY:Number = .5;
    private const BACK_COLOR:Number = 0x666666;
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
    private var tugInterval:Number;
    private var tugActive:Boolean = true;
    
    private var url:String;
    private var source:MovieClip;
    private var line:Sprite;
    private var hotspot:Sprite;
    private var leftMask:Sprite
    private var rightMask:Sprite;
    private var sourceMask:Sprite;
    private var backContainer:Sprite;
    private var back:Sprite;
    
    public static const PEEL_COMPLETE:String = "peelComplete";
    public static const PEEL_CANCELLED:String = "peelCancelled";
    public static const PEEL_START:String = "peelStart";
    public static const PEEL_STOP:String = "peelStop";
    
    public function BookThief(mc:MovieClip,url:String) {
      this.url=url;
      fixSource(mc);
      setNumbers();
      drawLine();
      drawLineMasks();
      drawBack();
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
      line.addChild(hotspot);
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
      back.graphics.beginFill(BACK_COLOR,1);
      back.graphics.drawRect(-source.height,-source.width,source.height,source.width);
      back.graphics.endFill();
      addChild(backContainer);
      backContainer.addChild(back);
    }
    
    private function setMasks():void {
      if(!DEBUG_MODE) {
        source.mask = sourceMask;
        back.mask = rightMask;
      }
    }
    
    private function startPeel(e:Event=null):void {
      dispatchEvent(new Event(PEEL_START));
      addEventListener(MouseEvent.MOUSE_UP,stopPeel);
      addEventListener(MouseEvent.MOUSE_MOVE,dragPeel);
      clearInterval(tugInterval);
      Tweener.removeTweens(line);
    }
    
    private function stopPeel(e:Event=null):void {
      dispatchEvent(new Event(PEEL_STOP));
      removeEventListener(MouseEvent.MOUSE_UP,stopPeel);
      removeEventListener(MouseEvent.MOUSE_MOVE,dragPeel);
      line.y>halfPage ? completePeel() : cancelPeel();
    }
    
    private function doCurl(e:Event=null):void { Tweener.addTween(line,{y:curl,time:(curl+line.y)/150,transition:"linear",onUpdate:movePages}); }
    private function setTugInterval():void { tugInterval = setInterval(tugCurl,2500); }
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
      line.rotation = LINE_ANGLE*(line.y+spine)/source.height;
    }
    
    private function completePeel():void {
      movePeel(spine,function(){
        dispatchEvent(new Event(PEEL_COMPLETE));
      });
    }
    
    private function cancelPeel():void {
      movePeel(curl,function(){
        setTugInterval();
        dispatchEvent(new Event(PEEL_CANCELLED));
      });
    }

    private function addEvents():void {
      hotspot.addEventListener(MouseEvent.MOUSE_DOWN,startPeel);
      addEventListener(BookThief.PEEL_COMPLETE,onPeelComplete);
    }
    
    private function onPeelComplete(e:Event):void {
      stage.addEventListener(MouseEvent.CLICK,function(){navigateToURL(new URLRequest(url));});
    }
    
    private function init():void {
      addChild(line);
      doCurl();
      addEvents();
      setTugInterval();
    }
    
  }
}