//
//  BaseServices.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/14.
//  

import SKFoundation

// MARK: - BaseServices
// 当作命名空间来做
public enum BaseService {
    typealias LogFuncType = (_ message: String, _ extraInfo: [String: Any]?, _ error: Error?, _ component: String?, _ traceId: String?, _ fileName: String, _ funcName: String, _ funcLine: Int) -> Void
    typealias LogDebugFuncType = (_ message: @autoclosure () -> String,
                                  _ extraInfo: [String: Any]?,
                                  _ error: Error?,
                                  _ component: String?,
                                  _ traceId: String?,
                                  _ fileName: String,
                                  _ funcName: String,
                                  _ funcLine: Int) -> Void
    
    static var debugLogfunc: LogDebugFuncType? = DocsLogger.debug
    static var warningLogfunc: LogFuncType? = DocsLogger.warning
    static var errorLogfunc: LogFuncType? = DocsLogger.error
    static var serverLogfunc: LogFuncType? = DocsLogger.severe
    static var verboseLogfunc: LogFuncType? = DocsLogger.verbose
    static var infoLogfunc: LogFuncType? = DocsLogger.info

    typealias AssertFailFunc = (_ message: @autoclosure () -> String, _ file: StaticString, _ lint: UInt) -> Void
    typealias AssertFunc = (_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, _ file: StaticString, _ lint: UInt) -> Void
    static var assertFailFunc: AssertFailFunc? = spaceAssertionFailure
    static var assertFunc: AssertFunc? = spaceAssert
}

public func skInfo(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.infoLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skVerbose(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.verboseLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skDebug(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.debugLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skWarning(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.warningLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skError(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.errorLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skSevere(
    _ message: String,
    extraInfo: [String: Any]? = nil,
    error: Error? = nil,
    component: String? = nil,
    fileName: String = #fileID,
    funcName: String = #function,
    funcLine: Int = #line) {
    BaseService.serverLogfunc?(message, extraInfo, error, component, nil, fileName, funcName, funcLine)
}

public func skAssertionFailure(
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {
    BaseService.assertFailFunc?(message(), file, line)
}

public func skAssert(
    _ condition: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #fileID,
    line: UInt = #line) {
    if let currentAssert = BaseService.assertFunc {
        currentAssert(condition(), message(), file, line)
    }
}
