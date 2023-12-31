//
//  WebUserScript.swift
//  LarkWebViewContainer
//
//  Created by yinyuan on 2022/4/12.
//

import Foundation

public final class WebUserScript {
    
    static var geoLocationDisable: String {
"""
(function () {
  navigator.geolocation.getCurrentPosition = function (success, error, options) {
      return typeof error === 'function' && error(new Error('permission denied(1000001)'))
  };

  navigator.geolocation.watchPosition = function (success, error, options) {
      return typeof error === 'function' && error(new Error('permission denied(1000001)'))
  };

  navigator.geolocation.clearWatch = function (id) {
      return;
  };
})();
"""
    }
    
    public static var consoleLoggerSource: String {
"""
var console = (function (originalConsole) {
  function larkOPWebConsoleHandler(level) {
    return function(msg) {
      window.webkit.messageHandlers.opWebConsoleHandler.postMessage({ method: "console", level: level, content: JSON.stringify(msg) });
      originalConsole[level](msg);
      };
    }
  return {
    ...originalConsole,
    warn: larkOPWebConsoleHandler("warn"),
    error: larkOPWebConsoleHandler("error")
  }
})(window.console);
"""
    }
}
