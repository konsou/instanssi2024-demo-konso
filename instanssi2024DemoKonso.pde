boolean[] grid;
final boolean BENCHMARK_MODE = true;
final int BENCHMARK_RUNTIME_MS = 10000;

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
int gridCellCount = gridSizeX * gridSizeY;

void setup() {
  size(1920, 1080);
  // Only supports "pixels" that have the same length and height
  pixelSize = width / gridSizeX;
  grid = initGrid(gridSizeX, gridSizeY);

  hint(ENABLE_STROKE_PURE);
  strokeWeight(pixelSize);
  strokeCap(ROUND);
  frameRate(999);
}

void draw() {
  if (BENCHMARK_MODE && millis() > BENCHMARK_RUNTIME_MS) {
    float avgFPS = float(frameCount) / float(millis()) * 1000.0;
    println("Ran for " + BENCHMARK_RUNTIME_MS + " ms, Frame Count: " + frameCount + " avg FPS: " + avgFPS);
    exit();
  }

  background(BLACK);
  grid = processLife(grid);
  
  for (int i = 0; i < gridCellCount; i++) {
    int x = indexToX(i);
    int y = indexToY(i, x);
    displayCell(x, y, grid[i]);
  }
}

void displayCell(int x, int y, boolean isAlive) {
  float cellCenterX = (x * pixelSize) + (pixelSize / 2);
  float cellCenterY = (y * pixelSize) + (pixelSize / 2);

  if (isAlive) {
    stroke(ALIVE_COLOR);
    point(cellCenterX, cellCenterY);
  }
}

boolean[] processLife(boolean[] currentGrid) {
  boolean[] newGrid = new boolean[gridCellCount];
  
  for (int i = 0; i < gridCellCount; i++) {
    int x = indexToX(i);
    int y = indexToY(i, x);
    int aliveNeighbours = getAliveNeighbours(x, y, currentGrid);
    
    newGrid[i] = computeNewState(currentGrid[i], aliveNeighbours);
  }

  return newGrid;
}

boolean computeNewState(boolean currentState, int aliveNeighbours) {
  if (currentState == DEAD && aliveNeighbours == 3) return ALIVE;
  if (currentState == ALIVE && (aliveNeighbours == 2 || aliveNeighbours == 3)) return ALIVE;
  return DEAD;
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

int getAliveNeighbours(int x, int y, boolean[] grid) {
  int aliveNeighbours = 0;
  
  for (int i = 0; i < 8; i++) {
    int neighbourX = x + neighbourXOffsets[i];
    int neighbourY = y + neighbourYOffsets[i];
    
    if (isInsideGrid(neighbourX, neighbourY) && grid[xyToIndex(neighbourX, neighbourY)] == ALIVE) {
      aliveNeighbours++;
      if (aliveNeighbours >= 4) return aliveNeighbours;  // Optimize for game of life rules
    }
  }

  return aliveNeighbours;
}

boolean isInsideGrid(int x, int y) {
  return !(x < 0 || x >= gridSizeX || y < 0 || y >= gridSizeY);
}

boolean[] initGrid(int width, int height) {
  boolean[] newGrid = new boolean[width * height];
  
  for (int i = 0; i < gridCellCount; i++) {
    newGrid[i] = (i % 4 == 0) ? ALIVE : DEAD;
  }

  return newGrid;
}

int xyToIndex(int x, int y) {
  return x * gridSizeY + y;
}

int indexToX(int index) {
  return index / gridSizeY;
}

int indexToY(int index, int x) {
  return index - (x * gridSizeY);
}
