import 'dart:html';
import 'dart:math';
import 'package:web_ui/watcher.dart' as watchers;

int width = 600; //canvas grid size
int height = 400;


int sizex = 50; //number of cells X
int sizey = 50; //number of cells Y

int scale = 4; //drawing scale
int box_size = 4; //cell size


int density = 50; //initial density of randomly alive cells

CanvasElement canvas = query("#canvas");
CanvasRenderingContext2D context = canvas.getContext('2d');

bool drawingOn = false; //are we drawing?

bool mouse_is_drawing = false;//is the mouse down?

int last_flipped_y = 0; //last cell manually flipped
int last_flipped_x = 0;

var list = new List(); // the cells 
var buffer_list = new List(); // the cells "back buffer". 

num renderTime;
double fpsAverage;
/**
 * Display the animation's FPS in a div.
 */
void showFps(num fps) {
  if (fpsAverage == null) {
    fpsAverage = fps;
  }

  fpsAverage = fps * 0.05 + fpsAverage * 0.95;

  query("#notes").text = "${fpsAverage.round().toInt()} fps";
}
void populate_playfield_list(){ //create the initial cell layout using the chosen %
  print("random");
  var rng = new Random();
  list.clear();
  for (var y = 0;y<sizey; y+=1) {
  var t = new List();
  for (var x = 0;x<sizex; x+=1) {
    int ran = rng.nextInt(100);
    if (ran>density){t.add(false);}//50-50 random filled or not
    else{t.add(true);}
  }

 list.add(t);
 t = new List();

  }
  drawCanvas();
}

void make_buffer_list(){ //make an all "false" array the same size as hte main array
  buffer_list.clear();
  var t = new List();
  for (var y = 0;y<sizey; y+=1) {
  t.clear();
  for (var x = 0;x<sizex; x+=1) {
    t.add(false);
  }
  buffer_list.add(t);
  t = new List();

  }
}


void main() { //attach components to functions
  
  InputElement  density_slider_component = query("#densityslider");
  density_slider_component.on.change.add((Event e) {
    drawingOn = false;
    density = int.parse(density_slider_component.value);
    populate_playfield_list();
    drawCanvas();
    watchers.dispatch();//update the slider value
  });
  
  InputElement cellslider = query("#cellslider");
  cellslider.on.change.add((Event e) {
    drawingOn = false;
    var cell_count = int.parse(cellslider.value);
    sizex=cell_count;
    sizey=cell_count;

    populate_playfield_list();
    drawCanvas();

  });
  
  InputElement boxsizeslider = query("#boxsizeslider");
  boxsizeslider.on.change.add((Event e) {
    int box_size_from_scale = int.parse(boxsizeslider.value);
    box_size = box_size_from_scale;
    drawCanvas();

  });
  
  InputElement scaleslider = query("#scaleslider");
  scaleslider.on.change.add((Event e) {
    int scaleslider_value = int.parse(scaleslider.value);
    scale =scaleslider_value;
    drawCanvas();//redraw with new values

  });
  
  var button2 = query('#seed');
  button2.on.click.add((e) => populate_playfield_list());
  
  populate_playfield_list(); //create an initial grid population

  canvas.on.mouseDown.add((MouseEvent event) => mouse_is_drawing=true);
  
  canvas.on.mouseUp.add((MouseEvent event) => mouse_is_drawing=false);
  
  canvas.on.mouseMove.add((MouseEvent event) => flipBox(event));
  
  var button = query('#start_anim');
  button.on.click.add((e) => start_up_anim());
  
  var stop_button = query('#stop_anim');
  stop_button.on.click.add((e) => drawingOn = false);
  }


void start_up_anim(){ //start animation
  if (!drawingOn){ //if we're not already drawing
  drawingOn = true;
  requestRedraw();
  }
}


