//
//  EMADomainMiddleware.swift
//  EEMicroAppSDK
//
//  Created by MJXin on 2021/6/1.
//

import Foundation
import ECOInfra
import OPPluginManagerAdapter
import LKCommonsLogging
import LarkAccountInterface
import OPFoundation

/// Domain 获取中间件
class EMADomainMiddleware: ECONetworkMiddleware {
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        request.domain = (BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate)?.config?.domainConfig.openMinaDomain
        /// 添加小程序双机房配置参数，由Rust SDK检测此参数替换对应的备份机房域名
        /// ⚠️ 遗留的老逻辑, 这个字段会强制修改发起请求的 domain,
        /// 文档参见https://bytedance.feishu.cn/space/doc/doccn97DHActi4X2W75meLyEcjd
        request.setHeaderField(key: "domain_alias",value: "open")
        return .success(request)
    }
}

/// 未登陆时 Domain 获取中间件
class EMADomainWithoutLoginMiddleware: ECONetworkMiddleware {
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        request.domain = MicroAppDomainConfig.getDomainWithoutLogin().openMinaDomain
        request.setHeaderField(key: "domain_alias",value: "open")
        return .success(request)
    }
}

/// 加密中间件
/// TODO: 按理想的设计模式, 有这个中间件就没有 EMANetworkCipher 了. 之后的网络相关业务,都是中间件实现
/// 一次改造专注一件事, 本次只 NetworkService MVP 平移逻辑
class EMANetworkCipherMiddleware: ECONetworkMiddleware {
    
    private static let logger = Logger.oplog(EMANetworkCipherMiddleware.self, category: "EEMicroAppSDK")
    private let cipher = EMANetworkCipher()
    private let resultDictKey: String
    
    init(resultKey: String) { resultDictKey = resultKey }

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest,Error> {
        var request = request
        request.setBodyField(key: "ttcode", value: cipher.encryptKey)
        return .success(request)
    }
    
    func processResponse<ResultType>(task: ECONetworkServiceTaskProtocol, request: ECONetworkRequest, response: ECONetworkResponse<ResultType>) -> Result<ECONetworkResponse<ResultType>, Error> {
        guard let result = response.result as? [String: Any] else {
            Self.logger.error("CipherMiddleware processResponse with wrongType:\(String(describing: response.result.self))")
            return .failure(OPError.incompatibleResultType(detail: "CipherMiddleware processResponse with wrongType:\(String(describing: response.result.self))"))
        }
        
        guard let encryptedContent = result["encryptedData"] as? String,
              let decryptedDict = EMANetworkCipher.decryptDict(
                forEncryptedContent: encryptedContent,
                cipher: cipher
              ) as? Dictionary<String,Any> else {
            Self.logger.error("CipherMiddleware can't get decryptedDict")
            return .failure(OPError.incompatibleResultType(detail: "CipherMiddleware can't get decryptedDict"))
        }
        //TODO: 目前这个逻辑平移自原 EMARequestUtil 逻辑, 由于其本身将 cipher 获取与具体业务数据解包耦合, 导致 middleware 需要耦合具体接口. 用 resultDictKey 拿解析后数据
        if  let resultDict = decryptedDict[resultDictKey],
            let result = resultDict as? ResultType {
             var response = response
             response.updateResult(result: result)
             return .success(response)
        } else {
            return .failure(OPError.incompatibleResultType(detail: "CipherMiddleware unexpect result"))
        }
    }
}

/// EE 网络请求通用参数 (依赖对应的中间件类型)
class EMAAPIRequestCommonParamsMiddleware: ECONetworkMiddleware {
    
    private static let logger = Logger.oplog(EMANetworkCipherMiddleware.self, category: "EEMicroAppSDK")
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        var commonBody: [String: String]?
        var commonHeader: [String: String]?
        if let context = task.context as? BDPContextProtocol {
            commonBody = getCommonParams(fromBDPContextProtocol: context)
            commonHeader = getCommonHeader(fromBDPContextProtocol: context)
        } else if let context = task.context as? BDPCommon {
            commonBody = getCommonParams(fromBDPCommon: context)
            commonHeader = getCommonHeader(fromBDPCommon: context)
        } else {
            assertionFailure("error contextType = \(task.context.self)")
            Self.logger.error("error contextType = \(task.context.self)")
            return .failure(OPError.contextTypeError(detail: "contextType = \(task.context.self)"))
        }
        
