"""
Code for Evolutionary Strategy algorithm taken from openAI
https://openai.com/blog/evolution-strategies/
Modified slightly to have 5 parameters
"""

import numpy as np
def f(w):
  reward = -np.sum(np.square(solution - w))
  return reward

# hyperparameters
npop = 2 # population size
sigma = 0.1 # noise standard deviation
alpha = 0.001 # learning rate

# start the optimization
solution = np.array([0.5, 0.1, -0.3, 0.8, -.5])
w = np.random.randn(5) # our initial guess is random
for i in range(300):
  if i % 20 == 0:
    print('iter %d. w: %s, solution: %s, reward: %f' % 
          (i, str(w), str(solution), f(w)))
  N = np.random.randn(npop, 5) # samples from a normal distribution N(0,1)
  R = np.zeros(npop)
  for j in range(npop):
    w_try = w + sigma*N[j] # jitter w using gaussian of sigma 0.1
    # print(w_try)
    R[j] = f(w_try) # evaluate the jittered version
  print(R)
  A = (R - np.mean(R)) / np.std(R)
  w = w + alpha/(npop*sigma) * np.dot(N.T, A)