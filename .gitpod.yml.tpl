#!/usr/bin/env node

let _ = require('lodash-firecloud');
let fs = require('fs');
let yaml = require('js-yaml');

// see https://www.gitpod.io/docs/config-gitpod-file

let vscodeExtensions = fs.readFileSync(`${__dirname}/.vscode/extensions.json`);
vscodeExtensions = JSON.parse(vscodeExtensions);

let config = {
  // image: 'ubuntu:20.04',
  image: 'ysoftwareab/yp-ubuntu-20.04-common:latest',

  github: {
    prebuilds: {
      master: true,
      branches: false,
      pullRequests: false,
      pullRequestsFromForks: false,
      addCheck: false,
      addComment: false,
      addBadge: true
    }
  },

  vscode: {
    extensions: vscodeExtensions.recommendations
  },

  // NOTE 'make bootstrap' would be nice because
  // the branch's bootstrap might be out of sync with ysoftwareab/yp-ubuntu-20.04-common:latest
  // NOTE 'gp env PATH=$PATH' in order for vscode to find brew executable e.g. shellcheck
  // TODO should also modify the shell's rc file to source dev/inc.sh

  tasks: [{
    // init: _.join([
    //   'source dev/inc.sh',
    //   'make bootstrap'
    // ], '\n'),
    command: _.join([
      'source dev/inc.sh',
      'gp env PATH=$PATH',
      'gp open README.md',
      'make help'
    ], '\n')
  }]
};

let ymlConfig = yaml.dump(config);
// eslint-disable-next-line no-console
console.log(ymlConfig);
