//
//  GeckoLogger.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/7/7.
//  


import SKFoundation

class GeckoLogger {
    class func debug(_ msg: String, fileName: String = #fileID, funcName: String = #function, funcLine: Int = #line) {
        DocsLogger.debug(msg, component: LogComponents.fePackgeManager, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }
    class func info(_ msg: String, fileName: String = #fileID, funcName: String = #function, funcLine: Int = #line) {
        DocsLogger.info(msg, component: LogComponents.fePackgeManager, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }
    class func warning(_ msg: String, error: Error? = nil, fileName: String = #fileID, funcName: String = #function, funcLine: Int = #line) {
        DocsLogger.warning(msg, error: error, component: LogComponents.fePackgeManager, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }
    class func error(_ msg: String, error: Error? = nil, fileName: String = #fileID, funcName: String = #function, funcLine: Int = #line) {
        DocsLogger.error(msg, error: error, component: LogComponents.fePackgeManager, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }
}
