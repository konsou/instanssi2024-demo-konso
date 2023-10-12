import processing.core.*;

public class Instanssi2024DemoKonso extends PApplet{
    // Two grid arrays that are reused
    boolean[] PRIMARY_GRID;
    boolean[] SECONDARY_GRID;

    public int DRAW_STARTED_AT_MS = -1;
    public int DRAW_STARTED_AT_FRAMES = -1;


    Colors colors;
    // Instantiating Settings here since settings() needs it
    Settings settings = new Settings();

    public static void main(String[] args) {
        String[] appletArgs = new String[args.length + 1];
        appletArgs[0] = "Instanssi2024DemoKonso";
        System.arraycopy(args, 0, appletArgs, 1, args.length);
        PApplet.main(appletArgs);
    }

    @Override
    public void settings() {
        size(settings.SCREEN_WIDTH, settings.SCREEN_HEIGHT);
    }

    @Override
    public void setup() {
        // Instantiate things here to measure loading time more accurately
        colors = new Colors();

        handleArguments(args);

        PRIMARY_GRID = initGrid(settings.gridSizeX, settings.gridSizeY);
        SECONDARY_GRID = initGrid(settings.gridSizeX, settings.gridSizeY);

        hint(ENABLE_STROKE_PURE);
        strokeWeight(settings.pixelSize);
        strokeCap(ROUND);
        if (settings.BENCHMARK_MODE){ frameRate(settings.BENCHMARK_FPS_CAP); }
        else { frameRate(settings.FPS_CAP); }
    }

    @Override
    public void draw() {
        if (DRAW_STARTED_AT_MS == -1){ DRAW_STARTED_AT_MS = millis(); }
        if (DRAW_STARTED_AT_FRAMES == -1){ DRAW_STARTED_AT_FRAMES = frameCount; }
        if (settings.BENCHMARK_MODE && drawMillis() >= settings.BENCHMARK_RUNTIME_MS) { printBenchmarkStatsAndExit(); }

        background(colors.BACKGROUND_COLOR);

        boolean[] currentGrid, newGrid;

        if (frameCount % 2 == 0){
            currentGrid = PRIMARY_GRID;
            newGrid = SECONDARY_GRID;
        } else {
            currentGrid = SECONDARY_GRID;
            newGrid = PRIMARY_GRID;
        }

        // processLife modifies newGrid
        processLife(currentGrid, newGrid);

        for (int i = 0; i < newGrid.length; i++) {
            int x = indexToX(i);
            int y = indexToY(i, x);
            displayCell(x, y, newGrid[i]);
        }
    }

    void displayCell(int x, int y, boolean isAlive) {
        float cellCenterX = (x * settings.pixelSize) + ((float) settings.pixelSize / 2);
        float cellCenterY = (y * settings.pixelSize) + ((float) settings.pixelSize / 2);

        if (isAlive) {
            stroke(colors.randomAliveColor());
            point(cellCenterX, cellCenterY);
        }
    }

    /**
     * Processes the Game of Life logic on the provided current grid and writes the
     * results to the new grid. Both grids should be of the same size. The function
     * assumes that the `currentGrid` represents the current state of the Game of
     * Life, and it calculates the next state, writing it directly to the `newGrid`.
     * <p>
     * This function modifies the `newGrid` directly for performance reasons.
     *
     * @param currentGrid The current state of the Game of Life grid.
     * @param newGrid     An array where the next state of the Game of Life will be written.
     */
    void processLife(boolean[] currentGrid, boolean[] newGrid) {
        for (int i = 0; i < currentGrid.length; i++) {
            int x = indexToX(i);
            int y = indexToY(i, x);
            int aliveNeighbours = getAliveNeighbours(x, y, currentGrid);

            newGrid[i] = computeNewState(currentGrid[i], aliveNeighbours);
        }
    }

    boolean computeNewState(boolean currentState, int aliveNeighbours) {
        if (currentState == settings.DEAD && aliveNeighbours == 3) return settings.ALIVE;
        if (currentState == settings.ALIVE && (aliveNeighbours == 2 || aliveNeighbours == 3)) return settings.ALIVE;
        return settings.DEAD;
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

            if (
                    isInsideGrid(neighbourX, neighbourY) &&
                            grid[xyToIndex(neighbourX, neighbourY)] == settings.ALIVE
            ) {
                aliveNeighbours++;
                if (aliveNeighbours >= 4) return aliveNeighbours;  // Optimize for game of life rules
            }
        }

        return aliveNeighbours;
    }

    boolean isInsideGrid(int x, int y) {
        return !(x < 0 || x >= settings.gridSizeX || y < 0 || y >= settings.gridSizeY);
    }

    boolean[] initGrid(int width, int height) {
        boolean[] newGrid = new boolean[width * height];

        for (int i = 0; i < newGrid.length; i++) {
            newGrid[i] = (i % 4 == 0) ? settings.ALIVE : settings.DEAD;
        }

        return newGrid;
    }

    int xyToIndex(int x, int y) {
        return x * settings.gridSizeY + y;
    }

    int indexToX(int index) {
        return index / settings.gridSizeY;
    }

    int indexToY(int index, int x) {
        return index - (x * settings.gridSizeY);
    }

    /**
     * @return number of milliseconds since first call to draw()
     */
    int drawMillis(){ return millis() - DRAW_STARTED_AT_MS; }

    /**
     * @return frame count from the first draw() call, starting from 1
     */
    int drawFrameCount(){ return frameCount - DRAW_STARTED_AT_FRAMES + 1; }

    void printBenchmarkStatsAndExit(){
        int totalRuntime = millis();
        int drawRuntime = drawMillis();
        int setupRuntime = totalRuntime - drawRuntime;
        int drawFrameCount = drawFrameCount();
        float avgDrawFPS = (float) ((float) drawFrameCount / drawRuntime * 1000.0);
        println("Runtime (total):      " + totalRuntime + " ms");
        println("Runtime (setup):      " + setupRuntime + " ms");
        println("Runtime (draw):       " + drawRuntime + " ms");
        println("Frame count (total):  " + frameCount);
        println("Frame count (draw):   " + drawFrameCount());
        println("Average FPS (draw):   " + avgDrawFPS);
        exit();
    }

    void handleArguments(String[] args){
        ArgumentParser argParser = new ArgumentParser();

        if (argParser.parse(args)) {
            if (argParser.isBenchmarkMode()) {
                println("Automatic benchmark mode");
                settings.BENCHMARK_MODE = true;

                try {
                    settings.BENCHMARK_RUNTIME_MS = argParser.getRuntime() * 1000;
                    println("Setting benchmark runtime to " + settings.BENCHMARK_RUNTIME_MS / 1000 + " seconds");
                } catch (Exception e) {
                    println("Error: Benchmark runtime not set or invalid, exiting");
                    System.exit(1);
                }

                try {
                    settings.BENCHMARK_FPS_CAP = argParser.getFPSCap();
                    println("Setting FPS limit to " + settings.BENCHMARK_FPS_CAP);
                } catch (Exception e) {
                    println("Error: Benchmark FPS cap not set or invalid, exiting");
                    System.exit(1);
                }
            }
        } else {
            System.exit(1);
        }
    }
}
