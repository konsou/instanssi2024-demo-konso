import processing.core.*;

public class Instanssi2024DemoKonso extends PApplet{
    public int DRAW_STARTED_AT_MS = -1;
    public int DRAW_STARTED_AT_FRAMES = -1;


    Colors colors;
    LifeGrid grid;
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
        handleArguments(args);

        // Instantiate things here to measure loading time more accurately
        colors = new Colors();
        grid = new LifeGrid(settings.gridSizeX, settings.gridSizeY);

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

        grid.update(frameCount);

        // Draw to screen
        background(colors.BACKGROUND_COLOR);

        // TODO: think what to do with this
        // Separation of concerns point of view: do drawing here (but in a better way)
        // Performance point of view: do drawing in grid.update()
        boolean[] tempGrid = grid.getGrid();
        for (int i = 0; i < tempGrid.length; i++) {
            int x = grid.indexToX(i);
            int y = grid.indexToY(i, x);
            displayCell(x, y, tempGrid[i]);
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
