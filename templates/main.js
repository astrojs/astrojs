(function() {
  var {{name}};

  {{name}} = this.{{name}} = {};

  {{name}}.VERSION = '0.0.1';

  if (typeof module !== "undefined" && module !== null) {
    module.exports = {{name}};
  }

}).call(this);