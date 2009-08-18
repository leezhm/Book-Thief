package {
  import flash.display.Sprite;
  import com.wilqo.BookThief;
  
  public class BookThiefExample extends Sprite {
    
    public function BookThiefExample() {
      var stolen:BookThief = new BookThief(teddy,"http://www.wilqo.com",true,5000);
      addChild(stolen);
    }
    
  }
}