color[][] grid;
color RED = color(255, 0, 0);
color GREEN = color(0, 255, 0);
color BLUE = color(0, 0, 255);
color BLACK = color(0, 0, 0);
color ALIVE = GREEN;
color DEAD = BLACK;
int pixelSize;
int gridSizeX = 100;
int gridSizeY = 100;


void setup() {
  size(1000, 500);
  // Currently only supports "pixels" that have the same length and height
  pixelSize = width / gridSizeX;

  grid = initGrid(gridSizeX, gridSizeY);

  hint(ENABLE_STROKE_PURE);
  strokeWeight(pixelSize);
  strokeCap(ROUND);
  frameRate(5);
}

void draw() {
  background(BLACK);

  grid = processLife(grid);
  
  for (int y = 0; y < gridSizeY; y++) {
    for (int x = 0; x < gridSizeX; x++) {
      int topLeftX = x * pixelSize;
      int topLeftY = y * pixelSize;
      float cellCenterX = topLeftX + pixelSize / 2;
      float cellCenterY = topLeftY + pixelSize / 2;
      stroke(grid[x][y]);
      point(cellCenterX, cellCenterY);
    }
  }
}

color[][] processLife(color[][] grid){
  int gridWidth = grid.length;
  int gridHeight = grid[0].length;
  color[][] newGrid = new color[gridWidth][gridHeight];
  for (int y = 0; y < gridHeight; y++) {
    for (int x = 0; x < gridWidth; x++) {
      int aliveN = aliveNeighbours(x, y, grid);
      color currentCell = grid[x][y];
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

int aliveNeighbours(int x, int y, color[][] grid){
  int aliveNeighbours = 0;
  for (int i = 0; i < 8; i++){
    int xOffset = neighbourXOffsets[i];
    int yOffset = neighbourYOffsets[i];
    color neighbour;
    try { neighbour = grid[x + xOffset][y + yOffset]; }
    catch (ArrayIndexOutOfBoundsException e) { continue; }  // Values outside grid are considered dead
    if (neighbour != DEAD){ aliveNeighbours++; }
  }
  return aliveNeighbours;
}

color[][] initGrid(int width, int height){
  grid = new color[width][height];

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