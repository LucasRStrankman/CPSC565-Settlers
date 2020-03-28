import random
import copy

POOL_SIZE = 10
MUTATE_CHANCE = 0.3
ROULETTE_FACTOR = 0.6
ACTIONS = ["UP", "RIGHT", "DOWN", "LEFT", "FIX", "RAN", "WAIT"]
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
    for i in range(1,5):
        nWall = recursiveGene(4)
        for item in nWall:
            item.insert(i, "*")
            genes.append(item)
    ## Create the genes in the corners
    neCorner = recursiveGene(3)
    for item in neCorner:
        item.insert(1,"*")
        item.insert(2,"*")
        genes.append(item)
    seCorner = recursiveGene(3)
    for item in seCorner:
        item.insert(2,"*")
        item.insert(3,"*")
        genes.append(item)
    swCorner = recursiveGene(3)
    for item in swCorner:
        item.insert(3,"*")
        item.insert(4,"*")
        genes.append(item)
    nwCorner = recursiveGene(3)
    for item in nwCorner:
        item.insert(4,"*")
        item.insert(1,"*")
        genes.append(item)

    return convertListToString(genes)


## returns a dictionary of environment action pairs
def randomFillGenome():
    genes = createBlankGenome()
    genome = {}
    for gene in genes:
        action = random.choice(ACTIONS)
        genome[gene] = action
    return genome
    


def convertListToString(l):
    newList = []
    for item in l:
        st = ""
        for letter in item:
            st = st + letter
        newList.append(st)
    return newList


#####


class Fountain:
    def __init__(self):
        self.map = self.createMap()
        self.robotPos = (1,1)

    def evalutate(self, robot):
        fitness = 0
        self.robotPos = (1,1)
        map = self.map[:]
        for i in range(0,200): # 200 is the number of actions a robot can take
            x, y = self.robotPos
            env = self.getEnvironment()
            action = robot.getAction(env)
            self.printState(action, fitness)
            input("Press a key....")
           
            fitness += self.applyAction(action)
        return fitness


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
        if y == 1:
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

    def createMap(self):
        map = []
        border = []
        for i in range(0,12):
            border.append("*")
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


    def getEnvironment(self):
        x, y = self.robotPos
        env = ""
        env += self.map[y][x]    #in place
        env += self.map[y-1][y]  #up
        env += self.map[y][x+1]  #right
        env += self.map[y+1][x]  #down
        env += self.map[y][x-1]  #left
        return env


class Robot:
    def __init__(self, genome):
        self.fitness = 0
        self.genome = genome
    
    def getAction(self, env):
        return self.genome[env]

    def crossover(self, mate):
        split1 = random.randrange(0,128)
        split2 = random.randrange(0,128)
        possibleEnvs = createBlankGenome()
        
        newGenome = {}
        for i in range(0,128):
            if i < min(spit1, split2): # Take genes from parent 1
                env = possibleEnvs[i]
                action = self.getAction(env)
                newGenome[env] = action
            elif min(split1, split2) < i and i < max(split1, split2): # take genes from parent 2
                env = possibleEnvs[i]
                action = mate.getAction(env)
                newGenome[env] = action 
            elif max(split1, split2) < i:
                env = possibleEnvs[i]
                action = self.getAction(env)
                newGenome[env] = action  

        return Robot(newGenome)

    def mutate(self):
        possibleEnvs = createBlankGenome()
        for env in possibleEnvs:
            if random.uniform(0,1) > MUTATE_CHANCE


class GenePool:
    def __init__(self, robots):
        self.robots = robots
        self.env = Fountain()
        self.weights = [1]
        for i in range(1, len(robots)):
            self.weights.append(self.weights[i-1] * ROULETTE_FACTOR)
        self.best = self.test()

    def select_parents(self,num=2):
        return random.choices(self.robots,self.weights, k=num)

    def test(self):
        self.env.evalutate(self.robots[0])
        # self.robots.sort(key = lambda x: x.fitness)

    def nextGen(self):
        return []






def main():
    robots = []
    for i in range(0, POOL_SIZE):
        genome = randomFillGenome()
        robots.append(Robot(genome))
    
    pool = GenePool(robots)
    
if __name__ == "__main__":
    main()
