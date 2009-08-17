package {
  import flash.display.Sprite;
  import com.wilqo.BookThief;
  
  public class BookThiefExample extends Sprite {
    
    public function BookThiefExample() {
      var stolen:BookThief = new BookThief(teddy,"http://www.wilqo.com");
      addChild(stolen);
    }
    
  }
}