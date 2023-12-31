//
//  OpenPluginVerify.swift
//  OPPlugin
//
//  Created by zhysan on 2021/4/27.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginBiz
import OPFoundation
import SwiftyJSON
import OPPluginManagerAdapter
import LarkAccountInterface
import ECOInfra
import LarkContainer
import LarkEnv
import LarkSetting

private enum HTTPMethod: String {
    case post = "POST"
    case get = "GET"
}

struct APIErrorWrapper: Error {
    let apiError: OpenAPIError
}

/// 内部错误 code（和原来的错误码保持一致）
private let kErrCodeUndefine = -1;
/// 内部错误 msg（和原来的错误消息保持一致）
private let kErrMsgUndefine  = "something error";

/// 离线人脸比对基准图读取失败
private let kErrCodeOfflineVerifyImgReadFailed  = 9001;
/// 离线人脸比对资源下载超时
private let kErrCodeOfflinePrepareTimeout       = 9002;

/// 离线人脸比对基准图文件大小限制：最大 10M
private let kOfflineVerifyMaxImageSize: Int = 10 * 1024 * 1024;

/// 离线人脸比对 Prepare 超时时间限制
private let kOfflinePrepareTimeoutMax: Double = 60.0;

private typealias APICallback = (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void

enum FaceIdentifyAuthType: String {
    case currentUser = "current_user_auth"
    case twoElement = "two_element_auth"
}

private final class LocalVerifyPrepareTimerInfo: NSObject {
    var monitor: OPMonitor
    var callback: APICallback
    init(monitor: OPMonitor, callback: @escaping APICallback) {
        self.monitor = monitor
        self.callback = callback
        super.init()
    }
}

final class OpenPluginVerify: OpenBasePlugin {
    
    @ScopedProvider private var userService: PassportUserService?

    /// 离线比对下载资源的超时 Timer，为保障线程安全，只可在主线程访问
    private var offlinePrepareTimers = [Timer]()
    
    // MARK: - register
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        registerInstanceAsyncHandlerGadget(
            for: "setAuthenticationInfo", pluginType: Self.self,
            paramsType: OpenSetAuthenticationInfoParams.self
        ) { (this, params, context, gadgetContext, callback) in
            
            this.setAuthenticationInfo(params: params, context: context,  gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(
            for: "startFaceIdentify", pluginType: Self.self,
            paramsType: OpenStartFaceIdentifyParams.self,
            resultType: OpenOnlineFaceVerifyResult.self
        ) { (this, params, context, gadgetContext, callback) in
            
            this.startFaceIdentify(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(
            for: "startFaceVerify", pluginType: Self.self,
            paramsType: OpenStartFaceVerifyParams.self,
            resultType: OpenOnlineFaceVerifyResult.self
        ) { (this, params, context, gadgetContext, callback) in
            
            BDPMemoryManager.sharedInstance.triggerMemoryCleanByAPI(name: "startFaceVerify")
            this.startFaceVerify(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
        registerInstanceAsyncHandler(
            for: "checkLocalFaceVerify",
            pluginType: Self.self
        ) { (this, params, context, callback) in
            
            this.checkLocalFaceVerify(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(
            for: "prepareLocalFaceVerify", pluginType: Self.self,
            paramsType: OpenPrepareLocalFaceVerifyParams.self
        ) { (this, params, context, callback) in
            
            this.prepareLocalFaceVerify(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandlerGadget(
            for: "startLocalFaceVerify", pluginType: Self.self,
            paramsType: OpenStartLocalFaceVerifyParams.self
        ) { (this, params, context, gadgetContext, callback) in
            
            this.startLocalFaceVerify(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
    }
    
    // MARK: - api implementation
    
    /// 在线有源：三要素信息上传和认证
    func setAuthenticationInfo(
        params: OpenSetAuthenticationInfoParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        context.apiTrace.info("setAuthenticationInfo, app=\(gadgetContext.uniqueID)")
        
        let uniqueID = gadgetContext.uniqueID
        let trace = EMARequestUtil.generateRequestTracing(uniqueID)
        EMANetworkManager.shared().requestUrl(
            EMAAPI.uploadAuthURL(),
            method: HTTPMethod.post.rawValue,
            params: params.toJSONDict(),
            header: networkSessionHeader(),
            completionHandler: { (data, _, error) in
                guard let data = data else {
                    OPMonitor(APIMonitorCodeFaceLiveness.upload_info_other_error)
                        .setUniqueID(uniqueID)
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    
                    let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setError(error)
                        .setMonitorMessage("server data nil error")
                        .setOuterCode(kErrCodeUndefine)
                        .setOuterMessage(kErrMsgUndefine)
                    callback(.failure(error: apiErr))
                    return
                }
                do {
                    let json = try JSON(data: data)
                    guard json["code"].int == 0 else {
                        let msg = json["msg"].stringValue
                        let code = json["code"].int ?? kErrCodeUndefine
                        
                        OPMonitor(mcode(from: code))
                            .setUniqueID(uniqueID)
                            .setResultTypeFail()
                            .setErrorCode("\(code)")
                            .setErrorMessage(msg)
                            .flush()
                        
                        let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("server err: \(code)-\(msg)")
                            .setOuterCode(code)
                            .setOuterMessage(msg)
                        callback(.failure(error: apiErr))
                        return
                    }
                    OPMonitor(APIMonitorCodeFaceLiveness.upload_info_success)
                        .setUniqueID(uniqueID)
                        .setResultTypeSuccess()
                        .flush()
                    callback(.success(data: nil))
                } catch {
                    OPMonitor(APIMonitorCodeFaceLiveness.upload_info_other_error)
                        .setUniqueID(uniqueID)
                        .setResultTypeFail()
                        .setError(error)
                        .flush()
                    
                    let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setError(error)
                        .setMonitorMessage("server data parse error")
                        .setOuterCode(kErrCodeUndefine)
                        .setOuterMessage(kErrMsgUndefine)
                    callback(.failure(error: apiErr))
                }
            },
            eventName: "uploadAuthInfo", requestTracing: trace
        )
        
        func mcode(from serverCode: Int) -> OPMonitorCodeProtocol {
            switch serverCode {
            case 10001:
                return APIMonitorCodeFaceLiveness.upload_info_fail
            case 10002:
                return APIMonitorCodeFaceLiveness.update_info_name_mismatch
            case 10003:
                return APIMonitorCodeFaceLiveness.update_info_code_mismatch
            case 10004:
                return APIMonitorCodeFaceLiveness.update_info_mobile_mismatch
            case 10100:
                return APIMonitorCodeFaceLiveness.upload_info_param_error
            default:
                return APIMonitorCodeFaceLiveness.upload_info_other_error
            }
        }
    }
    
    /// 在线有源：开始活体认证
    func startFaceIdentify(
        params: OpenStartFaceIdentifyParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenOnlineFaceVerifyResult>) -> Void
    ) {
        context.apiTrace.info("startFaceIdentify start call, authType=\(String(describing: params.authType)), session=\(String(describing: params.session?.mask())), identityName=\(String(describing: params.identityName?.mask())), identityCode=\(String(describing: params.identityCode?.mask()))")
        let authTypeString = params.authType ?? FaceIdentifyAuthType.currentUser.rawValue
        guard let authType = FaceIdentifyAuthType(rawValue: authTypeString) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                .setMonitorMessage("Invalid auth type")
                .setErrno(OpenAPICommonErrno.invalidParam(.invalidParam(param: "authType")))
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        context.apiTrace.info("startFaceIdentify, uniqueID=\(uniqueID)")

        // 非登录用户的有源人脸认证，不需要 checkAuth
        if authType == .twoElement {
            context.apiTrace.info("startFaceIdentify, start twoElement identify")
            guard let identityName = params.identityName else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("Invalid name")
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "identityName")))
                callback(.failure(error: error))
                return
            }
            guard let identityCode = params.identityCode else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                    .setMonitorMessage("Invalid identity")
                    .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "identityCode")))
                callback(.failure(error: error))
                return
            }
            
            let sessionHeader = GadgetSessionFactory.storage(for: gadgetContext).sessionHeader
            var h5Session:String?
            var minaSession:String?
            
            guard let session = sessionHeader["Session-Value"] else{
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("Invalid session")
                    .setErrno(OpenAPIBiologyErrno.failedToGetSession)
                callback(.failure(error: error))
                return
            }
            if let type = sessionHeader["Session-Type"], type == "h5_session" {
                h5Session = session
            }else {
                minaSession = session
            }
            context.apiTrace.info("twoElement identify h5Session:\(h5Session?.mask()), minaSession:\(minaSession?.mask())")
            let encryptedName = encrypt(identityName)
            let encryptedCode = encrypt(identityCode)

            let ticketParam = VerifyTicketParam(ticketType: .identified,
                                            uid: "",
                                            h5Session: h5Session,
                                            minaSession: minaSession,
                                            name: encryptedName,
                                            code: encryptedCode)
            getTicketAndIdentify(authType: authType,
                                 ticketParam: ticketParam,
                                 context: context,
                                 gadgetContext: gadgetContext,
                                 callback: callback)
            return
        }

        // 当前登录用户有源人脸认证，检查实名信息是否上传并通过
        context.apiTrace.info("startFaceIdentify, start currentUser identify")
        var checkParam: [String: Any] = ["app_id": uniqueID.appID]
        checkParam["session"] = params.session
        checkAuth(param: checkParam, gadgetContext: gadgetContext) {
            [weak self] (result) in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("nil self")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            switch result {
            case .success(let uid):
                context.apiTrace.info("startFaceIdentify, checkAuth success, uid.count:\(uid.count)")
                // 2. 请求 Ticket 并唤起人脸认证
                let ticketParam = VerifyTicketParam(ticketType: .identified,
                                                    uid: uid,
                                                    h5Session: params.session,
                                                    minaSession: nil,
                                                    name: nil,
                                                    code: nil)
                self.getTicketAndIdentify(authType: authType,
                                          ticketParam: ticketParam,
                                          context: context,
                                          gadgetContext: gadgetContext,
                                          callback: callback)
            case .failure(let error):
                callback(.failure(error: error.apiError))
            }
        }
    }

    // 获取 Ticket 并开始有源在线活体比对
    func getTicketAndIdentify(authType: FaceIdentifyAuthType,
                                      ticketParam: VerifyTicketParam,
                                      context: OpenAPIContext,
                                      gadgetContext: GadgetAPIContext,
                                      callback: @escaping (OpenAPIBaseResponse<OpenOnlineFaceVerifyResult>) -> Void) {
        context.apiTrace.info("startFaceIdentify, start getUserTicket,authType:\(authType.rawValue), h5Session:\(String(describing: ticketParam.h5Session?.mask())), minaSession:\(String(describing: ticketParam.minaSession?.mask()))")
        getUserTicket(
            authType: authType,
            param: ticketParam,
            gadgetContext: gadgetContext
        ) { [weak self] (result1) in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("nil self")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            switch result1 {
            case .success(let ticket):
                // 进行在线活体比对（有源）
                self.onlineFaceVerify(
                    ticket: ticket,
                    context: context,
                    gadgetContext: gadgetContext
                ) { (error) in
                    if let apiErr = error {
                        callback(.failure(error: apiErr))
                        return
                    }
                    let resultData = OpenOnlineFaceVerifyResult(reqNo: ticket.ticket)
                    callback(.success(data: resultData))
                }
            case .failure(let error):
                callback(.failure(error: error.apiError))
            }
        }
    }
    
    /// 在线无源：开始活体认证
    func startFaceVerify(
        params: OpenStartFaceVerifyParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenOnlineFaceVerifyResult>) -> Void
    ) {
        // 1. 请求活体 ticket
        let actionSceneEnable = actionsSceneEnable(uniqueId: gadgetContext.uniqueID)
        context.apiTrace.info("startFaceVerify actionSceneEnable:\(actionSceneEnable), actionsScene:\(params.actionsScene)")
        let ticketParam = VerifyTicketParam(ticketType: .unidentified,
                                            uid: params.userId,
                                            h5Session: params.session,
                                            minaSession: nil,
                                            actionsScene: actionSceneEnable ? params.actionsScene:nil,
                                            name: nil,
                                            code: nil)
        getUserTicket(authType: .currentUser, param: ticketParam, gadgetContext: gadgetContext) {
            [weak self] result1 in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("nil self")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            switch result1 {
            case .success(let ticket):
                // 2. 进行在线活体比对（无源）
                self.onlineFaceVerify(
                    ticket: ticket,
                    context: context,
                    gadgetContext: gadgetContext
                ) { (error) in
                    if let apiErr = error {
                        callback(.failure(error: apiErr))
                        return
                    }
                    callback(.success(data: OpenOnlineFaceVerifyResult(reqNo: ticket.ticket)))
                }
            case .failure(let error):
                callback(.failure(error: error.apiError))
            }
        }
    }
    
    /// 离线无源：检查当前离线无源环境是否可用
    func checkLocalFaceVerify(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let delegate = EMAProtocolProvider.getLiveFaceDelegate() else {
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setUniqueID(context.uniqueID)
                .setResultTypeFail()
                .setErrorMessage("client not impl the api")
                .flush()
            let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("Client NOT Impl the API.")
                .setOuterCode(kErrCodeUndefine)
                .setOuterMessage("Client NOT Impl the API.")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: apiErr))
            return
        }
        context.apiTrace.info("checkLocalFaceVerify start call")
        delegate.checkOfflineFaceVerifyReady { error in
            if let err = error {
                let errorCode = (err as NSError).code
                let msg = err.localizedDescription
                OPMonitor(mcode(from: errorCode))
                    .setUniqueID(context.uniqueID)
                    .setResultTypeFail()
                    .setError(err)
                    .flush()
                
                let apiErr = OpenAPIError(code: FaceVerifyErrorCode(rawValue: errorCode) ?? FaceVerifyErrorCode.internalError)
                    .setError(err)
                    .setMonitorMessage("checkLocalFaceVerify failed")
                    .setOuterCode(errorCode)
                    .setOuterMessage(msg)
                    .setErrno(FaceVerifyUtils.splitCertSdkError(certErrorCode: errorCode, msg: msg))
                callback(.failure(error: apiErr))
            } else {
                OPMonitor(APIMonitorCodeFaceLiveness.offline_check_success)
                    .setUniqueID(context.uniqueID)
                    .setResultTypeSuccess()
                    .flush()
                
                callback(.success(data: nil))
            }
        }
        
        func mcode(from sdkErrorCode: Int) -> OPMonitorCodeProtocol {
            switch sdkErrorCode {
            case -5003:
                return APIMonitorCodeFaceLiveness.offline_check_not_downloaded
            case -5004:
                return APIMonitorCodeFaceLiveness.offline_check_no_model
            case -5005:
                return APIMonitorCodeFaceLiveness.offline_check_md5_error
            default:
                return APIMonitorCodeFaceLiveness.offline_check_other_error
            }
        }
    }
    
    /// 离线无源：加载活体资源（下载相关模型文件）
    func prepareLocalFaceVerify(
        params: OpenPrepareLocalFaceVerifyParams,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        guard let delegate = EMAProtocolProvider.getLiveFaceDelegate() else {
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setUniqueID(context.uniqueID)
                .setResultTypeFail()
                .setErrorMessage("client not impl the api")
                .flush()
            let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("Client NOT Impl the API.")
                .setOuterCode(kErrCodeUndefine)
                .setOuterMessage("Client NOT Impl the API.")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: apiErr))
            return
        }
        context.apiTrace.info("prepareLocalFaceVerify start call, timeout: \(params.timeout)")

        if !Thread.isMainThread {
            assertionFailure("this method should be called in main thread")
        }
        
        let monitor = OPMonitor(APIMonitorCodeFaceLiveness.offline_prepare_timeout)
            .setUniqueID(context.uniqueID)
            .timing()
        
        var timeout = params.timeout
        timeout = min(max(0, timeout), kOfflinePrepareTimeoutMax)
        
        let info = LocalVerifyPrepareTimerInfo(
            monitor: monitor,
            callback: callback
        )
        
        let timer = Timer(
            timeInterval: timeout,
            target: self,
            selector: #selector(p_offlinePrepareTimeout(_:)),
            userInfo: info,
            repeats: false
        )
        RunLoop.main.add(timer, forMode: .common)
        
        offlinePrepareTimers.append(timer)
        
        // 如果已经启动了下载，只需添加超时监听，等待回调结果即可
        if offlinePrepareTimers.count > 1 {
            context.apiTrace.info("prepareLocalFaceVerify already has call")
            return
        }
        context.apiTrace.info("start call certSDK prepareOfflineFaceVerify")
        delegate.prepareOfflineFaceVerify {
            [weak self] error in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("nil self")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            BDPExecuteOnMainQueue {
                // 对所有未超时的调用一次性进行回调
                for obj in self.offlinePrepareTimers {
                    guard let info = obj.userInfo as? LocalVerifyPrepareTimerInfo else {
                        continue
                    }
                    
                    // 废弃 timer
                    obj.invalidate()
                    
                    if let err = error {
                        let errorCode = (err as NSError).code
                        let msg = err.localizedDescription
                        info.monitor.setMonitorCode(mcode(from: errorCode))
                            .setResultTypeFail()
                            .setError(err)
                            .timing()
                            .flush()
                        
                        let apiErr = OpenAPIError(code: FaceVerifyErrorCode(rawValue: errorCode) ?? FaceVerifyErrorCode.internalError)
                            .setMonitorMessage("")
                            .setError(err)
                            .setOuterCode(errorCode)
                            .setOuterMessage(msg)
                            .setErrno(FaceVerifyUtils.splitCertSdkError(certErrorCode: errorCode, msg: msg))
                        info.callback(.failure(error: apiErr))
                    } else {
                        info.monitor.setMonitorCode(APIMonitorCodeFaceLiveness.offline_prepare_success)
                            .setResultTypeSuccess()
                            .timing()
                            .flush()
                        
                        info.callback(.success(data: nil))
                    }
                }
                // 清除所有等待回调的调用
                self.offlinePrepareTimers.removeAll()
            }
        }
        
        func mcode(from sdkErrorCode: Int) -> OPMonitorCodeProtocol {
            switch sdkErrorCode {
                case -5000:
                    return APIMonitorCodeFaceLiveness.offline_prepare_download_failed
                case -5001:
                    return APIMonitorCodeFaceLiveness.offline_prepare_not_needed
                default:
                    return APIMonitorCodeFaceLiveness.offline_prepare_other_error
            }
        }
    }
    
    /// 离线无源：开始活体认证
    func startLocalFaceVerify(
        params: OpenStartLocalFaceVerifyParams,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
       
        let callback: (Result<Data, APIErrorWrapper>) -> Void = { [weak self] result in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setMonitorMessage("nil self")
                    .setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
                return
            }
            switch result {
            case .success(let imageData):
                BDPExecuteOnMainQueue {
                    // 2. 开始活体认证
                    self.offlineFaceVerify(
                        baseImage: imageData,
                        certAppId: params.certAppId,
                        scene: params.scene,
                        ticket: params.ticket,
                        mode: params.mode,
                        motionTypes: params.motionTypes,
                        context: context
                    ) { error in
                        if let apiErr = error {
                            callback(.failure(error: apiErr))
                        } else {
                            callback(.success(data: nil))
                        }
                    }
                }
            case .failure(let error):
                callback(.failure(error: error.apiError))
            }
        }

        // 1. 异步获取基准图 imageData
        standardAsyncFetchImageData(path: params.path, gadgetContext: gadgetContext, context: context, callback: callback)
    }
    
    // MARK: - detail funcs
    
    /// 离线活体（无源）加载超时
    @objc
    func p_offlinePrepareTimeout(_ sender: Timer) {
        guard let info = sender.userInfo as? LocalVerifyPrepareTimerInfo else {
            return
        }
        
        offlinePrepareTimers.removeAll { $0 == sender }
        sender.invalidate()
        
        info.monitor.setMonitorCode(APIMonitorCodeFaceLiveness.offline_prepare_timeout)
            .setErrorCode("\(kErrCodeOfflinePrepareTimeout)")
            .setErrorMessage("offline prepare timeout")
            .setResultTypeFail()
            .timing()
            .flush()
        
        let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("offline prepare timeout")
            .setOuterCode(kErrCodeOfflinePrepareTimeout)
            .setOuterMessage("offline prepare timeout")
            .setErrno(OpenAPIBiologyErrno.downloadTimeout)
        info.callback(.failure(error: apiErr))
    }
    
    /// 无源比对：三要素信息认证检查
    func checkAuth(
        param: [String: Any],
        gadgetContext: GadgetAPIContext,
        callback: @escaping (Result<String, APIErrorWrapper>) -> Void
    ) {
        func handleResult(data: Data?, response: URLResponse?, error: Error?, callback: @escaping (Result<String, APIErrorWrapper>) -> Void) {
            let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
            guard let data = data else {
                OPMonitor(APIMonitorCodeFaceLiveness.check_has_authed_other_error)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                
                let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setError(error)
                    .setMonitorMessage("server data nil error(logid:\(logID)")
                    .setOuterCode(kErrCodeUndefine)
                    .setOuterMessage(kErrMsgUndefine)
                    .setErrno(OpenAPIBiologyErrno.failedIdentity)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
                return
            }
            do {
                let json = try JSON(data: data)
                guard json["code"].int == 0 else {
                    let msg = json["msg"].stringValue
                    let code = json["code"].int ?? kErrCodeUndefine
                    
                    OPMonitor(mcode(from: code))
                        .setUniqueID(gadgetContext.uniqueID)
                        .setResultTypeFail()
                        .setErrorCode("\(code)")
                        .setErrorMessage(msg)
                        .flush()
                    
                    let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("server err: \(code)-\(msg)")
                        .setOuterCode(code)
                        .setOuterMessage("server biz error(logid:\(logID), code:\(code), msg:\(msg)")
                        .setErrno(OpenAPIBiologyErrno.serverError(errorString: msg, errorCode: "\(code)"))
                    callback(.failure(APIErrorWrapper(apiError: apiErr)))
                    return
                }
                
                OPMonitor(APIMonitorCodeFaceLiveness.check_has_authed_success)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeSuccess()
                    .flush()
                
                let uid = json["data"]["verifyUid"].stringValue
                callback(.success(uid))
            } catch {
                OPMonitor(APIMonitorCodeFaceLiveness.check_has_authed_other_error)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                
                let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setError(error)
                    .setMonitorMessage("server data parse error(logid:\(logID)")
                    .setOuterCode(kErrCodeUndefine)
                    .setOuterMessage(kErrMsgUndefine)
                    .setErrno(OpenAPIBiologyErrno.failedIdentity)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
            }
        }
        
        let url = EMAAPI.hasAuthURL()
        let trace = EMARequestUtil.generateRequestTracing(gadgetContext.uniqueID)
        let header = newNetworkSessionHeader(trace: trace, h5Session: param["session"] as? String)
        if OPECONetworkInterface.enableECO(path: OPNetworkAPIPath.humanAuthIdentity) {
            OPECONetworkInterface.postForOpenDomain(url: url, context: OpenECONetworkAppContext(trace: trace, uniqueId: gadgetContext.uniqueID, source: .api), params: param, header: header) { _, data, response, error in
                handleResult(data: data, response: response, error: error, callback: callback)
            }
        } else {
            EMANetworkManager.shared().requestUrl(
                url,
                method: HTTPMethod.post.rawValue,
                params: param,
                header: header,
                completionHandler: { (data, response, error) in
                    handleResult(data: data, response: response, error: error, callback: callback)
                },
                eventName: "hasAuthed", requestTracing: trace
            )
        }
        
        func mcode(from serverCode: Int) -> OPMonitorCodeProtocol {
            switch serverCode {
            case 10301:
                return APIMonitorCodeFaceLiveness.check_has_authed_not_auth
            case 10100:
                return APIMonitorCodeFaceLiveness.check_has_authed_param_error
            default:
                return APIMonitorCodeFaceLiveness.check_has_authed_other_error
            }
        }
    }
    
    /// 在线活体认证票据请求（有源 & 无源）
    func getUserTicket(
        authType: FaceIdentifyAuthType,
        param: VerifyTicketParam,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (Result<VerifyTicket, APIErrorWrapper>) -> Void
    ) {
        func handleResult(data: Data?, response: URLResponse?, error: Error?, callback: @escaping (Result<VerifyTicket, APIErrorWrapper>) -> Void) {
            let logID = response?.allHeaderFields["x-tt-logid"] as? String ?? ""
            guard let data = data else {
                OPMonitor(APIMonitorCodeFaceLiveness.get_user_ticket_error)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                
                let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setError(error)
                    .setMonitorMessage("server data nil error(logid:\(logID))")
                    .setOuterCode(kErrCodeUndefine)
                    .setOuterMessage(kErrMsgUndefine)
                    .setErrno(OpenAPIBiologyErrno.failedUserTicket)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
                return
            }
            do {
                let json = try JSON(data: data)
                guard json["code"].int == 0 else {
                    let msg = json["msg"].stringValue
                    let code = json["code"].int ?? kErrCodeUndefine
                    
                    OPMonitor(mcode(from: code))
                        .setUniqueID(gadgetContext.uniqueID)
                        .setResultTypeFail()
                        .setErrorCode("\(code)")
                        .setErrorMessage(msg)
                        .flush()
                    
                    let apiErr = OpenAPIError(code: FaceVerifyErrorCode(rawValue: code) ?? FaceVerifyErrorCode.internalError)
                        .setMonitorMessage("server biz error(logid:\(logID), code:\(code), msg:\(msg)")
                        .setOuterCode(code)
                        .setOuterMessage(msg)
                        .setErrno(OpenAPIBiologyErrno.serverError(errorString: msg, errorCode: "\(code)"))
                    callback(.failure(APIErrorWrapper(apiError: apiErr)))
                    return
                }
                OPMonitor(APIMonitorCodeFaceLiveness.get_user_ticket_success)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeSuccess()
                    .flush()
                
                let rawData = try json["data"].rawData()
                let ticket = try JSONDecoder().decode(VerifyTicket.self, from: rawData)
                callback(.success(ticket))
            } catch {
                OPMonitor(APIMonitorCodeFaceLiveness.get_user_ticket_error)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setError(error)
                    .flush()
                
                let apiErr = OpenAPIError(code: FaceVerifyErrorCode.jsonParseFail)
                    .setError(error)
                    .setMonitorMessage("server data parse error(logid:\(logID))")
                    .setOuterCode(kErrCodeUndefine)
                    .setOuterMessage(kErrMsgUndefine)
                    .setErrno(OpenAPIBiologyErrno.failedUserTicket)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
            }
        }
        
        let path = authType == .currentUser ? OPNetworkAPIPath.humanAuthUserTicket : OPNetworkAPIPath.humanAuthUserTicketWithCode
        let url = authType == .currentUser ? EMAAPI.getUserTicketURL() : EMAAPI.getUserTicketWithCodeURL()
        let trace = EMARequestUtil.generateRequestTracing(gadgetContext.uniqueID)
        let jsonParams = param.toServerJsonDict()
        let header = newNetworkSessionHeader(trace: trace, h5Session: param.h5Session, minaSession: param.minaSession)
        if OPECONetworkInterface.enableECO(path: path) {
            OPECONetworkInterface.postForOpenDomain(url: url, context: OpenECONetworkAppContext(trace: trace, uniqueId: gadgetContext.uniqueID, source: .api), params: jsonParams, header: header) { _, data, response, error in
                handleResult(data: data, response: response, error: error, callback: callback)
            }
        } else {
            EMANetworkManager.shared().requestUrl(
                url,
                method: HTTPMethod.post.rawValue,
                params: jsonParams,
                header: header,
                completionHandler: { (data, response, error) in
                    handleResult(data: data, response: response, error: error, callback: callback)
                },
                eventName: "getUsetTicket", requestTracing: trace
            )
        }
        
        func mcode(from serverCode: Int) -> OPMonitorCodeProtocol {
            switch serverCode {
            case 10100:
                return APIMonitorCodeFaceLiveness.get_user_ticket_param_error
            default:
                return APIMonitorCodeFaceLiveness.get_user_ticket_error
            }
        }
    }
    
    /// 在线活体（有源 + 无源）
    func onlineFaceVerify(
        ticket: VerifyTicket,
        context: OpenAPIContext,
        gadgetContext: GadgetAPIContext,
        callback: @escaping (OpenAPIError?) -> Void
    ) {
        guard let delegate = EMAProtocolProvider.getLiveFaceDelegate() else {
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setUniqueID(context.uniqueID)
                .setResultTypeFail()
                .setErrorMessage("client not impl the api")
                .flush()
            let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("Client NOT Impl the API.")
                .setOuterCode(kErrCodeUndefine)
                .setOuterMessage("Client NOT Impl the API.")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(apiErr)
            return
        }
        //兜底开关，默认不打开，用于解决在线活体实名页面有两个返回箭头问题
        let disablePresent = EMAFeatureGating.boolValue(forKey: "openplatform.api.onlinefaceverify.present.disable")
        var params = ticket.toSDKJsonDict()
        if !disablePresent {
            params["present_to_show"] = true
        }
        delegate.checkFaceLiveness(params) {
            let shouldShow = gadgetContext.isVCForeground
            context.apiTrace.info("shouldShow: \(shouldShow)")
            return shouldShow
        } block: { (result, errorDict) in
            let code = result?["status_code"] as? Int
            guard code == 0 else {
                let errCode = (errorDict?["errorCode"] as? Int) ?? kErrCodeUndefine
                let errMsg = (errorDict?["errorMessage"] as? String) ?? ""
                
                OPMonitor(mcode(from: errCode))
                    .setUniqueID(context.uniqueID)
                    .setResultTypeFail()
                    .addCategoryValue("ticket", ticket.ticket)
                    .setErrorCode("\(errCode)")
                    .setErrorMessage(errMsg)
                    .flush()
                
                let apiErr = OpenAPIError(code: FaceVerifyErrorCode(rawValue: errCode) ?? FaceVerifyErrorCode.internalError)
                    .setMonitorMessage("face verify failed, code: \(errCode), msg: \(errMsg)")
                    .setOuterCode(errCode)
                    .setOuterMessage(errMsg)
                    .setErrno(FaceVerifyUtils.splitCertSdkError(certErrorCode: errCode, msg: errMsg))
                callback(apiErr)
                return
            }
            
            OPMonitor(APIMonitorCodeFaceLiveness.face_live_success)
                .setUniqueID(context.uniqueID)
                .setResultTypeSuccess()
                .addCategoryValue("ticket", ticket.ticket)
                .flush()
            
            callback(nil)
        }
        
        func mcode(from serverCode: Int) -> OPMonitorCodeProtocol {
            switch serverCode {
            case -1003:
                return APIMonitorCodeFaceLiveness.face_live_user_cancel_after_error
            case -1006:
                return APIMonitorCodeFaceLiveness.face_live_user_cancel
            case -3000, -3002, -3003:
                return APIMonitorCodeFaceLiveness.face_live_device_interrupt
            default:
                return APIMonitorCodeFaceLiveness.face_live_internal_error
            }
        }
    }

    /// 根据 ttpath 异步获取基准图的 imageData
    /// 经过 FileSystem 标准化改造的
    func standardAsyncFetchImageData(
        path: String,
        gadgetContext: GadgetAPIContext,
        context: OpenAPIContext,
        callback: @escaping (Result<Data, APIErrorWrapper>) -> Void
    ) {
        BDPExecuteOnGlobalQueue {
            do {
                /// 准备数据
                let file = try FileObject(rawValue: path)
                let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID, trace: context.apiTrace, tag: "startLocalFaceVerify")

                guard file.isValidTTFile() else {
                    let errMsg = "convert image path failed: \(path)"
                    OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                        .setUniqueID(gadgetContext.uniqueID)
                        .setResultTypeFail()
                        .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                        .setErrorMessage(errMsg)
                        .flush()

                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                        .setOuterMessage(errMsg)
                        .setErrno(OpenAPIBiologyErrno.failedReadImage)
                    callback(.failure(APIErrorWrapper(apiError: error)))
                    return
                }

                /// 获取文件信息
                let attributes = try FileSystem.attributesOfFile(file, context: fsContext) as NSDictionary
                let fileSize = attributes.fileSize()

                /// 判断大小
                guard fileSize > 0, fileSize <= kOfflineVerifyMaxImageSize else {
                    let errMsg = "invalid image size: \(String(describing: fileSize))"
                    OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                        .setUniqueID(gadgetContext.uniqueID)
                        .setResultTypeFail()
                        .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                        .setErrorMessage(errMsg)
                        .flush()

                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                        .setOuterMessage(errMsg)
                        .setErrno(OpenAPIBiologyErrno.failedReadImage)
                    callback(.failure(APIErrorWrapper(apiError: error)))
                    return
                }

                /// 读取文件数据
                let data = try FileSystem.readFile(file, position: nil, length: nil, context: fsContext)

                /// 读取成功
                callback(.success(data))
            /// 原逻辑对齐: 获取 storageModule 失败, 新逻辑包含 fileinfo 解析失败
            } catch FileSystemError.biz(.resolveStorageModuleFailed(_)),
                    FileSystemError.biz(.resolveLocalFileInfoFailed(_, _)) {
                let errMsg = "BDPStorageModuleProtocol not support"
                OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                    .setErrorMessage(errMsg)
                    .flush()

                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                    .setOuterMessage(errMsg)
                    .setErrno(OpenAPIBiologyErrno.failedReadImage)
                callback(.failure(APIErrorWrapper(apiError: error)))
            /// 原逻辑对齐: 获取路径失败
            } catch FileSystemError.invalidFilePath(_),
                    FileSystemError.biz(.resolveFilePathFailed(_, _)) {
                let errMsg = "convert image path failed: \(path)"
                OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                    .setErrorMessage(errMsg)
                    .flush()

                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                    .setOuterMessage(errMsg)
                    .setErrno(OpenAPIBiologyErrno.failedReadImage)
                callback(.failure(APIErrorWrapper(apiError: error)))
            /// 其他系统错误，按照原逻辑思路返回 image read error
            } catch let error as FileSystemError {
                let errMsg = "image read error: \(error.errorMessage)"
                OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setResultTypeFail()
                    .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                    .setErrorMessage(errMsg)
                    .flush()

                let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setError(error)
                    .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                    .setOuterMessage(errMsg)
                    .setErrno(OpenAPIBiologyErrno.failedReadImage)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
            /// 对齐原逻辑思路，其他错误，统一提示 error msg
            } catch {
                let errMsg = "image read error: \(error)"
                OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_img_read_failed)
                    .setUniqueID(gadgetContext.uniqueID)
                    .setError(error)
                    .setResultTypeFail()
                    .setErrorCode("\(kErrCodeOfflineVerifyImgReadFailed)")
                    .setErrorMessage(errMsg)
                    .flush()

                let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setError(error)
                    .setOuterCode(kErrCodeOfflineVerifyImgReadFailed)
                    .setOuterMessage(errMsg)
                    .setErrno(OpenAPIBiologyErrno.failedReadImage)
                callback(.failure(APIErrorWrapper(apiError: apiErr)))
            }
        }
    }
    
    
    // 离线活体（无源）
    func offlineFaceVerify(
        baseImage: Data,
        certAppId: String? = nil,
        scene: String? = nil,
        ticket: String? = nil,
        mode: Int? = 0,
        motionTypes: [String]? = nil,
        context: OpenAPIContext,
        callback: @escaping (OpenAPIError?) -> Void
    ) {
        guard let delegate = EMAProtocolProvider.getLiveFaceDelegate() else {
            OPMonitor(APIMonitorCodeFaceLiveness.internal_error)
                .setUniqueID(context.uniqueID)
                .setResultTypeFail()
                .setErrorMessage("client not impl the api")
                .flush()
            let apiErr = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("Client NOT Impl the API.")
                .setOuterCode(kErrCodeUndefine)
                .setOuterMessage("Client NOT Impl the API.")
                .setErrno(OpenAPICommonErrno.internalError)
            callback(apiErr)
            return
        }
        
        var startParam: [String: Any] = ["image_compare": baseImage]
        if let certAppId = certAppId {
            startParam["certAppId"] = certAppId
        }
        if let mode = mode {
            startParam["mode"] = mode
        }
        if let scene = scene {
            startParam["scene"] = scene
        }
        if let ticket = ticket {
            startParam["ticket"] =  ticket
        }
        //离线活体失败上传失败人脸数据
        startParam["log_mode"] =  true
        /*
         motions支持用户自定义活体动作：
         nil：随机动作
         []：零动作
         [xx]：指定xx动作，超出3个，走随机动作
        */
        context.apiTrace.info("offlineFaceVerify origin motionTypes:\(String(describing: motionTypes))")
        switch motionTypes {
        case .none,.some([]):
            startParam["motions"] = motionTypes
        case .some(let elements):
            let mapArray = elements.map { element in
                if element == "SHARK" {
                    return "SHAKE"
                }
                return element
            }
            var resultMotionTypes:Set<Int> = []
            for item in mapArray {
                guard let motionType = MotionType(rawValue: item) else {
                    let apiErr = OpenAPIError(errno: OpenAPICommonErrno.invalidParam(.invalidParam(param: "motionTypes")))
                        .setMonitorMessage("motionTypes has invalid item:\(item)")
                    callback(apiErr)
                    return
                }
                resultMotionTypes.insert(motionType.typeInt)
            }
            //超过3个动作，走随机动作
            if resultMotionTypes.count > 3 {
                startParam["motions"] = nil
            }else {
                startParam["motions"] = Array(resultMotionTypes)
            }
        }
        context.apiTrace.info("offlineFaceVerify result motionTypes:\(String(describing: startParam["motions"]))")
        
        delegate.startOfflineFaceVerify(
            startParam) { error in
            if let err = error {
                let code = (err as NSError).code
                let msg = err.localizedDescription
                OPMonitor(mcode(from: code))
                    .setUniqueID(context.uniqueID)
                    .setResultTypeFail()
                    .setError(err)
                    .flush()
                
                let apiErr = OpenAPIError(code: FaceVerifyErrorCode(rawValue: code) ?? FaceVerifyErrorCode.internalError)
                    .setMonitorMessage("local verfiy failed, code: \(code), msg: \(msg)")
                    .setError(err)
                    .setOuterCode(code)
                    .setOuterMessage(msg)
                    .setErrno(FaceVerifyUtils.splitCertSdkError(certErrorCode: code, msg: msg))
                callback(apiErr)
                return
            }
            
            OPMonitor(APIMonitorCodeFaceLiveness.offline_verify_success)
                .setUniqueID(context.uniqueID)
                .setResultTypeSuccess()
                .flush()
            callback(nil)
        }
        
        func mcode(from sdkErrorCode: Int) -> OPMonitorCodeProtocol {
            switch sdkErrorCode {
            case -5010:
                return APIMonitorCodeFaceLiveness.offline_verify_liveness_init_error
            case -5011:
                return APIMonitorCodeFaceLiveness.offline_verify_liveness_failed
            case -5020:
                return APIMonitorCodeFaceLiveness.offline_verify_compare_init_failed
            case -5021:
                return APIMonitorCodeFaceLiveness.offline_verify_compare_failed
            default:
                return APIMonitorCodeFaceLiveness.offline_verify_other_error
            }
        }
    }

    private func encrypt(_ plainString: String) -> String? {
        let releasePublicKey = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsLBauw2Kv4S/nI68/OJE
aCS86YqGoiwUZdNoSgVp5Abhd7QB7T70XWH6C8U+Ha1J5t12FZFGlujJDD3M7fWJ
hpsnUxk7WSNUpiz7dx9ZU0+w7RrfwBduXQF0SWjuETazbOfS67bYt6eDiqNOAhM0
KvMVpR0/P3rjCL6ZzYe1OqCQihuotd0DBJocZS+w51LB49kwgbcxb9qi62LQZp8W
PNmNA/T2lq9xJobxbQviApthFUt5usfa1oVPVnOGMhTTkQShsMsBLVP/wRiBgSDY
avjwJ3j69Dq9H4eQ1srl3z3a0FOQiuDdSWRm6EkNUUyN7wEuUO8h8BwWF126Vcj+
DwIDAQAB
-----END PUBLIC KEY-----
"""
        let stagingPublicKey = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo4CxnF7/RyWS9+otmgW6
zUY0yip42qPO3eiRqnqRlNIjhR75M4wbZAX8at3dt/Go6Y5V/cl0sPZgodaBgLa0
v5UCbGKxgoeMGFbn1opgeDoGvGKLdaClhDySQrU9AuSJhfnCvCM89mkxvWrA5xFg
sWow1/WyhHny6l/mluxtVR14FmCVvmP45qz+ZhlizmV2Zc+Rrogh/p8VNbzkyoOC
nKM6iureT0sFI61xGbGLHpPuTxai/1+gZ29m3OMHFnJhe8JCx6HmOm13PMlrG7tI
Rnf4JGonDk5UU0nVFLJPrb5vnbTs9IeKcQJ92+PDPd/ZSBJe8BHhaYMRYsbxn7x3
LQIDAQAB
-----END PUBLIC KEY-----
"""

        var publicKey = EnvManager.env.isStaging ? stagingPublicKey : releasePublicKey
        let authConfig = try? userResolver.settings.setting(with: "openplatform_bio_auth_config")
        if let remotePublicKey = authConfig?["face_identify_pub_key"] as? String {
            publicKey = remotePublicKey
        }

        let rawData = plainString.data(using: .utf8)
        do {
            let encryptedData = try NSData.encryptData(rawData, publicKey: publicKey) as Data
            return encryptedData.base64EncodedString()
        } catch {
            return nil
        }
    }
    
    func networkSessionHeader() -> [String : String] {
       let session = EMARequestUtil.userSession()
       return [
           "Cookie": "session=\(session ?? "")"
       ]
   }

   // 新加入lark session和jssdk session
   func newNetworkSessionHeader(trace: OPTrace, h5Session: String?, minaSession: String? = nil) -> [String : String] {
       var header: [String: String] = [:]
       
       if let userService {
           if let larkSession = userService.user.sessionKey, !larkSession.isEmpty {
               header["session"] = larkSession
           }
       } else {
           trace.error("resolve PassportUserService failed")
       }
       
       if let h5Session = h5Session {
           header["Session-Type"] = "h5_session"
           header["Session-Value"] = h5Session
       } else if let minaSession = minaSession {
           header["Session-Type"] = "mina_session"
           header["Session-Value"] = minaSession
       }
       return header
   }
    
    private func actionsSceneEnable(uniqueId: OPAppUniqueID) -> Bool{
        do {
            let config: [String: Any] = try userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "faceAuthActionsScene"))
            let appID = uniqueId.appID
            if let appIds = config["appIds"] as? [String], appIds.contains(appID) {
                return true
            }
            return false
        } catch {
            return false
        }
    }
}
