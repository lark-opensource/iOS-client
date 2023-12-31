//
//  OpenPluginWebAppDebug.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2023/9/5.
//

import ECOInfra
import LarkAccountInterface
import LarkAppConfig
import LarkContainer
import LKCommonsLogging
import LarkSetting

enum WebOnlineInspectNetworkError: String, Error {
    case createTaskError
    case invalidParams
    case reponseDataError
}

// MARK: - WebOnlineInspectNetwork
class WebOnlineInspectNetwork {
    
    static let logger = Logger.ecosystemWebLog(WebOnlineInspectNetwork.self, category: "WebOnlineInspect")
        
    private static var service: ECONetworkService {
        Injected<ECONetworkService>().wrappedValue
    }
    
    private static func requestDomain(_ alias: DomainKey) -> String? {
        return DomainSettingManager.shared.currentSetting[alias]?.first
    }
    
    private static var connectionDict = [String: WebOnlineInspectorConnection]()
    private static var debugURLConnIDDict = [String: String]()
          
    static func getWebDebugConnection(appId: String, debugPageUrl: String, debugSession: String, deviceID: String, debugSessionCheckLevel: Int, context: ECONetworkServiceContext, completionHandler: @escaping (Result<OpenPluginGetWebDebugConnectionResponse?, Error>) -> Void) {
       
        let connID = debugURLConnIDDict[debugPageUrl] ?? ""
        if let connection = connectionDict[connID] {
            //非首次，根据connection请求更新token
            logger.info("exec createWSSToken")
            self.createWSSTokenRequest(connection: connection, deviceID: deviceID, context: context, completionHandler:completionHandler)
        } else {
            //首次创建链接，获得token等信息
            logger.info("exec createConnection")
            self.createConnectionRequest(appId: appId, debugPageUrl: debugPageUrl, debugSession: debugSession, deviceID: deviceID, debugSessionCheckLevel: debugSessionCheckLevel, context: context, completionHandler: completionHandler)
        }
    }
    
    static func closeConnection(connId: String, debugScene: Int, context: ECONetworkServiceContext, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let connection = connectionDict[connId] else {
            logger.info("debug connection is empty")
            completionHandler(.failure(WebOnlineInspectNetworkError.invalidParams))
            return
        }
        self.closeConnection(appId: connection.appId, connId: connection.connRes.connId, debugSession: connection.debugSession, debugScene: 1, context: context, completionHandler: completionHandler)
    }
    
    static func closeConnection(appId: String, connId: String, debugSession: String, debugScene: Int, context: ECONetworkServiceContext, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        if(appId.isEmpty || connId.isEmpty || debugSession.isEmpty) {
            logger.error("appId and connId and debugSession can not empty")
            completionHandler(.failure(WebOnlineInspectNetworkError.invalidParams))
            return
        }
        self.closeConnectionRequest(appId: appId, connId: connId, debugSession: debugSession, debugScene: debugScene, context: context, completionHandler: completionHandler)
        self.connectionDict.removeValue(forKey: connId)
    }
            
    // 获取调试逻辑连接request
    static private func createConnectionRequest(appId: String, debugPageUrl: String, debugSession: String, deviceID: String, debugSessionCheckLevel: Int, context: ECONetworkServiceContext, completionHandler: @escaping (Result<OpenPluginGetWebDebugConnectionResponse?, Error>) -> Void) {
        
        let params = [
            "app_id": appId,
            "debug_page_url": debugPageUrl,
            "debug_session" : debugSession,
            "lark_device_id": deviceID,
            "webkit_version": "Apple WebKit2",
            "debug_session_check_level" : debugSessionCheckLevel
        ] as [String : Any]
    
        let header: [String: String] = ["Content-Type": "application/json"]
        let host = self.requestDomain(.open) ?? ""
        let url = self.getUrlString(with: host, path: "/miniprogram/api/v5/web_online/remote_debug/conn")
        let serviceTask = service.post(url: url, header: header, params: params, context: context) { res, err in
            let logID = (res?.response.allHeaderFields["x-tt-logid"]) ?? "empty logid"
            logger.info("finish createConnection, appID:\(appId), logID:\(logID)")
            if let error = err {
                completionHandler(.failure(error))
                return
            }
            var response: OpenPluginGetWebDebugConnectionResponse? = nil
            var error: NSError? = nil
            if let result = res?.result, let code = result["code"] as? Int {
                if code == 0, let data = result["data"] as? [String: Any] {
                    if let wssConnInfo = data["wss_conn_info"] as? [String: Any], let connID = data["conn_id"] as? String {
                        response = OpenPluginGetWebDebugConnectionResponse.parseParamDict(connID: connID, apiHost: host, wssConnInfo: wssConnInfo)
                    }
                } else {
                    error = self.getErrorFromResonse(result: result, code: code)
                }
            }
            
            if let response = response {
                self.connectionDict[response.connId] = WebOnlineInspectorConnection(appId: appId, debugSession: debugSession, connRes: response)
                self.debugURLConnIDDict[debugPageUrl] = response.connId
                completionHandler(.success(response))
            } else {
                completionHandler(.failure(error ?? WebOnlineInspectNetworkError.createTaskError))
            }
        }

        if let task = serviceTask {
            logger.info("start createConnection, appID:\(appId)")
            service.resume(task: task)
        } else {
            logger.error("create task fail")
            completionHandler(.failure(WebOnlineInspectNetworkError.createTaskError))
        }
    }
    
