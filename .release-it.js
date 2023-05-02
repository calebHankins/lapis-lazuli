module.exports = {
  npm: {
      "publish": false
  },
  hooks: {
      "after:bump": [
          "npx auto-changelog -p"]
  },
};
