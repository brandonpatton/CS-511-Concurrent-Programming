package hw1;

public class Swapper implements Runnable {
    private int offset;
    private Interval interval;
    private String content;
    private char[] buffer;

    public Swapper(Interval interval, String content, char[] buffer, int offset) {
        this.offset = offset;
        this.interval = interval;
        this.content = content;
        this.buffer = buffer;
    }

    @Override
    public void run() {
        // TODO: Implement me!
        //Writes the specified content into the buffer.
        for (int i = interval.getX(); i < interval.getY(); i++){
            buffer[i] = content.charAt(offset);
            offset += 1;
        }
    }
}