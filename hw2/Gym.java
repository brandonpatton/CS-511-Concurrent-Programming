/* I pledge my honor that I have abided by the Stevens Honor System.
        Brandon Patton
 */
package Assignment2;

import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class Gym implements Runnable {
    private static final int GYM_SIZE = 30;
    private static final int GYM_REGISTERED_CLIENTS = 10000;
    private Map<WeightPlateSize,Integer> noOfWeightPlates = new HashMap<WeightPlateSize, Integer>();
    private Set<Integer> clients = new HashSet<Integer>();
    private ExecutorService executor;

    Semaphore[] machines = new Semaphore[] {new Semaphore(5), new Semaphore(5), new Semaphore(5), new Semaphore(5), new Semaphore(5), new Semaphore(5), new Semaphore(5), new Semaphore(5)};
    Semaphore weightRackMutex = new Semaphore(1);
    Semaphore[] plates = new Semaphore[] {new Semaphore(110), new Semaphore(90), new Semaphore(75)};

    public Gym() {
        this.noOfWeightPlates.put(WeightPlateSize.SMALL_3KG, 110);
        this.noOfWeightPlates.put(WeightPlateSize.MEDIUM_5KG, 90);
        this.noOfWeightPlates.put(WeightPlateSize.LARGE_10KG, 75);
        Random rand = new Random();
        for(int i = 0; i < 10000; i++) {
            int id = rand.nextInt(10000);
                if (this.clients.contains(id)) {
                    i--;
                } else {
                    this.clients.add(id);
                    Client c = Client.generateRandom(id);
                    List<Exercise> routine = c.getRoutine();

                }
        }
    }

    ExecutorService executorService = Executors.newFixedThreadPool(30);

    public void run() {
        for(int p = 0; p < 10000; p++) {
            int finalP = p;

            executorService.execute(new Runnable() {
                public void run() {
                    Client c = Client.generateRandom(finalP);
                    for (Exercise exercise : c.getRoutine()) {
                        ApparatusType apparatus = exercise.getApparatus();
                        int indexApparatus = ApparatusType.getIndex(apparatus);
                        Map<WeightPlateSize, Integer> mappy = exercise.getMap();
                        boolean ready = false;

                        while(machines[indexApparatus].availablePermits() > 0
                                && mappy.get(WeightPlateSize.SMALL_3KG) <= plates[0].availablePermits()
                                && mappy.get(WeightPlateSize.MEDIUM_5KG) <= plates[1].availablePermits()
                                && mappy.get(WeightPlateSize.LARGE_10KG) <= plates[2].availablePermits()) {
                            ready = true;

                            try {
                                weightRackMutex.acquire();
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }

                            try {
                                machines[indexApparatus].acquire();
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }


                            for (Map.Entry<WeightPlateSize, Integer> val : mappy.entrySet()) {
                                int indexWeightPlate = WeightPlateSize.getIndex(val.getKey());

                                for (int i = 0; i < val.getValue(); i++) {
                                    try {
                                        plates[indexWeightPlate].acquire();
                                    } catch (InterruptedException e) {
                                        e.printStackTrace();
                                    }
                                }
                            }
                            weightRackMutex.release();


                            int duration = exercise.getDuration();
                            System.out.println(finalP + " Beginning exercise with " + ApparatusType.values()[indexApparatus] + " " + machines[indexApparatus].availablePermits() + " left and " + mappy);
                            try {
                                TimeUnit.MILLISECONDS.sleep(10);
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }
                            System.out.println(finalP + " Ending exercise with " + ApparatusType.values()[indexApparatus] + " " + machines[indexApparatus].availablePermits() + " left and " + mappy);
                            break;
                        }
                        if(ready) {
                            machines[indexApparatus].release();
                            for (Map.Entry<WeightPlateSize, Integer> val : mappy.entrySet()) {
                                int indexWeightPlate = WeightPlateSize.getIndex(val.getKey());
                                for (int i = 0; i < val.getValue(); i++) {
                                    plates[indexWeightPlate].release();
                                }

                            }
                        }
                    }

                }
            });
        }
        executorService.shutdown();
    }
}