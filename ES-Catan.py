import numpy as np
import os
import csv
import subprocess

"""
Code for Evolutionary Strategy algorithm adapted from openAI
https://openai.com/blog/evolution-strategies/
"""

# Set these to your locations to run
NETLOGO_INSTALL_LOCATION = "/home/lucas/Downloads/NetLogo"
MODEL_LOCATION = "/home/lucas/Documents/cpsc565/CPSC565-Settlers/Catan.nlogo"
GENERATION_RESULTS_FILE = "Generation_Results.csv"

WRITE_FILE = "catanRunOutput.txt"
GENERATIONS = 100 # number of generations to run
FITNESS_RUNS = 10 # Number of runs in Netlogo per fitness evaluation
POPULATION = 10 # Population per Generation
sigma = 0.1 # noise standard deviation
alpha = 0.05 # learning rate



# Uses an Evolutionary Strategy to evolve weights that determine
# Where to build a settlement
def main():
  setupGenFile() 

  # start the optimization
  weights = np.random.randn(5) # our initial guess is random
  
  for i in range(GENERATIONS):
    w_fitness = fitness(weights)
    print('\n~~~~ Generation %d. weights: %s, avg VPoints: %f ~~~~' % 
            (i, str(weights), w_fitness))
    writeGen(i, weights, w_fitness)
    N = np.random.randn(POPULATION, 5) # Represents a Noise matrix to add to the the parent
    R = np.zeros(POPULATION) 

    for j in range(POPULATION):
      w_try = weights + sigma*N[j] # add small amount of noise to the parent 
      print("Testing fitness of child %d" % j)
      R[j] = fitness(w_try)

    # Standardize the rewards to get a gaussian distribution
    A = (R - np.mean(R)) / np.std(R) 
    # Update the weights
    # Alpha is the learning rate
    weights = weights + alpha/(POPULATION*sigma) * np.dot(N.T, A)


# Runs a Netlogo experiment to determine the effectiveness of these weights
# Returns the Average of the multiple runs with a set of weights
def fitness(weights):
    # write weights to the readfile
    writeNewSetup("setupfile.txt", weights) # Records the weights in a setupfile
    process = subprocess.Popen(     # Create a subprocess to run Netlogo headless
        ["bash", 
        "Run_netlogo_headless.sh", 
        NETLOGO_INSTALL_LOCATION, 
        MODEL_LOCATION, 
        "setupfile.txt",
        WRITE_FILE]) 
    process.wait()

    # Get the information from the runs
    # Average the performance of the runs
    avgVPoints = 0
    with open(WRITE_FILE, "r") as csvfile:
        reader = csv.reader(csvfile, delimiter=",")
        info = list(reader)
        runs = info[7:] 
        for row in runs:
            avgVPoints += int(row[-1])  # The last index contains the VPoints
    return (avgVPoints / len(runs))     # Return the Average



#Adds headers to the results file
def setupGenFile():
  with open(GENERATION_RESULTS_FILE, "w") as f:
    f.write("Gen, Wood,Brick,Wheat,Sheep,Distance,Fitness\n")


# Write the Generation to the file
def writeGen(gen, weights, fitness):
  with open(GENERATION_RESULTS_FILE, "a") as csvfile:
    writer = csv.writer(csvfile)
    info = [gen] + weights.tolist() + [fitness]
    writer.writerow(info)
  

# Create the Experiment file
def writeNewSetup(path, w):
  output = """<experiments>
  <experiment name="experiment4" repetitions="{5}" runMetricsEveryStep="false">
  <setup>setup</setup>
  <go>go</go>
  <timeLimit steps="100"/>
  <metric>rVPoints</metric>
  <enumeratedValueSet variable="woodWeight">
    <value value="{0}"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="brickWeight">
    <value value="{1}"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="wheatWeight">
    <value value="{2}"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="sheepWeight">
    <value value="{3}"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="distWeight">
    <value value="{4}"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="woodProbability">
    <value value="23"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="brickProbability">
    <value value="23"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="desertProbability">
    <value value="8"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="wheatProbability">
    <value value="23"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="sheepProbability">
    <value value="23"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="redYstart">
    <value value="1"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="boardSize">
    <value value="9"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="redXstart">
    <value value="-1"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="show-details?">
    <value value="false"/>
  </enumeratedValueSet>
  <enumeratedValueSet variable="show-value?">
    <value value="true"/>
  </enumeratedValueSet>
  </experiment>
  </experiments>""".format(w[0], w[1], w[2], w[3], w[4], FITNESS_RUNS)
#     output = """<experiments>
#    <experiment name="exp" repetitions="{5}" runMetricsEveryStep="false">
#     <setup>setup</setup>
#     <go>go</go>
#     <timeLimit steps="200"/>
#     <metric>rVPoints</metric>
#     <enumeratedValueSet variable="desertProbability">
#       <value value="8"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="sheepWeight">
#       <value value="{3}"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="redYstart">
#       <value value="1"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="brickWeight">
#       <value value="{1}"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="redXstart">
#       <value value="-1"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="boardSize">
#       <value value="9"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="woodProbability">
#       <value value="23"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="woodWeight">
#       <value value="{0}"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="sheepProbability">
#       <value value="23"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="distWeight">
#       <value value="{4}"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="brickProbability">
#       <value value="23"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="wheatWeight">
#       <value value="{2}"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="show-value?">
#       <value value="true"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="wheatProbability">
#       <value value="23"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="blueYstart">
#       <value value="0"/>
#     </enumeratedValueSet>
#     <enumeratedValueSet variable="blueXstart">
#       <value value="0"/>
#     </enumeratedValueSet>
#   </experiment>
# </experiments>""".format(w[0], w[1], w[2], w[3], w[4], FITNESS_RUNS)
  with open(path, "w") as f:
    f.write(output)


main()