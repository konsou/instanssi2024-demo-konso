import java.util.Random;

public class Colors {
    // Palette
    public final int MAIN_COLOR_GREEN = color(48, 178, 71);
    public final int LIGHTER_GREEN = color(96, 255, 124);
    public final int DARKER_GREEN = color(0, 100, 17);
    public final int ALMOST_BLACK = color(39, 39, 39);
    public final int ALMOST_WHITE = color(240, 240, 240);

    final int[] ALIVE_COLORS = { LIGHTER_GREEN, MAIN_COLOR_GREEN, DARKER_GREEN};
    final int[] ALIVE_COLOR_WEIGHTS = { 5, 1, 0 };
    int[] weightedAliveColors = constructWeightedColors(ALIVE_COLORS, ALIVE_COLOR_WEIGHTS);

    public final int DEAD_COLOR = ALMOST_BLACK;
    public final int BACKGROUND_COLOR = ALMOST_BLACK;

    private static final Random rand = new Random();

    public int randomAliveColor() {
        return weightedAliveColors[(randomInt(weightedAliveColors.length))];
    }

    public static int color(int r, int g, int b) {
        return (255 << 24) | (r << 16) | (g << 8) | b;
    }

    public static int randomInt(int upperBound) {
        return rand.nextInt(upperBound);
    }

    int[] constructWeightedColors(int[] colors, int[] weights) {
        int totalWeights = 0;
        for (int weight : weights) {
            totalWeights += weight;
        }

        int[] result = new int[totalWeights];
        int currentIndex = 0;

        for (int i = 0; i < colors.length; i++) {
            int end = currentIndex + weights[i];
            while (currentIndex < end) {
                result[currentIndex] = colors[i];
                currentIndex++;
            }
        }
        return result;
    }
}