void drawCanvas() {//draw the list of cells

  context.save();
  try {
  context.clearRect(0, 0, width, height);
  context.beginPath();

  for (var y = 0;y<sizey; y+=1) {  
  for (var x = 0;x<sizex; x+=1) {
    
    if (list[x][y]==true) 
    {
    context.strokeRect(x*scale,y*scale,box_size,box_size);//apply scaling and box size

    }
    else
    {
      context.fillRect(x*scale,y*scale,box_size,box_size);  
   }
  }
}
context.stroke();
  }
  finally {
    context.restore();
  }
}



void flipBox([MouseEvent event]) {//flip the chosen cell to it's opposite state. 
  if (mouse_is_drawing) {
  
  event.preventDefault();
  var x =event.offsetX;
  var y =event.offsetY;
  var pixel_x = x/scale;
  var pixel_y = y/scale;
  pixel_x = pixel_x.toInt();
  pixel_y = pixel_y.toInt();
  
  if ((pixel_x!=last_flipped_x)&&(pixel_y!=last_flipped_y)) {//check we've not just flipped this one just now

  bool current_state = list[pixel_x][pixel_y];
  if (current_state) {
    list[pixel_x][pixel_y] = false;  
  }
  else
  {
    list[pixel_x][pixel_y] = true;

  }
  last_flipped_y = pixel_y;
  last_flipped_x = pixel_y;//save the last one flipped so we don[t reflip it until another is flipped
  drawCanvas();
  calculate_neighbours(pixel_x,pixel_y);
  }
  }
}


int calculate_neighbours(int x, int y) {
  int count = 0;
  //print("X $x Y $y");

  if ((x<sizex-1)&&(y<sizey-1)&&(x>1)&&(y>1)){//hack to fix border issue = all cells at the border are dead
 
    
  bool top_left = list[x-1][y-1];
  if (top_left){count++;}
  bool top = list[x][y-1];
  if (top){count++;}
  bool top_right = list[x+1][y-1];  
  if (top_right){count++;}
  
  bool left = list[x-1][y];
  if (left){count++;}//if we have 4 or more just return 4 
  if (count==4) {return 4;}
  bool right = list[x+1][y]; 
  if (right){count++;}
  if (count==4) {return 4;}
  bool bottom_left = list[x-1][y+1];
  if (bottom_left){count++;}
  if (count==4) {return 4;}
  bool bottom = list[x][y+1];
  if (bottom){count++;}
  if (count==4) {return 4;}
  bool bottom_right = list[x+1][y+1]; 
  if (bottom_right){count++;}
  if (count==4) {return 4;}

  return count;
  }
  else{
  return 0; //we're on the edge so return 0 which kills the cell. 
  }
  }


void run_the_game(){//main loop
  //print("game run");

  make_buffer_list();

  for (var y = 0;y<sizey; y+=1) {    

    for (var x = 0;x<sizex; x+=1) {

      int neighbours = calculate_neighbours(x,y);
      bool alive = list[x][y];
      
      if (alive==true){
        switch(neighbours) {
        case 0:
          buffer_list[x][y] = false;
          break;          
        case 1:
          buffer_list[x][y] = false;
          break;
        case 2:
          buffer_list[x][y] = true;
          break;
        case 3:
          buffer_list[x][y] = true;
          break;
        default://no need for more as 3+ = death
          buffer_list[x][y] = false;
          break;

        }
      }
      
      else if ((alive==false)&&(neighbours==3))
          {
          buffer_list[x][y] = true;      //bring to life
          }  
      
    }
}

  list.clear();//update the global list with the newly calculated cell map
  for (List l in buffer_list){
    List l_clone = new List.from(l);
    list.add(l_clone); }

}


void draw(num _) { //main main animation loop
  
  num time = new Date.now().millisecondsSinceEpoch;

  if (renderTime != null) {
    showFps((1000 / (time - renderTime)).round());
  }

   renderTime = time;
   
   run_the_game();
   drawCanvas();
   requestRedraw();
}

void requestRedraw() {
  if (drawingOn) {
  window.requestAnimationFrame(draw);
  }
}

