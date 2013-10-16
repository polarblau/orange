if 'Worker' of window
  Orange.Worker = Worker
else
  throw new Error('Your environment does not support WebWorkers')