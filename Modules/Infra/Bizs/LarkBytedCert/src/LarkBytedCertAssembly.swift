//
//  LarkBytedCertAssembly.swift
//  Lark
//
//  Created by tangyunfei.tyf on 2020/8/19.
//  Copyright © 2020 tangyunfei.tyf. All rights reserved.
//

import UIKit
import Foundation
import RustPB
import LKCommonsLogging
import LKCommonsTracker
import TTNetworkManager
import LarkFoundation
import byted_cert
import RxSwift
import LarkRustClient
import Swinject
import LarkEnv
import LarkAccountInterface
import OfflineResourceManager
import LarkLocalizations
import LarkContainer
import LarkExtensions
import LarkSetting

public final class LarkBytedCert {
    static var bytedCertManager: LarkBytedCertManager?
    static var bytedCertTracker: LarkBytedCertTracker?
    static var bytedCertLogger: LarkBytedCertLogger?

    static var isInited: Bool = false

    public init() {

        if !Self.isInited {
            BytedCertManager.initSDKV3()
            Self.isInited = true
        }

        if Self.bytedCertManager == nil {
            Self.bytedCertManager = LarkBytedCertManager()
        }
        BytedCertInterface.sharedInstance().bytedCertNetDelegate = Self.bytedCertManager

        if Self.bytedCertTracker == nil {
            Self.bytedCertTracker = LarkBytedCertTracker()
        }
        BytedCertInterface.sharedInstance().bytedCertTrackEventDelegate = Self.bytedCertTracker
        if Self.bytedCertLogger == nil {
            Self.bytedCertLogger = LarkBytedCertLogger()
        }
        BytedCertInterface.sharedInstance().bytedCertLoggerDelegate = Self.bytedCertLogger
        if EnvManager.env.isStaging {
            BytedCertManager.domain = "http://rc-boe.snssdk.com"
            BytedCertManager.isBoe = true
        }
        BytedCertWrapper.sharedInstance().setPreloadParams(
            [BytedCertParamAppId: OfflineResourceManager.config.appId,
             BytedCertParamTargetOffline: "",
             BytedCertParamAppVersion: OfflineResourceManager.config.appVersion,
             BytedCertParamDeviceId: OfflineResourceManager.config.deviceId,
             BytedCertParamCacheRootDirectory: OfflineResourceManager.config.cacheRootDirectory ?? ""
            ]
        )
        BytedCertWrapper.sharedInstance().setLanguage(LanguageManager.currentLanguage.languageIdentifier)
    }

