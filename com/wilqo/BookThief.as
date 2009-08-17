/*

BookThief V1.0 - A simple page flip class primarily built to be used for simple banners
Created by Karl (karlbright) Brightman - wilqo.com
karl@wilqo.com

*/

package com.wilqo {
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
    private const BACK_COLOR:Number = 0x7d88be;
    private const BACK_OPACITY:Number = 1;
    private const PEEL_RATE:Number = 3;
    
    private const DEBUG_MODE:Boolean = false;
    private const LINE_OPACITY:Number = 0;
    
    private var spine:Number;
    private var edge:Number;
    private var halfPage:Number;
    private var peelInterval:Number;
    private var curl:Number = 20;
    
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
      addChild(line);
      addEvents();
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
    
    private function positionLine():void {
      line.rotation = LINE_ANGLE;
    }
    
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
    
    private function startPeel(e:Event):void {
      dispatchEvent(new Event(PEEL_START));
      addEventListener(MouseEvent.MOUSE_UP,stopPeel);
      addEventListener(MouseEvent.MOUSE_MOVE,movePeel);
    }
    
    private function stopPeel(e:Event):void {
      dispatchEvent(new Event(PEEL_STOP));
      removeEventListener(MouseEvent.MOUSE_UP,stopPeel);
      removeEventListener(MouseEvent.MOUSE_MOVE,movePeel);
      peelInterval = line.y>halfPage ? setInterval(completePeel,10) : setInterval(cancelPeel,10);
    }
    
    private function doCurl(e:Event):void {
      line.y += (curl+line.y)/PEEL_RATE;
      movePages();
      if((curl-line.y)<1) removeEventListener(Event.ENTER_FRAME,doCurl);
    }
    
    private function movePeel(e:Event):void {
      line.y = mouseY;
      if(line.y>spine) {
        line.y = spine;
      } else if(line.y<edge) {
        line.y = edge;
      }
      movePages();
    }
    
    private function movePages():void {
      back.alpha = 1;
      backContainer.y = line.y;
      backContainer.rotation = 90+((LINE_ANGLE*2)*((line.y-spine)/source.height));
      back.x = -(edge-line.y);
      line.rotation = LINE_ANGLE*(line.y+spine)/source.height;
    }
    
    private function completePeel():void {
      line.y += (spine-line.y)/PEEL_RATE;
      if((spine-line.y)<1) {
        back.alpha = 0;
        dispatchEvent(new Event(PEEL_COMPLETE));
        clearInterval(peelInterval);
      }
      movePages();
    }
    
    private function cancelPeel():void {
      line.y -= (line.y-curl)/PEEL_RATE;
      if((line.y-curl)<1) {
        line.y = curl;
        dispatchEvent(new Event(PEEL_CANCELLED));
        clearInterval(peelInterval);
      }
      movePages();
    }

    private function addEvents():void {
      addEventListener(Event.ENTER_FRAME,doCurl);
      hotspot.addEventListener(MouseEvent.MOUSE_DOWN,startPeel);
      addEventListener(BookThief.PEEL_COMPLETE,onPeelComplete);
    }
    
    private function onPeelComplete(e:Event):void {
      stage.addEventListener(MouseEvent.CLICK,function(){navigateToURL(new URLRequest(url));});
    }
    
  }
}