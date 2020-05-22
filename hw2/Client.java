/* I pledge my honor that I have abided by the Stevens Honor System.
        Brandon Patton
 */
package Assignment2;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

public class Client {
    private int id;
    private List<Exercise> routine;

    public Client(int id) {
        this.id = id;
        this.routine = new ArrayList<Exercise>();
        Exercise e = Exercise.generateRandom();
        addExercise(e);

    }


    public void addExercise(Exercise e) {
        addHelp(e, this.routine);
    }

    public void addHelp(Exercise e, List<Exercise> routine) {
        List<Exercise> staging = new ArrayList<Exercise>();
        Random rand = new Random();
        int r = rand.nextInt(6);
        for(int i = 0; i <= 15 + r; i++) {
            Exercise exercise = Exercise.generateRandom();
            staging.add(e);
        }
        this.routine.addAll(staging);

    }

    public List<Exercise> getRoutine() {
        return this.routine;
    }

    public static Client generateRandom(int id) {
        Client c = new Client(id);
        return c;
    }


}
