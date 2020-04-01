import random
import copy

POOL_SIZE = 150 
ELITE_SURVIVAL = 6
MUTATE_CHANCE = 0.1
EVAL_AVERAGE_NUM = 20
ROULETTE_FACTOR = 0.3
ACTIONS = ["UP", "RIGHT", "DOWN", "LEFT", "FIX", "WAIT", "RAN"]
FIX_BROKEN_BONUS = 10
FIX_UNBROKEN_PENALTY = -1
FALL_OFF_PENALTY = -5

######

def recursiveGene(x):
    if x == 0:
        return [[]]
    l = recursiveGene(x-1)
    new = []
    for item in l:
        temp = item.copy()
        temp2 = item.copy()
        temp.append("X")
        new.append(temp)
        temp2.append("O")
        new.append(temp2)
    return new


## returns an empty list with all the genome strings

def createBlankGenome():
    genes = []
    ## Create the normal genes
    normal = recursiveGene(5)
    for item in normal:
        genes.append(item)
    ## Create the genes next to walls but not in the corners
    for i in range(0,4):
        nWall = recursiveGene(4)
        for item in nWall:
            item.insert(i, "*")
            genes.append(item)
    ## Create the genes in the corners
    neCorner = recursiveGene(3)
    for item in neCorner:
        item.insert(0,"*")
        item.insert(1,"*")
        genes.append(item)
    seCorner = recursiveGene(3)
    for item in seCorner:
        item.insert(1,"*")
        item.insert(2,"*")
        genes.append(item)
    swCorner = recursiveGene(3)
    for item in swCorner:
        item.insert(2,"*")
        item.insert(3,"*")
        genes.append(item)
    nwCorner = recursiveGene(3)
    for item in nwCorner:
        item.insert(0,"*")
        item.insert(3,"*")
        genes.append(item)

    return convertListToString(genes)


## returns a dictionary of environment action pairs
def randomFillGenome():
    genes = createBlankGenome()
    genome = {}
    for gene in genes:
        genome[gene] = random.choice(ACTIONS)
    return genome
    

def convertListToString(l):
    newList = []
    for item in l:
        st = ""
        for letter in item:
            st = st + letter
        newList.append(st)
    return newList


#####################


class Fountain:
    def __init__(self):
        self.map = self.createMap()  # is a class variable for convenience
        self.robotPos = (1,1)       # is a class variable for convenience

    # Creates a random map
    def evaluate(self, robot):
        finalFitness = 0
        for i in range(EVAL_AVERAGE_NUM):
            fitness = 0                     # Reset the fitness
            self.robotPos = (1,1)           # Reset the robotPosition
            self.map = self.createMap()     # Create a new Map

            for j in range(0,200):         # 200 is the number of actions a robot can take
                x, y = self.robotPos
                env = self.getEnvironment()
                action = robot.getAction(env)
                # self.printState(action, fitness)               
            
                fitness += self.applyAction(action)
            # print(i)
            # print(j)
            # input("Press a key....")
            finalFitness += fitness
        finalFitness /= EVAL_AVERAGE_NUM    # Get the average of the runs
        return finalFitness


    # For debugging
    def printState(self, action, fitness):
        m = copy.deepcopy(self.map)
        x, y = self.robotPos
        m[y][x] = "R"
        for line in m:
            print(line)
        print()
        print(self.robotPos)
        print(action)
        print(fitness)

    # Applies the effect of the rule
    def applyAction(self,action):
        if action == "UP":
            return self.up()
        elif action == "RIGHT":
            return self.right()
        elif action == "DOWN":
            return self.down()
        elif action == "LEFT":
            return self.left()
        elif action == "FIX":
            return self.fix()
        elif action == "RAN":
            return self.randomMove()
        elif action == "WAIT":
            return 0

    def up(self):
        x,y = self.robotPos
        if y == 1:
            return FALL_OFF_PENALTY
        self.robotPos = (x,y-1)
        return 0

    def right(self):
        x,y = self.robotPos
        if x == 10:
            return FALL_OFF_PENALTY
        self.robotPos = (x+1,y)
        return 0

    def down(self):
        x,y = self.robotPos
        if y == 10:
            return FALL_OFF_PENALTY
        self.robotPos = (x,y+1)
        return 0

    def left(self):
        x,y = self.robotPos
        if x == 1:
            return FALL_OFF_PENALTY
        self.robotPos = (x-1,y)
        return 0

    def fix(self):
        x,y = self.robotPos
        if self.map[y][x] == "X":
            self.map[y][x] = "O"
            return FIX_BROKEN_BONUS
        elif self.map[y][x] == "O":
            return FIX_UNBROKEN_PENALTY
    
    def randomMove(self):
        x = random.randint(0,3)
        if x == 0: return self.up()
        if x == 1: return self.right()
        if x == 2: return self.down()
        if x == 3: return self.left()
        print("ERROR IN RANDOM MOVE")

    # Creates a random fountain map
    def createMap(self):
        map = []
        border = []
        for i in range(0,12):
            border.append("*")  # Stars represent the "off the edge" tiles
        map.append(border)

        for i in range(0,10):
            row = []
            row.append("*")
            for j in range(0,10):
                num = random.randint(0,1)
                if (num == 0):
                    row.append("O")     # Fixed Tile
                else:
                    row.append("X")     # Broken Tile
            row.append("*")
            map.append(row)
        map.append(border)
        return map


    def getEnvironment(self):       # Returns an ordered string representing Tilly's current environment
        x, y = self.robotPos
        env = ""
        env += self.map[y-1][y]  #up
        env += self.map[y][x+1]  #right
        env += self.map[y+1][x]  #down
        env += self.map[y][x-1]  #left
        env += self.map[y][x]    #in place
        return env


