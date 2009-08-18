package {
  import flash.display.Sprite;
  import com.wilqo.BookThief;
  
  public class BookThiefExample extends Sprite {
    
    public function BookThiefExample() {
      if(!linkURL) var linkURL:String = "http://github.com/karlbright";
      var stolen:BookThief = new BookThief(teddy,linkURL,true,5000);
      addChild(stolen);
    }
    
  }
}