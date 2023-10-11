boolean[] grid;
final boolean BENCHMARK_MODE = true;
final int BENCHMARK_RUNTIME_MS = 10000;

final boolean ALIVE = true;
final boolean DEAD = false;

// Palette
final color MAIN_COLOR_GREEN = color(48, 178, 71);
final color LIGHTER_GREEN = color(96, 255, 124);
final color DARKER_GREEN = color(0, 100, 17);
final color ALMOST_BLACK = color(39, 39, 39);
final color ALMOST_WHITE = color(240, 240, 240);

final color ALIVE_COLOR = LIGHTER_GREEN;
final color DEAD_COLOR = ALMOST_BLACK;
final color BACKGROUND_COLOR = ALMOST_BLACK;

final color[] ALIVE_COLORS = { LIGHTER_GREEN, MAIN_COLOR_GREEN, DARKER_GREEN};
final int[] ALIVE_COLOR_WEIGHTS = { 5, 1, 1 };

color[] weightedAliveColors;

int pixelSize;
int gridSizeX = 192;
int gridSizeY = 108;
int gridCellCount = gridSizeX * gridSizeY;

float HALF_WIDTH;
float HALF_HEIGHT;
float CAMERA_DEFAULT_Z;

void setup() {
  size(1920, 1080);
  HALF_WIDTH = width / 2;
  HALF_HEIGHT = height / 2;
  CAMERA_DEFAULT_Z = (height/2.0) / tan(PI*30.0 / 180.0);

  weightedAliveColors = constructWeightedColors(ALIVE_COLORS, ALIVE_COLOR_WEIGHTS);

  // Only supports "pixels" that have the same length and height
  pixelSize = width / gridSizeX;
  grid = initGrid(gridSizeX, gridSizeY);

  hint(ENABLE_STROKE_PURE);
  strokeWeight(pixelSize);
  strokeCap(ROUND);
  frameRate(10);
}

void draw() {
  if (BENCHMARK_MODE && millis() > BENCHMARK_RUNTIME_MS) {
    float avgFPS = float(frameCount) / float(millis()) * 1000.0;
    println("Ran for " + BENCHMARK_RUNTIME_MS + " ms, Frame Count: " + frameCount + " avg FPS: " + avgFPS);
    exit();
  }
  camera(
    frameCount % 100, HALF_HEIGHT, CAMERA_DEFAULT_Z, 
    HALF_WIDTH, HALF_HEIGHT, 0,
    0, 1, 0
    );

  background(BACKGROUND_COLOR);
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
    stroke(randomAliveColor());
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

color[] constructWeightedColors(color[] colors, int[] weights) {
    int totalWeights = 0;
    for (int weight : weights) {
        totalWeights += weight;
    }
    
    color[] result = new color[totalWeights];
    int currentIndex = 0;

    for (int i = 0; i < colors.length; i++) {
        for (int j = 0; j < weights[i]; j++) {
            result[currentIndex++] = colors[i];
        }
    }
    
    return result;
}

color randomAliveColor() {
  return weightedAliveColors[int(random(weightedAliveColors.length))];
}