boolean[][] grid;
final boolean ALIVE = true;
final boolean DEAD = false;
color RED = color(255, 0, 0);
color GREEN = color(0, 255, 0);
color BLUE = color(0, 0, 255);
color BLACK = color(0, 0, 0);
color ALIVE_COLOR = GREEN;
color DEAD_COLOR = BLACK;
int pixelSize;
int gridSizeX = 192;
int gridSizeY = 108;


void setup() {
  size(1920, 1080);
  // Currently only supports "pixels" that have the same length and height
  pixelSize = width / gridSizeX;

  grid = initGrid(gridSizeX, gridSizeY);

  hint(ENABLE_STROKE_PURE);
  strokeWeight(pixelSize);
  strokeCap(ROUND);
  frameRate(60);
}

final int runtimeMs = 10000;
void draw() {

  if (millis() > runtimeMs){
    float avgFPS = float(frameCount) / float(millis()) * 1000.0;
    println("Frame Count: " + frameCount);
    println("millis():    " + millis());
    println("Ran for " + runtimeMs + " ms, avg FPS: " + avgFPS);
    exit();
  }
  background(BLACK);

  grid = processLife(grid);
  
  for (int y = 0; y < gridSizeY; y++) {
    for (int x = 0; x < gridSizeX; x++) {
      int topLeftX = x * pixelSize;
      int topLeftY = y * pixelSize;
      float cellCenterX = topLeftX + pixelSize / 2;
      float cellCenterY = topLeftY + pixelSize / 2;
      if (grid[x][y]) { 
        stroke(ALIVE_COLOR); 
        point(cellCenterX, cellCenterY);
        }
    }
  }
}

boolean[][] processLife(boolean[][] grid){
  int gridWidth = grid.length;
  int gridHeight = grid[0].length;
  boolean[][] newGrid = new boolean[gridWidth][gridHeight];
  for (int y = 0; y < gridHeight; y++) {
    for (int x = 0; x < gridWidth; x++) {
      int aliveN = aliveNeighbours(x, y, grid);
      boolean currentCell = grid[x][y];
      if (currentCell == DEAD && aliveN == 3){ newGrid[x][y] = ALIVE; }
      else if (currentCell == ALIVE && (aliveN == 2 || aliveN == 3)){ newGrid[x][y] = ALIVE; }
      else { newGrid[x][y] = DEAD; }
    }
  }
  return newGrid;
}

int[] neighbourXOffsets = {
                           -1, 0, 1,
                           -1,    1,
                           -1, 0, 1,
                          };
int[] neighbourYOffsets = {
                           -1, -1, -1,
                            0,      0,
                            1,  1,  1,
                          };

int aliveNeighbours(int x, int y, boolean[][] grid){
  int aliveNeighbours = 0;
  for (int i = 0; i < 8; i++){
    int xOffset = neighbourXOffsets[i];
    int yOffset = neighbourYOffsets[i];
    boolean neighbour;
    try { neighbour = grid[x + xOffset][y + yOffset]; }
    catch (ArrayIndexOutOfBoundsException e) { continue; }  // Values outside grid are considered dead
    if (neighbour != DEAD){ aliveNeighbours++; }
  }
  return aliveNeighbours;
}

boolean[][] initGrid(int width, int height){
  grid = new boolean[width][height];

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int randomNumber = int(random(2));
      if (randomNumber == 0) {
        grid[x][y] = DEAD;
      } else {
        grid[x][y] = ALIVE;
      }
    }
  }
  return grid;
}
