(function() {
  importScripts('../../../orange/worker.js');

  perform(function(data) {
    var memo, number, _i, _len, _ref;
    memo = 0;
    _ref = data.members;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      number = _ref[_i];
      memo += number;
    }
    return memo;
  });

}).call(this);

/*
//@ sourceMappingURL=sum.js.map
*/