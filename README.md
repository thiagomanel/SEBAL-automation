# SEBAL-automation
Experiments for the SAPS automation paper

This experiment aims to check how the service adapts to variations on the available storage resources.

Our scenario is the following:

1. We have three SAPS sites. One management site and two processing sites. The management site deploys the Archiver, the TaskCatalog, the GUI and the Scheduler. Both the processing site deploys the a crawler and worker resources.
2. We perform a long run experiment (e.g 3 days)
3. We submit a not-seen-before dataset
4. We observe:
	4.1 average throughut (images per unit of time)
	4.2 third stage average throughput (images per unit of time)
	4.3 fraction of used temporary storage
	4.4 fraction of used VMs
5. We control the amount of free temporay space (e.g by allocating/deallocating a big file in the temporary storage)

CODE ORGANIZATION

bin/ - script to run the experiments
data/ - experiment output
