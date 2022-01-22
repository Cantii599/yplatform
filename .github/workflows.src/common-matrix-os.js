/* eslint-disable no-template-curly-in-string */

let _ = require('lodash-firecloud');

let matrixOs = {
  ubuntu: [
    // deprecated in https://github.com/actions/virtual-environments/issues/3287
    // "ubuntu-16.04",
    'ubuntu-18.04',
    'ubuntu-20.04'
  ],
  macos: [
    'macos-10.15',
    'macos-11'
  ],
  windows: [
    'windows-2019',
    'windows-2022'
  ]
};

module.exports = {
  matrixOs
};
