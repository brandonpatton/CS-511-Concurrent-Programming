/* I pledge my honor that I have abided by the Stevens Honor System.
        Brandon Patton
 */
package Assignment2;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class Exercise {

    private ApparatusType at;
    private Map<WeightPlateSize,Integer> weight;
    private int duration;

    public Exercise(ApparatusType at, Map<WeightPlateSize,Integer> weight, int duration) {
        this.at = at;
        this.weight = weight;
        this.duration = duration;
    }

    public static Exercise generateRandom() {
        Random rand = new Random();
        int a = rand.nextInt(8);
        int wps = rand.nextInt(3);
        int plates;

       Map<WeightPlateSize,Integer> weight = new HashMap<WeightPlateSize, Integer>();
       for (int i = 0; i < WeightPlateSize.values().length; i++){
           weight.put(WeightPlateSize.values()[i], rand.nextInt(11));
       }
       int sum = 0;
       for (int currWeight : weight.values()) {
           sum += currWeight;
       }

       if (sum == 0){
           weight.replace(WeightPlateSize.values()[rand.nextInt(WeightPlateSize.values().length)], rand.nextInt(10) + 1);
       }


        Exercise e = new Exercise(ApparatusType.values()[a], weight, 10);
        return e;
    }

    public ApparatusType getApparatus() {
        return this.at;
    }

    public Map<WeightPlateSize,Integer> getMap() {
        return this.weight;
    }

    public int getDuration() {
        return this.duration;
    }

}
