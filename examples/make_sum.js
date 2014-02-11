importScripts('../dist/orange/worker.js');

perform(function(data) {

  function sum(numbers) {
    for(var i=0,sum=0,l=numbers.length;i<l;i++) {
      sum += numbers[i];
    }
    return sum;
  }

  if (Math.random() > 0.5) {
    throw new Error('Oh noes!');
  }

  return sum(data.members);
});

