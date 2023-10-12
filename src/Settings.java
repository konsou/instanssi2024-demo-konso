public class Settings {
    // Display
    public final int SCREEN_WIDTH = 1920;
    public final int SCREEN_HEIGHT = 1080;
    public final double HALF_WIDTH = SCREEN_WIDTH / 2.0;
    public final double HALF_HEIGHT = SCREEN_HEIGHT / 2.0;

    // Benchmarking
    public boolean BENCHMARK_MODE = true;
    public int BENCHMARK_RUNTIME_MS = 10000;
    public int FPS_CAP = 60;
    public int BENCHMARK_FPS_CAP = 999;

    public final boolean ALIVE = true;
    public final boolean DEAD = false;

    // Grid size
    public int gridSizeX = 192;
    public int gridSizeY = 108;
    // Only supports "pixels" that have the same length and height
    public int pixelSize = SCREEN_WIDTH / gridSizeX;
    public int gridCellCount = gridSizeX * gridSizeY;

    // TODO: Camera control
    public double CAMERA_DEFAULT_Z;
    // CAMERA_DEFAULT_Z = (height/2.0) / tan(PI*30.0 / 180.0);

}
