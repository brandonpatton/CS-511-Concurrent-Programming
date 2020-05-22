/* I pledge my honor that I have abided by the Stevens Honor System.
        Brandon Patton
 */
package Assignment2;

public enum ApparatusType {
    LEGPRESSMACHINE, BARBELL, HACKSQUATMACHINE, LEGEXTENSIONMACHINE, LEGCURLMACHINE, LATPULLDOWNMACHINE, PECDECKMACHINE, CABLECROSSOVERMACHINE;

    public static int getIndex(ApparatusType appIndex) {
        for(int i = 0; i < ApparatusType.values().length; i++) {
            if(appIndex == ApparatusType.values()[i]) {
                return i;
            }
        }
        return -1;
    }
}