color[][] grid;
color RED = color(255, 0, 0);
color GREEN = color(0, 255, 0);
color BLUE = color(0, 0, 255);
color BLACK = color(0, 0, 0);
int pixelSize = 10;
int gridSizeX;
int gridSizeY;


void setup() {
  size(1024, 768);
  gridSizeX = int(width / pixelSize);
  gridSizeY = int(width / pixelSize);

  grid = initGrid(gridSizeX, gridSizeY);

  hint(ENABLE_STROKE_PURE);
  strokeWeight(pixelSize);
  strokeCap(ROUND);
  noLoop();  // Run once and stop
}

void draw() {
  background(BLACK);
  
  for (int y = 0; y < gridSizeY; y++) {
    for (int x = 0; x < gridSizeX; x++) {
      int topLeftX = x * pixelSize;
      int topLeftY = y * pixelSize;
      float cellCenterX = topLeftX + pixelSize / 2;
      float cellCenterY = topLeftY + pixelSize / 2;
      // println("x: " + topLeftX);
      // println("y: " + topLeftY);
      // println();
      stroke(grid[x][y]);
      point(cellCenterX, cellCenterY);
    }
  }
}

color[][] initGrid(int width, int height){
  grid = new color[width][height];

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int randomNumber = int(random(2));
      if (randomNumber == 0) {
        grid[x][y] = BLACK;
      } else {
        grid[x][y] = GREEN;
      }
    }
  }

  return grid;
}