class Robot:
    def __init__(self, genome):
        self.genome = genome
        self.fitness = 0
        self.possibleEnvs = createBlankGenome() # Used as a static ordered list
        

    def getAction(self, env):
        return self.genome[env]

    #### This was an attempt at crossover by randomly taking genes from either parent
    # def crossover(self, mate):
    #     newGenome = {}
    #     for env in self.possibleEnvs:
    #         if random.randint(0,1) == 0:
    #             newGenome[env] = self.getAction(env)    # Take from parent 1
    #         else:
    #             newGenome[env] = mate.getAction(env)
    #     return Robot(newGenome)
    


    # Creates two children, each opposite from the other in what it takes from the parents
    def crossover(self, mate):
        split1 = random.randrange(0,128)
        split2 = random.randrange(0,128)
        # print("split 1: {0} | split 2: {1}".format(split1,split2))
        
        newGenome1 = {}
        newGenome2 = {}
        for i in range(0,128):
            if i <= min(split1, split2):        # Left of split point 
                env = self.possibleEnvs[i]
                action1 = self.getAction(env)   # parent 1 to child 1
                newGenome1[env] = action1

                action2 = mate.getAction(env)    # parent 2 to child 2
                newGenome2[env] = action2

            elif min(split1, split2) < i and i < max(split1, split2): # Inside split point
                env = self.possibleEnvs[i]
                action1 = mate.getAction(env)   # parent 2 to child 1
                newGenome1[env] = action1

                action2 = self.getAction(env)   # parent 1 to child 2
                newGenome2[env] = action2

            elif max(split1, split2) <= i:      # Right or split point
                env = self.possibleEnvs[i]
                action1 = self.getAction(env)    # parent 1 to child 1
                newGenome1[env] = action1

                action2 = mate.getAction(env)   # parent 2 to child 2
                newGenome2[env] = action2
        return Robot(newGenome1), Robot(newGenome2)


    def mutate(self):
        i = 0
        # print("starting mutations")
        for env in self.possibleEnvs:
            if random.uniform(0,1) < MUTATE_CHANCE:
                i += 1
                # print("MUTATING")
                action = random.choice(ACTIONS)
                self.genome[env] = action
                # print("Mutating: {0} -> {1}".format(env, action))
        # print(i)
               


class GenePool:
    def __init__(self, robots):
        self.robots = robots
        self.fountain = Fountain()
        self.weights = [1]
        for i in range(1, len(robots)):
            self.weights.append(self.weights[i-1] * ROULETTE_FACTOR)
        self.best = self.test()
        self.nth = self.robots[ELITE_SURVIVAL]
        self.worst = robots[-1]
        

    def select_parents(self,num=2):
        return random.choices(self.robots,self.weights, k=num)

    # Test all except the elite that carry between generations
    def test(self):
        for i in range(POOL_SIZE):
            robot = self.robots[i]
            robot.fitness = self.fountain.evaluate(robot)
        self.robots.sort(key = lambda x: x.fitness, reverse = True) # Reverse = true to sort in decending order
        return self.robots[0]


    def nextGen(self):
        robots = self.robots[:ELITE_SURVIVAL]       # We keep some of the best and add new ones to fill up the rest
        while (len(robots) < POOL_SIZE):   # Fill the pool up with many new child robots
            parent1, parent2 = self.select_parents()
            child1, child2 = parent1.crossover(parent2)
            child1.mutate()
            child2.mutate()
            robots.append(child1)
            robots.append(child2)
        return GenePool(robots)



# Convert the genome to integers and write it to a .txt
def writeToFile(genome, path):
    with open(path, "w") as f:
        for allele in genome:
            output = allele.replace("O", "0 ").replace("X", "1 ").replace("*", "2 ")
        
            action = genome[allele]
        
            if action == "UP":
                output += "1"
            elif action == "RIGHT":
                output += "2"
            elif action == "DOWN":
                output += "3"
            elif action == "LEFT":
                output += "4"
            elif action == "FIX":
                output += "5"
            elif action == "WAIT":
                output += "6"
            elif action == "RAN":
                output += "7"


            f.write(output +"\n") 


def main():
    robots = []
    for i in range(0, POOL_SIZE):
        genome = randomFillGenome()
        r = Robot(genome)
        robots.append(r)
    pool = GenePool(robots)
    generation = 0
    currentBest = 0
    while (True):
        currentBest = pool.best.fitness
        nth = pool.nth.fitness
        avg = 0
        for r in pool.robots:
            avg += r.fitness
        avg = avg/POOL_SIZE
        worst = pool.worst.fitness
        print("Gen: {0} | currentBest {1}| {5}th best {2} | worst {3} | average {4}".format(generation, currentBest, nth, worst, avg, ELITE_SURVIVAL))

        # for robot in pool.robots:
        #     print(robot.fitness)
        if generation%400 == 0:
            writeToFile(pool.best.genome, "/home/lucas/Documents/cpsc565/assignment3/Gen{0} - {1}.txt".format(generation, currentBest))
        pool = pool.nextGen()
        generation += 1

    
if __name__ == "__main__":
    main()