    /// 无源人脸认证
    /// - Parameters:
    ///   - appId: 向实名认证中台申请的 appId
    ///   - ticket: 后端向实名认证中台获取，认证票据
    ///   - scene: 向实名认证中台申请的 scene
    ///   - mode: 模式
    ///      - 0:   绑定（上传基图）
    ///      - 1：认证（根据基图认证）
    ///   - callback: 回调
    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        mode: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ errMsg: String?) -> Void
    ) {
        doFaceLiveness(appId: appId,
                       ticket: ticket,
                       scene: scene,
                       mode: mode) { data, error in
            callback(data, error?.localizedDescription)
        }
    }

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        mode: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    ) {
        BytedCertWrapper.sharedInstance().doFaceLiveness(withParams: [
            BytedCertParamAppId: appId,
            BytedCertParamTicket: ticket,
            BytedCertParamScene: scene,
            BytedCertParamMode: mode
        ], extraParams: nil) { (data, error) in
            callback(data, error?.nsError())
        }
    }

    /// 有源人脸认证
    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        presentToShow: Bool,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ errmsg: String?) -> Void
    ) {
        doFaceLiveness(appId: appId,
                       ticket: ticket,
                       scene: scene,
                       identityName: identityName,
                       identityCode: identityCode,
                       presentToShow: presentToShow) { data, error in
            callback(data, error?.localizedDescription)
        }
    }

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        presentToShow: Bool,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    ) {
        BytedCertWrapper.sharedInstance().doFaceLiveness(withParams: [
            BytedCertParamAppId: appId,
            BytedCertParamTicket: ticket,
            BytedCertParamScene: scene,
            "present_to_show": presentToShow
        ], extraParams: [
            BytedCertParamIdentityName: identityName,
            BytedCertParamIdentityCode: identityCode
        ]) { (data, error) in
            callback(data, error?.nsError())
        }
    }

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ errmsg: String?) -> Void
    ) {
        doFaceLiveness(appId: appId, ticket: ticket, scene: scene) { data, error in
            callback(data, error?.localizedDescription)
        }
    }

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    ) {
        BytedCertWrapper.sharedInstance().doFaceLiveness(withParams: [
            BytedCertParamAppId: appId,
            BytedCertParamTicket: ticket,
            BytedCertParamScene: scene
        ], extraParams: nil) { (data, error) in
            callback(data, error?.nsError())
        }
    }

    public func checkFaceLivenessMessage(params: [AnyHashable: Any], shouldPresent: (() -> Bool)?, callback: @escaping ([AnyHashable: Any]?, [String: Any]?) -> Void) {
        BytedCertWrapper.sharedInstance().doFaceLiveness(withParams: params, shouldPresent: shouldPresent) { (data, error) in
            callback(data, error?.errorDic)
        }
    }

    public func doFaceLiveness(with params: [AnyHashable: Any], extraParams: [AnyHashable: Any], callback: @escaping ([AnyHashable: Any]?, Error?) -> Void) {
        BytedCertWrapper.sharedInstance().doFaceLiveness(withParams: params, extraParams: extraParams) { (result, error) in
            if let err = error {
                callback(
                    result,
                    BytedCertError.errorWithInstance(instance: err)
                )
            } else {
                callback(result, nil)
            }
        }
    }
    public func checkOfflineFaceVerifyReady(callback: @escaping (Error?) -> Void) {
        let ret = BytedCertWrapper.sharedInstance().checkModelAvailable()
        if ret == 0 {
            callback(nil)
        } else {
            let error = NSError(domain: "com.byted-cert.verify", code: Int(ret), userInfo: nil)
            callback(error)
        }
    }
    public func prepareOfflineFaceVerify(callback: @escaping (Error?) -> Void) {
        let revert = FeatureGatingManager.shared.featureGatingValue(with: "openplatform.face.prepare_add_check_revert")
        if !revert {
            BytedCertWrapper.sharedInstance().checkAndPreload { (ret, error) in
                if ret {
                    callback(nil)
                } else {
                    callback(BytedCertError.errorWithInstance(instance: error))
                }
            }
        }else{
            BytedCertWrapper.sharedInstance().preload { (ret, error) in
                if ret {
                    callback(nil)
                } else {
                    callback(BytedCertError.errorWithInstance(instance: error))
                }
            }
        }
    }
    public func startOfflineFaceVerify(_ params: [AnyHashable: Any], callback: @escaping (Error?) -> Void) {
        BytedCertWrapper.sharedInstance().doOfflineFaceLiveness(withParams: params) { (_, error) in
            if error == nil {
                callback(nil)
            } else {
                callback(BytedCertError.errorWithInstance(instance: error))
            }
        }
    }

    public func startFaceQualityDetect(withBeautyIntensity beautyIntensity: Int32,
                                       backCamera: Bool,
                                       faceAngleLimit: Int32,
                                       from fromViewController: UIViewController?,
                                       callback: @escaping (Error?, UIImage?, [AnyHashable: Any]?) -> Void) {
        BytedCertManager.beginFaceQualityDetect(withBeautyIntensity: beautyIntensity,
                                                backCamera: backCamera,
                                                faceAngleLimit: faceAngleLimit,
                                                from: fromViewController,
                                                completion: callback)
    }
}

