"""
Code for Evolutionary Strategy algorithm modified from openAI
https://openai.com/blog/evolution-strategies/
"""

import numpy as np
import csv
import subprocess
import concurrent.futures
NETLOGO_FILE_LOCATION = "C:\\Users\\lucas\Documents\\CPSC565\\CPSC565-Settlers\\Catan.nlogo"
EXPERIMENT = "somesetup.txt"
TEMP_WRITE_FILE = "catanRunOutput.txt"
# CATAN_READ_WEIGHTS_FILE = "C:\\Users\\lucas\\Documents\\CPSC565\\CPSC565-Settlers\\test_file_read.txt"




def writeNewSetup(path, w):
    output = """<experiments>
  <experiment name="experiment2" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>rVPoints</metric>
    <enumeratedValueSet variable="boardSize">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redYstart">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepWeight">
      <value value="{3}"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="desertProbability">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickWeight">
      <value value="{1}"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="redXstart">
      <value value="-5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="woodWeight">
      <value value="{0}"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sheepProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distWeight">
      <value value="{4}"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="brickProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatWeight">
      <value value="{2}"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-value?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wheatProbability">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueYstart">
      <value value="-7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blueXstart">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>""".format(w[0], w[1], w[2], w[3], w[4])
    with open(path, "w") as f:
        f.write(output)
    

def f(weights, index):
    
    # write weights to the readfile
    writeNewSetup("setupfile{0}.txt".format(str(index)), weights)


    process = subprocess.Popen(["netlogo-headless.bat", "--model", NETLOGO_FILE_LOCATION, "--setup-file", "setupfile{0}.txt".format(str(index)), "--table", str(index) + TEMP_WRITE_FILE])
    process.wait()

    # find the fitness from the run
    avgVPoints = 0
    with open(str(index)+TEMP_WRITE_FILE, "r") as csvfile:
        reader = csv.reader(csvfile, delimiter=",")

        info = list(reader)
        runs = info[7:]
        
        for row in runs:
            avgVPoints += int(row[-1])
    return avgVPoints/100



#   reward = -np.sum(np.square(solution - w))
#   return reward

# hyperparameters
npop = 10 # population size
sigma = 0.1 # noise standard deviation
alpha = 0.001 # learning rate

# start the optimization
# solution = np.array([0.5, 0.1, -0.3, 0.8, -.5])
w = np.random.randn(5) # our initial guess is random
executor = concurrent.futures.ThreadPoolExecutor()

for i in range(20):
  if i % 2 == 0:
    print('iter %d. weights: %s, avg VPoints: %f' % 
          (i, str(w), f(w, -1)))
  N = np.random.randn(npop, 5) # samples from a normal distribution N(0,1)
  R = np.zeros(npop)
  print("starting gen eval")
  for j in range(npop):
    w_try = w + sigma*N[j] # jitter w using gaussian of sigma 0.1
    future = executor.submit(f, w_try, j)
    R[j] = future.result()
    # print(w_try)
    R[j] = f(w_try, j) # evaluate the jittered version
  A = (R - np.mean(R)) / np.std(R)
  w = w + alpha/(npop*sigma) * np.dot(N.T, A)
  print("done gen eval")

