/* I pledge my honor that I have abided by the Stevens Honor System.
        Brandon Patton
 */
package Assignment2;

import java.awt.*;

public enum WeightPlateSize {
    SMALL_3KG, MEDIUM_5KG, LARGE_10KG;

    public static int getIndex(WeightPlateSize desiredWeight) {
        if (desiredWeight == SMALL_3KG){
            return 0;
        } else if (desiredWeight == MEDIUM_5KG){
            return 1;
        } else if (desiredWeight == LARGE_10KG){
            return 2;
        } else {
            return -1;
        }

    }
}