fileprivate extension BytedCertError {
    var errorDic: [String: Any] {
        var dict = [String: Any]()
        dict["errorCode"] = self.errorCode
        dict["errorMessage"] = self.errorMessage
        return dict
    }

    static let domain = "com.byted-cert.verify"
    static let unknownCode = -9999
    static let unknownInfo = [NSLocalizedDescriptionKey: "unknown"]
    static func errorWithInstance(instance: BytedCertError?) -> Error {
        if let err = instance {
            var userInfo = err.errorDic
            let msg = "msg: \(err.errorMessage ?? ""), detail: \(err.detailErrorCode)-\(err.detailErrorMessage ?? "")"
            userInfo[NSLocalizedDescriptionKey] = msg
            return NSError(domain: domain, code: err.errorCode, userInfo: userInfo)
        } else {
            return NSError(domain: domain, code: unknownCode, userInfo: unknownInfo)
        }
    }

    func nsError() -> Error {
        let userInfo = [NSLocalizedDescriptionKey: errorMessage ?? "unknown"]
        return NSError(domain: Self.domain, code: errorCode, userInfo: userInfo)
    }
}

// MARK: manager
public final class LarkBytedCertManager: NSObject, BytedCertNetDelegate {

    @Injected private var deviceService: DeviceService
    @Provider private var rustService: RustService

    private static let logger = Logger.log(LarkBytedCertManager.self, category: "LarkBytedCertManager")

    private let disposeBag: DisposeBag = DisposeBag()

    public func upload(withResponse info: BytedCertNetInfo, callback: @escaping BytedCertHttpFinishWithResponse, timeout: TimeInterval) {

        guard let binaryDatas = info.binaryDatas,
              let binaryNames = info.binaryNames else {
            let result = BytedCertNetResponse(by: nil)
            callback(LarkBytedCertError.internalError("required params is nil"), nil, result)
            return
        }
        let initUrlString = info.url
        let method = info.method
        let params = info.params
        let queryDict = self.commonQueryDict()
        guard let initUrl = URL(string: initUrlString), let modifiedUrl = initUrl.lf.addQueryDictionary(queryDict) else {
            let result = BytedCertNetResponse(by: nil)
            callback(LarkBytedCertError.internalError("no valid url"), nil, result)
            return
        }

        var request = URLRequest(url: modifiedUrl)
        request.httpMethod = method
        let boundary = "Boundary+\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var data = Data()
        for(key, value) in params {
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)".data(using: .utf8)!)
        }
        for index in 0..<binaryDatas.count {
            if let key = binaryNames[index] as? String,
                let value = binaryDatas[index] as? Data {
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(key)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: multipart/form-data\r\n\r\n".data(using: .utf8)!)
                data.append(value)
            }
        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = data

        guard let stubHeader = TTNetworkUtil.md5Hex(data) else {
            let result = BytedCertNetResponse(by: nil)
            callback(LarkBytedCertError.internalError("no valid stub header"), nil, result)
            return
        }
        request.addValue(stubHeader, forHTTPHeaderField: "X-SS-STUB")

        let captchaMethod = self.methodForUrl(url: modifiedUrl)
        let captchaToken = self.generateCaptchaToken(method: captchaMethod, body: stubHeader)
        request.addValue(captchaToken, forHTTPHeaderField: "X-Sec-Captcha-Token")

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            Self.logger.debug("finished upload req: \(modifiedUrl.absoluteString)")
            let result = BytedCertNetResponse(by: response)
            callback(error, data, result)
        }
        task.resume()
    }

    public func requestForBinary(withResponse info: BytedCertNetInfo, callback: @escaping BytedCertHttpFinishWithResponse) {
        let initUrlString = info.url
        let method = info.method
        let params = info.params

        let queryDict = self.commonQueryDict()
        guard let initUrl = URL(string: initUrlString), let modifiedUrl = initUrl.lf.addQueryDictionary(queryDict) else {
            let result = BytedCertNetResponse(by: nil)
            callback(LarkBytedCertError.internalError("no valid url"), nil, result)
            return
        }
        var request = URLRequest(url: modifiedUrl)
        if method.uppercased() ==  "POST" {
            request.httpMethod = "POST"
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            if let formData = LarkBytedCertManagerUtil.encodeParametersToData(parameters: params) {
                request.httpBody = formData
                guard let stubHeader = TTNetworkUtil.md5Hex(formData) else {
                    let result = BytedCertNetResponse(by: nil)
                    callback(LarkBytedCertError.internalError("no valid stub header"), nil, result)
                    return
                }

                let captchaMethod = self.methodForUrl(url: modifiedUrl)
                let captchaToken = self.generateCaptchaToken(method: captchaMethod, body: stubHeader)

                request.addValue(stubHeader, forHTTPHeaderField: "X-SS-STUB")
                request.addValue(captchaToken, forHTTPHeaderField: "X-Sec-Captcha-Token")
            }

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                Self.logger.debug("finished post req: \(modifiedUrl.absoluteString)")
                let result = BytedCertNetResponse(by: response)
                callback(error, data, result)
            }
            task.resume()
        } else if method.uppercased() == "GET" {
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                Self.logger.debug("finished get req: \(modifiedUrl.absoluteString)")
                let result = BytedCertNetResponse(by: response)
                callback(error, data, result)
            }
            task.resume()
        }
    }

    private func commonQueryDict() -> [String: String] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let queryDict = [
            "device_id": self.deviceService.deviceId,
            "lark_version": LarkBytedCertManagerUtil.percentEscapeString(string: version)
        ]
        return queryDict
    }

    private func methodForUrl(url: URL) -> String {
        var result: String = ""

        let path = url.path
        if let query = url.query {
            result = "\(path)?\(query)"
        } else {
            result = path
        }
        return result
    }

    private func generateCaptchaToken(method: String, body: String, timeout: Int = 20) -> String {
        var result = ""

        var request = Tool_V1_GetCaptchaEncryptedTokenRequest()
        request.method = method
        request.requestBody = body
        request.appVersion = Utils.appVersion
        request.devicePlatform = "ios"
        let semaphore = DispatchSemaphore(value: 0)
        rustService.sendAsyncRequest(request)
            .map({ (response) -> Tool_V1_GetCaptchaEncryptedTokenResponse in
                return response.response
            })
            .subscribe(onNext: { resp in
                result = resp.token
                semaphore.signal()
            }, onError: { error in
                Self.logger.error("GetCaptchaEncryptedTokenRequest method:\(method) appVersion:\(request.appVersion) error:\(error.localizedDescription)")
                result = ""
                semaphore.signal()
            })
            .disposed(by: disposeBag)
        _ = semaphore.wait(timeout: .now() + .seconds(timeout))
        return result
    }
}