        guard let bodyFields = commonBody, let headers = commonHeader else {
            assertionFailure("contextType error tyoe = \(task.context.self)")
            Self.logger.error("error contextType = \(task.context.self)")
            return .failure(OPError.contextTypeError(detail: "contextType = \(task.context.self)"))
        }
        var request = request
        request.mergingBodyFields(with: bodyFields)
        request.mergingHeaderFields(with: headers)
        return .success(request)
    }
    
    func getCommonParams(fromBDPContextProtocol context: BDPContextProtocol) -> [String: String]? {
        guard let engineType = context.engine?.uniqueID.appType,
              let uniqueID = context.engine?.uniqueID,
              let auth: BDPAuthModuleProtocol = BDPModuleManager(
                of: engineType
              ).resolveModule(with: BDPAuthModuleProtocol.self) as? BDPAuthModuleProtocol,
              let session = auth.getSessionContext(context) else {
            Self.logger.error("contextType = \(context.self) miss require params")
            assertionFailure("contextType = \(context.self) miss require params")
            return nil
        }
        let appType = uniqueID.appType
        var sessionKey = "session"
        if appType == .gadget {
            sessionKey = "minaSession"
        } else if appType == .webApp {
            sessionKey = "h5Session"
        }
        return ["appid": uniqueID.appID, sessionKey: session]
    }
    
    func getCommonHeader(fromBDPCommon context:BDPCommon) -> [String: String]? {
        guard let appEngine = (BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate),
              let session = appEngine.account?.userSession else {
            Self.logger.error("contextType = \(context.self) miss require params")
            assertionFailure("contextType = \(context.self) miss require params")
            return nil
        }
        return  ["Cookie": "session=\(session)"]
    }
    
    func getCommonParams(fromBDPCommon context: BDPCommon) -> [String: String]? {
        guard let uniqueID = context.uniqueID,
              let sanbox = context.sandbox,
              let session = TMASessionManager.shared()?.getSession(sanbox) else {
            Self.logger.error("contextType = \(context.self) miss require params")
            assertionFailure("contextType = \(context.self) miss require params")
            return nil
        }
        return ["appid": uniqueID.appID, "session": session]
    }
    
    func getCommonHeader(fromBDPContextProtocol context: BDPContextProtocol) -> [String: String]? {
        guard let engineType = context.engine?.uniqueID.appType,
              let auth = BDPModuleManager(
                of: engineType
              ).resolveModule(with: BDPAuthModuleProtocol.self) as? BDPAuthModuleProtocol,
              let session = auth.getSessionContext(context) else {
            Self.logger.error("contextType = \(context.self) miss require params")
            assertionFailure("contextType = \(context.self) miss require params")
            return nil
        }
        return  ["Cookie": "sessionKey=\(session)"]
    }
}

// 给request的header注入开放应用 Session的中间件
class EMASessionInjector: ECONetworkMiddleware {
    private static let logger = Logger.oplog(EMASessionInjector.self, category: "EEMicroAppSDK")
    
    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        guard let context = task.context as? BDPContextProtocol else {
            // 非 BDPContextProtocol 情况下拿不到 Session, 啥也不干
            return .success(request)
        }
        var request = request
        request.mergingHeaderFields(with: GadgetSessionFactory.storage(for: context).sessionHeader)
        return .success(request)
    }
}

// 给request的header注入lark Session的中间件
class LarkSessionInjector: ECONetworkMiddleware {
    
    enum EMANetworkLarkSessionKey: String {
        case X_Session_ID = "X-Session-ID"
    }

    private var larkSessionKey: EMANetworkLarkSessionKey

    init(larkSessionKey: EMANetworkLarkSessionKey) {
        self.larkSessionKey = larkSessionKey
    }

    func processRequest(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest
    ) -> Result<ECONetworkRequest, Error> {
        // TODOZJX
        let larkSession = AccountServiceAdapter.shared.currentAccessToken
        var request = request
        request.mergingHeaderFields(with: [larkSessionKey.rawValue: larkSession])
        return .success(request)
    }
}

class EMAResponseVerifyMiddleware: ECONetworkMiddleware {
    
    func didCompleteRequest<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<Void, Error> {
        if response.bodyData == nil {
            // 旧逻辑,与原先保持一致
            let msg = "invaild data"
            let error = NSError(domain: msg, code: -9999, userInfo: [NSLocalizedDescriptionKey: msg])
            return .failure(error)
        } else {
            return .success(())
        }
    }
    
    func processResponse<ResultType>(
        task: ECONetworkServiceTaskProtocol,
        request: ECONetworkRequest,
        response: ECONetworkResponse<ResultType>
    ) -> Result<ECONetworkResponse<ResultType>, Error> {
        // 旧逻辑,与原先保持一致
        if response.result == nil {
            let msg = "response dict is nil"
            let error = NSError(domain: msg, code: -9999, userInfo: [NSLocalizedDescriptionKey: msg])
            return .failure(error)
        } else {
            return .success(response)
        }
    }
}