    //创建长连接token request
    static private func createWSSTokenRequest(connection: WebOnlineInspectorConnection, deviceID: String, debugScene: Int = 1, context: ECONetworkServiceContext, completionHandler: @escaping (Result<OpenPluginGetWebDebugConnectionResponse?, Error>) -> Void) {
        
        let params = [
            "app_id": connection.appId,
            "conn_id": connection.connRes.connId,
            "debug_session" : connection.debugSession,
            "lark_device_id": deviceID,
            "debug_scene" : debugScene
        ] as [String : Any]
        
        let header: [String: String] = ["Content-Type": "application/json"]
        let host = self.requestDomain(.open) ?? ""
        let url = self.getUrlString(with: host, path: "/miniprogram/api/v5/web_online/remote_debug/conn/token")
        let serviceTask = service.post(url: url, header: header, params: params, context: context) { res, err in
            let logID = (res?.response.allHeaderFields["x-tt-logid"]) ?? "empty logid"
            logger.info("finish createWSSToken, logID:\(logID)")
            if let error = err {
                completionHandler(.failure(error))
                return
            }
            
            var response: OpenPluginGetWebDebugConnectionResponse? = nil
            var error: NSError? = nil
            if let result = res?.result, let code = result["code"] as? Int {
                if code == 0, let data = result["data"] as? [String: Any] {
                    if let wssConnInfo = data["wss_conn_info"] as? [String: Any] {
                        response = OpenPluginGetWebDebugConnectionResponse.parseParamDict(connID: connection.connRes.connId, apiHost: host, wssConnInfo: wssConnInfo)
                    }
                } else {
                    error = self.getErrorFromResonse(result: result, code: code)
                }
            }
            
            if let response = response {
                //update
                self.connectionDict[connection.connRes.connId] = WebOnlineInspectorConnection(appId: connection.appId, debugSession: connection.debugSession, connRes: response)
                completionHandler(.success(response))
            } else {
                completionHandler(.failure(error ?? WebOnlineInspectNetworkError.createTaskError))
            }
        }
        
        if let task = serviceTask {
            logger.info("start createWSSToken")
            service.resume(task: task)
        } else {
            logger.error("create createWSSToken task fail")
            completionHandler(.failure(WebOnlineInspectNetworkError.createTaskError))
        }
    }
    
    // 关闭调试链接 request
    static private func closeConnectionRequest(appId: String, connId: String, debugSession: String, debugScene: Int, context: ECONetworkServiceContext, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        
        let params = [
            "app_id": appId,
            "conn_id": connId,
            "debug_scene": debugScene,
            "debug_session" : debugSession
        ] as [String : Any]
    
        let header: [String: String] = ["Content-Type": "application/json"]
        let host = self.requestDomain(.open) ?? ""
        let url = self.getUrlString(with: host, path: "/miniprogram/api/v5/web_online/remote_debug/conn/close")
        
        let serviceTask = service.post(url: url, header: header, params: params, context: context) { res, err in
            let logID = (res?.response.allHeaderFields["x-tt-logid"]) ?? "empty logid"
            logger.info("finish closeConnection, connId:\(appId), logID:\(logID)")
            if let error = err {
                completionHandler(.failure(error))
                return
            }
            
            if let result = res?.result, let code = result["code"] as? Int {
                let isSuccess = code == 0
                completionHandler(.success(isSuccess))
            } else {
                completionHandler(.failure(WebOnlineInspectNetworkError.reponseDataError))
            }
        }
        
        if let task = serviceTask {
            logger.info("start closeConnection, connId:\(appId)")
            service.resume(task: task)
        } else {
            logger.error("create closeConnection task fail")
            completionHandler(.failure(WebOnlineInspectNetworkError.createTaskError))
        }
    }
    
    static private func getErrorFromResonse(result: [String: Any], code: Int) -> NSError? {
        var error: NSError? = nil
        if let errorDict = result["error"] as? [String: Any], let localizedMsgDict = errorDict["localizedMessage"] as? [String: String] {
            let errorId = errorDict["id"] ?? ""
            var errorMsg = localizedMsgDict["message"] ?? ""
            if let responseMsg = result["msg"] as? String {
                if errorMsg.isEmpty {
                    errorMsg = responseMsg
                }
                logger.info("code: \(code), msg:\(responseMsg), error.localizedMessage.message:\(errorMsg), error.id :\(errorId)")
            } else {
                logger.info("code: \(code), msg:null, error.localizedMessage.message:\(errorMsg), error.id :\(errorId)")
            }
            let finalErrorMsg = "code:\(code), msg:\(errorMsg)"
            let errorInfo = [NSLocalizedDescriptionKey: finalErrorMsg]
            error = NSError(domain: "com.openplatform.webbrowser.debug.error", code: code, userInfo: errorInfo)
        }
        return error
    }

    static private func getUrlString(with host: String, path: String) -> String {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if let url = components.url {
            return url.absoluteString
        }
        return ""
    }
}

// MARK: - WebOnlineInspectorConnection
public class WebOnlineInspectorConnection {
    /// 应用ID
    let appId: String
    
    /// 调试Session
    let debugSession: String
    
    /// 创建调试链接的Response
    let connRes: OpenPluginGetWebDebugConnectionResponse
    
    init(appId: String, debugSession: String, connRes: OpenPluginGetWebDebugConnectionResponse) {
        self.appId = appId
        self.debugSession = debugSession
        self.connRes = connRes
    }
}

