public class LifeGrid {
    // Two grid arrays that are reused
    private final boolean[] PRIMARY_GRID;
    private final boolean[] SECONDARY_GRID;
    private boolean[] currentGrid, newGrid;
    int width, height;
    final boolean ALIVE = true;
    final boolean DEAD = false;

    private final int[] neighbourXOffsets = {
            -1, 0, 1,
            -1,    1,
            -1, 0, 1,
    };
    private final int[] neighbourYOffsets = {
            -1, -1, -1,
             0,      0,
             1,  1,  1,
    };

    public LifeGrid(int width, int height) {
        this.width = width;
        this.height = height;
        PRIMARY_GRID = initGrid(width, height);
        SECONDARY_GRID = initGrid(width, height);
    }

    public void update(int frameCount){
        if (frameCount % 2 == 0){
            currentGrid = PRIMARY_GRID;
            newGrid = SECONDARY_GRID;
        } else {
            currentGrid = SECONDARY_GRID;
            newGrid = PRIMARY_GRID;
        }
        // processLife modifies newGrid
        processLife(currentGrid, newGrid);
    }

    /**
     * TODO: currently works properly ONLY if called AFTER update()
     * Always returns newGrid
     */
    public boolean[] getGrid(){
        return newGrid;
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


    boolean[] initGrid(int width, int height) {
        boolean[] newGrid = new boolean[width * height];

        for (int i = 0; i < newGrid.length; i++) {
            newGrid[i] = (i % 4 == 0) ? ALIVE : DEAD;
        }
        return newGrid;
    }
    boolean computeNewState(boolean currentState, int aliveNeighbours) {
        if (currentState == DEAD && aliveNeighbours == 3) return ALIVE;
        if (currentState == ALIVE && (aliveNeighbours == 2 || aliveNeighbours == 3)) return ALIVE;
        return DEAD;
    }

    int getAliveNeighbours(int x, int y, boolean[] grid) {
        int aliveNeighbours = 0;

        for (int i = 0; i < 8; i++) {
            int neighbourX = x + neighbourXOffsets[i];
            int neighbourY = y + neighbourYOffsets[i];

            if (
                    isInsideGrid(neighbourX, neighbourY) &&
                    grid[xyToIndex(neighbourX, neighbourY)] == ALIVE
            ) {
                aliveNeighbours++;
                if (aliveNeighbours >= 4) return aliveNeighbours;  // Optimize for game of life rules
            }
        }

        return aliveNeighbours;
    }

    boolean isInsideGrid(int x, int y) {
        return !(x < 0 || x >= width || y < 0 || y >= height);
    }

    public int xyToIndex(int x, int y) {
        return x * height + y;
    }

    public int indexToX(int index) {
        return index / height;
    }

    public int indexToY(int index, int x) {
        return index - (x * height);
    }

}
