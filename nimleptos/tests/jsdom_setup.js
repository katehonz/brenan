// Setup jsdom environment for Nim JS tests in Node.js
const { JSDOM } = require('jsdom');

const dom = new JSDOM('<!DOCTYPE html><html><body><div id="app"></div></body></html>', {
  url: 'http://localhost',
  pretendToBeVisual: true,
  resources: 'usable'
});

global.document = dom.window.document;
global.window = dom.window;
global.navigator = dom.window.navigator;
global.Event = dom.window.Event;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLElement = dom.window.HTMLElement;

// Polyfill PopStateEvent for router tests (jsdom doesn't include it)
if (!global.PopStateEvent) {
  global.PopStateEvent = class PopStateEvent extends global.window.Event {
    constructor(type, init) {
      super(type, init);
      this.state = init ? init.state : null;
    }
  };
}
global.window.PopStateEvent = global.PopStateEvent;
