//
// Created by maozhixiang.lip on 2022/10/19.
//

import Foundation
import Lynx

class LynxLoggerModule: NSObject, LynxNativeModule {
    typealias Param = Any
    private(set) static var name: String = "Logger"
    private(set) static var methodLookup: [String: String] = [
        "log": NSStringFromSelector(#selector(log(level:content:)))
    ]
    override required init() { super.init() }
    required init(param: Any) {}

    @objc func log(level: String, content: String) {
        switch level {
        case "info": Logger.lynx.info(content)
        case "warn": Logger.lynx.warn(content)
        case "error": Logger.lynx.error(content)
        case "debug": Logger.lynx.debug(content)
        default: return
        }
    }
}
