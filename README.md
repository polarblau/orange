# Orange

Orange wants to make multi threaded code on the client side more accessible. It provides a set of helpers and conventions to queue and execute jobs in the background using Web Workers across all browsers.

All example code is written in CoffeeScript.

## Usage

### Setup

To get started simply include orange.js in your HTML file. If you want to use the worker API provided by Orange you will also have to include orange/worker.js in your public directory (no need to include it in the HTML files, though).

#### Settings

Orange can be configured via a few settings.

<table>
<thead>
<th>Property</th>
<th>Default</th>
<th></th>
</thead>
<tbody>
<tr>
<td><strong>maxWorkerPoolSize</strong></td>
<td>4</td>
<td>
The maximum amount of Jobs to be executed in parallel *across the entire app*. Browsers have different limits for the number of workers that can be used in parallel. Orange will help to ensure that this number won’t be exceeded since this would inadvertently crash the browser. 
</td>
</tr>
<tr>
<td><strong>maxRetries</strong></td>
<td>3</td>
<td>
How often should a job be restarted if an error occurs?
</td>
</tr>
<tr>
<td><strong>workersPath</strong></td>
<td>'/lib/workers/'</td>
<td>
A relative path to your workers directory.
</td>
</tr>
</tbody>
</table>

Update and read settings:

```coffeescript
Orange.Config.set('maxWorkerPoolSize', 10)

# update multiple settings at once
Orange.Config.set
  maxWorkerPoolSize: 4
  maxRetries       : 3
  workersPath      : '/lib/workers/'
  
# read a setting
Orange.Config.get('maxRetries') # => 3
```

***

### Jobs

#### Defining a new job

In order to perform an operation in the background, simply instantiate the Orange.Job class by defining a job type and passing all required data. 

A job is essentially nothing more than a thin wrapper around a Worker instance, facilitating communication from and to the Worker and providing helpers like callbacks and events.

```coffee
# assuming you have a worker file called `sum.js`
# defined in your workers directory create a new job …
job = new Orange.Job('sum', [1, 2, 3])

# … and run it
job.perform()
```

***

### Workers

#### Defining a worker using the Orange Worker API

Orange provides a thing API layer for the workers to simplify the communication with the job. To define a new worker, create a new Javascript file under your workers directory and import Orange’s Worker API using the native function `importScripts()`. Then define your Worker through the `defineWorker()` method provided through the Orange API.

```coffee
importScripts 'orange/worker.js'

perform (data)->
  data.numbers.reduce (a, b) -> a + b
```

**Note**: The Orange worker API only extends the native Web Worker API but doesn’t override anything.

#### Listen to events from the Worker

```coffee
# success: triggered once the Worker’s `perform()` method returns successfully
job.on 'success', (result) ->
  console.log('Your job finished and returned:', result)
  
# complete: triggered either once the Worker’s `perform()` method returns successfully or the max. number of retries has been exceeded
job.on 'complete', ->
  console.log('Your job finished')

# error: triggered whenever an error occurs within the worker
job.on 'error', (error) -> 
  console.error('Your job threw an error:', error)
  
# failure: triggered if the maximum amount of retries is exceeded
job.on 'failure', (error)-> 
  retryCount = Orange.Config.get('maxRetries')
  console.error("Your job failed after #{retryCount} retries.")
```  

#### Logging within a worker

The Orange Worker API provides a convenience method `log()` to log messages from the worker to the console since Web Workers don’t have access.

```coffeescript
importScripts 'orange/worker.js'

perform (data)->
  log 'starting to count...'
  data.numbers.reduce (a, b) -> a + b
```

***

### Batches

You’ll find yourself sometimes in a situation where you’d like to schedule a group of jobs and receive a callback once *all* jobs are completed.
Orange provides the convenience class `Batch` for this purpose:

```coffee
batch = new Orange.Batch

# now you can simply push a job into this set after you define it

job = new Orange.Job('sum', [1, 2, 3])
batch.push job

batch.perform()

# additionally you can also import an set of jobs when creating a new batch

batch = new Orange.Batch [job1, job2, job3]
```

*NOTE: Once a job has been added to batch you can’t call it’s `#perform` method any longer. Call the `batch#perform` method instead once the batch has been populated.*
*NOTE: Once a batches’ `#perform` method has been called it will be locked and no more new jobs can be added to it.*

A batch triggers a `complete` event, once all jobs have finished as well as `complete`, `error` and `failure` events for individual jobs. As the name suggests, the complete event will return the jobs in the same order they have been added.

```coffeescript
batch.on 'complete', (jobs) ->
  console.log("Completed #{jobs.length} jobs.")

# you can retrieve whatever the worker returned using the job#getResponse method
batch.on 'job:success', (job) ->
  console.log('A job has completed and returned:', job.getResponse())

batch.on 'job:complete', (job)->
  console.log('A job has finished somehow.')

# you can retrieve the last error caused by the worker using the job#getLastError method
batch.on 'job:error', (job) ->
  console.error('A job threw an error:', job.getLastError())

batch.on 'job:failure', (job) ->
  console.error('A job failed to complete.', job.getLastError())
```



