import org.apache.commons.cli.*;

public class ArgumentParser {

    private final Options options;
    private CommandLine cmd;

    public ArgumentParser() {
        options = new Options();

        Option benchmarkMode = new Option("b", "benchmark", true, "Automatic benchmark mode");
        benchmarkMode.setRequired(false);
        options.addOption(benchmarkMode);

        Option runtime = new Option("r", "runtime", true, "Benchmark runtime in seconds");
        runtime.setRequired(false);
        options.addOption(runtime);

        Option fps = new Option("f", "fps", true, "Benchmark FPS cap");
        fps.setRequired(false);
        options.addOption(fps);
    }

    public boolean parse(String[] args) {
        CommandLineParser parser = new DefaultParser();
        try {
            cmd = parser.parse(options, args);
            return true;
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            printHelp();
            return false;
        }
    }

    public boolean isBenchmarkMode() {
        return cmd.hasOption("b");
    }

    public Integer getRuntime() {
        return Integer.valueOf(cmd.getOptionValue("r"));
    }

    public Integer getFPSCap() {
        return Integer.valueOf(cmd.getOptionValue("f"));
    }

    public void printHelp() {
        HelpFormatter formatter = new HelpFormatter();
        formatter.printHelp("Instanssi2024DemoKonso", options);
    }
}
