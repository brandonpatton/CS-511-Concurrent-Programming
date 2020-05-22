package hw1;

import java.io.*;
import java.util.*;

public class TextSwap {

    private static String readFile(String filename) throws Exception {
        String line;
        StringBuilder buffer = new StringBuilder();
        File file = new File(filename);
        BufferedReader br = new BufferedReader(new FileReader(file));
        while ((line = br.readLine()) != null) {
            buffer.append(line);
        }
        br.close();
        return buffer.toString();
    }

    private static Interval[] getIntervals(int numChunks, int chunkSize) {
        // TODO: Implement me!
        //Returns an array of intervals.
        int chunkBump = 0;
        Interval[] intervalArray = new Interval[numChunks];
        for (int i = 0; i < numChunks; i++) {
            intervalArray[i] = new Interval(chunkBump, (chunkSize) + chunkBump);
            chunkBump += chunkSize;
        }
        return intervalArray;
    }

    private static List<Character> getLabels(int numChunks) {
        Scanner scanner = new Scanner(System.in);
        List<Character> labels = new ArrayList<Character>();
        int endChar = numChunks == 0 ? 'a' : 'a' + numChunks - 1;
        System.out.printf("Input %d character(s) (\'%c\' - \'%c\') for the pattern.\n", numChunks, 'a', endChar);
        for (int i = 0; i < numChunks; i++) {
            labels.add(scanner.next().charAt(0));
        }
        scanner.close();
        // System.out.println(labels);
        return labels;
    }

    private static char[] runSwapper(String content, int chunkSize, int numChunks) {
        // TODO: Order the intervals properly, then run the Swapper instances.
        //runSwapper creates the intervals, runs the Swapper threads, and returns the reordered buffer that will be written to the new file.
        List<Character> labels = getLabels(numChunks);
        Interval[] intervals = getIntervals(numChunks, chunkSize);
        char[] buff = new char[content.length()];
        List<Thread> threadList = new ArrayList<>(numChunks);
        for(int i = 0; i < numChunks; i++){
            threadList.add(new Thread(new Swapper(intervals[i], content, buff, (labels.get(i) - 'a')*chunkSize)));
            threadList.get(i).start();
        }
        for (int i = 0; i < numChunks; i++){
            try {
                threadList.get(i).join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        return buff;
    }

    private static void writeToFile(String contents, int chunkSize, int numChunks) throws Exception {
        char[] buff = runSwapper(contents, chunkSize, contents.length() / chunkSize);
        PrintWriter writer = new PrintWriter("output.txt", "UTF-8");
        writer.print(buff);
        writer.close();
    }

    public static void main(String[] args) {
        if (args.length != 2) {
            System.out.println("Usage: java TextSwap <chunk size> <filename>");
            return;
        }
        String contents = "";
        int chunkSize = Integer.parseInt(args[0]);

        try {
            contents = readFile(args[1]);
            System.out.println(Arrays.toString(getIntervals(contents.length()/chunkSize, chunkSize)));

            if (contents.length()/chunkSize > 26) {
                System.out.println("Error: Chunk size too small");
            }
            if (contents.length()%chunkSize > 0) {
                System.out.println("Error: File Size must be a multiple of the chunk size");
            }
            writeToFile(contents, chunkSize, contents.length() / chunkSize);

        } catch (FileNotFoundException e) {
            System.out.println("Error: File not found.");

        } catch (Exception e) {
            System.out.println("Error with IO.");
            return;
        }




    }
}