final class LarkBytedCertManagerUtil {
    static func percentEscapeString(string: String) -> String {
        var characterSet = NSCharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._* ")

        return string.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
    }

    static func encodeParametersToData(parameters: [AnyHashable: Any]) -> Data? {
        let parameterArray = parameters.map { (key, value) -> String in
            let valueString = "\(value)"
            return "\(key)=\(self.percentEscapeString(string: valueString))"
        }

        return parameterArray.joined(separator: "&").data(using: .utf8, allowLossyConversion: true)
    }
}

enum LarkBytedCertError: Error, CustomStringConvertible {
    case internalError(String)

    public var description: String {
        switch self {
        case .internalError(let msg):
            return "LarkBytedCertError.internalError: \(msg)"
        }
    }
}

public final class LarkBytedCertTracker: NSObject, BytedCertTrackEventDelegate {
    public func track(withEvent event: String, params: [AnyHashable: Any]) {
        Tracker.post(TeaEvent(event, params: params))
    }
}

public final class LarkBytedCertLogger: NSObject, BytedCertLoggerDelegate {
   
    static let logger = Logger.log(LarkBytedCertLogger.self, category: "byted_cert.LarkBytedCertLogger")

    public func info(_ message: String, params: [String : String]?) {
        Self.logger.info(message,additionalData: params)
    }
    
    public func error(_ message: String, params: [String : String]?, error: Error?) {
        Self.logger.error(message, additionalData: params,error: error)
    }
}

extension BytedCertNetResponse {
    convenience init(by urlResponse: URLResponse?) {
        guard let resp = urlResponse as? HTTPURLResponse else {
            self.init(statusCode: -1, logId: nil)
            return
        }
        let code = resp.statusCode
        let logId = resp.allHeaderFields["x-tt-logid"] as? String
        self.init(statusCode: code, logId: logId)
    }
}
