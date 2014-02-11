importScripts('../dist/orange/worker.js');

function sendTimeOnInterval(job, interval) {
  job.trigger('time', new Date());
  setTimeout(sendTimeOnInterval, interval || 1000, job);
}

perform(function(job, data) {
  sendTimeOnInterval(job, 1000);

  job.on('calculate', function(data) {
    job.log('Calculating (' + data + '):', eval(data));
  });

  job.done('Long runing worker started.');
});
