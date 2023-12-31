//
//  KaTokenManager.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/21.
//

import Foundation
import LKCommonsLogging
import LarkFoundation
import RxSwift
import RxRelay
import LarkContainer
import LarkAccountInterface

class KaTokenManager {

    private let store: KaStore

    private let loginStateSub: BehaviorRelay<V3LoginState>

    @Provider var dependency: PassportDependency

    init(
        store: KaStore,
        loginStateSub: BehaviorRelay<V3LoginState>
        ) {
        KaTokenManager.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSSZ"
        self.store = store
        self.loginStateSub = loginStateSub

        let becomeActiveOb = NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
        becomeActiveOb.bind { [weak self] (_) in
            guard let self = self else { return }
            if case .logined = loginStateSub.value {
                self.startTimer()
            }
        }.disposed(by: disposeBag)

        let enterBackgroundOb = NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
        enterBackgroundOb.bind { [weak self] (_) in
            guard let self = self else { return }
            if case .logined = loginStateSub.value {
                self.stopTimer()
            }
        }.disposed(by: disposeBag)

        loginStateSub.distinctUntilChanged().bind { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .logined:
                self.startTimer()
            case .notLogin:
                self.stopTimer()
            }
        }.disposed(by: disposeBag)
    }

    var isRequesting: Bool = false

    private let semaphore = DispatchSemaphore(value: 1)

    private var callbacks: [(onSuccess: (KaIdentity) -> Void, onFail: (Error) -> Void)] = []

    private func addCallback(onSuccess: @escaping (KaIdentity) -> Void, onFail: @escaping (Error) -> Void) {
        callbacks.append((onSuccess, onFail))
    }

    private func removeAllCallback() -> [(onSuccess: (KaIdentity) -> Void, onFail: (Error) -> Void)] {
        let cbs = callbacks
        callbacks.removeAll()
        return cbs
    }

    deinit {
        stopTimer()
    }

    func startTimer() {
        stopTimer()
        SuiteLoginUtil.runOnMain {
            let timer = self.createTimer()
            KaTokenManager.logger.info("start timer")
            timer.fire()
            self.timer = timer
        }
    }

    func stopTimer() {
        guard let timer = timer else {
            return
        }
        SuiteLoginUtil.runOnMain {
            KaTokenManager.logger.info("stop timer")
            timer.invalidate()
            self.timer = nil
        }
    }

    func fetchIdentity(onSuccess: @escaping (KaIdentity) -> Void, onError: @escaping (Error) -> Void) {
        guard let identity = self.store.identity else {
            let msg = "no identity"
            KaTokenManager.logger.error(msg)
            onError(V3LoginError.badLocalData(msg))
            return
        }
        let status = identity.status()
        KaTokenManager.logger.info("identity status: \(status) open_id: \(genMD5(identity.extraIdentity.openId, salt: nil))")
        switch identity.status() {
        case .externalTokenValid:
            onSuccess(identity)
        case .externalTokenNeedRefresh:
            semaphore.wait()
            if isRequesting {
                addCallback(onSuccess: onSuccess, onFail: onError)
                semaphore.signal()
                KaTokenManager.logger.info("fetch identity while requsting")
                return
            } else {
                isRequesting = true
                semaphore.signal()
            }
            self.request(onSuccess: { [weak self] identity in
                guard let self = self else { return }
                KaTokenManager.logger.info("update token success externalTokenExpire: \(identity.externalTokenExpiresTimestamp) refreshTokenExpire: \(identity.refreshTokenExpiresTimestamp)")
                onSuccess(identity)
                self.semaphore.wait()
                let callbacks = self.removeAllCallback()
                callbacks.forEach({ (callback) in
                    let (onSuccess, _) = callback
                    onSuccess(identity)
                })
                self.isRequesting = false
                self.semaphore.signal()
            }, onError: { [weak self] error in
                guard let self = self else { return }
                KaTokenManager.logger.info("update token fail error: \(error)")
                onError(error)
                self.semaphore.wait()
                let callbacks = self.removeAllCallback()
                callbacks.forEach({ (callback) in
                    let (_, onFail) = callback
                    onFail(error)
                })
                self.isRequesting = false
                self.semaphore.signal()
            })
        case .refreshTokenExpired:
            onError(V3LoginError.badLocalData("token expired"))
            KaTokenManager.logger.info("refresh token expired start logout")
            DispatchQueue.main.async {
                AccountServiceAdapter.shared.relogin(conf: .default, onError: { error in
                    KaTokenManager.logger.error("refresh token logout error: \(error)")
                }, onSuccess: {
                    KaTokenManager.logger.info("refresh token logout success")
                }, onInterrupt: {
                    KaTokenManager.logger.info("refresh token logout interrupt")
                })
            }
        }
    }

    func updateExtraIdentity(_ extraIdentity: ExtraIdentity?) {
        if let extraIdentity = extraIdentity {
            store.identity = KaIdentity(extraIdentity)
        } else {
            store.identity = nil
            KaTokenManager.logger.error("extraIdentity is nil")
        }
    }

    static let logger = Logger.log(KaTokenManager.self, category: "SuiteLogin.KaTokenManager")

    private static let dateFormatter: DateFormatter = DateFormatter()

    private let disposeBag = DisposeBag()

    static let checkTokenTime: TimeInterval = 600

    private var timer: Timer?

    private func createTimer() -> Timer {
        let timer = Timer(timeInterval: KaTokenManager.checkTokenTime, repeats: true) { [weak self] (_) in
            guard let self = self else { return }
            // openPlatformDeviceIdProvider 内部会resolve AccountService 导致循环依赖栈溢出，async防止循环依赖。
            DispatchQueue.main.async {
                KaTokenManager.logger.info("timer update token")
                self.fetchIdentity(onSuccess: { (_) in
                    KaTokenManager.logger.info("timer update token success")
                }, onError: { (error) in
                    KaTokenManager.logger.error("timer update token error: \(error)")
                })
            }
        }
        RunLoop.current.add(timer, forMode: .common)
        return timer
    }

    private func request(onSuccess: @escaping (KaIdentity) -> Void, onError: @escaping (Error) -> Void) {
        func processFail(_ msg: String) {
            KaTokenManager.logger.error(msg)
            onError(V3LoginError.badLocalData(msg))
        }
        let did = dependency.getOpenPlatformDeviceId()
        if did.isEmpty {
            processFail("did is empty refresh token")
            return
        }
        guard let preConfig = store.preConfig else {
            processFail("no preConfig")
            return
        }
        guard let identity = store.identity else {
            processFail("no identity")
            return
        }
        let extraIdentity = identity.extraIdentity
        var request = Request(
            requestData: RequestData(refreshKey: extraIdentity.refreshToken),
            apiAttrs: APIAttrs(
                apiID: preConfig.client.refreshAPIID,
                apiVersion: ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.apiVersion.rawValue),
                appID: preConfig.client.refreshAppID,
                appSubID: ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.appSubId.rawValue),
                appToken: ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.appToken.rawValue),
                appVersion: Utils.appVersion,
                diviceID: did,
                diviceVersion: PassportConf.deviceModel,
                osVersion: PassportConf.deviceOS,
                partnerID: ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.partnerID.rawValue),
                sign: ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.sign.rawValue),
                timeStamp: KaTokenManager.dateFormatter.string(for: Date()) ?? "",
                userToken: extraIdentity.externalToken
            )
        )
        let appKey = ExtKeyName.valueForKey(dict: preConfig.ext, key: ExtKeyName.appKey.rawValue)
        let localSign = request.localSign(appKey)
        request.apiAttrs.sign = localSign

        let params = KaTokenRequestParams(
            request: request
        )
        requestToken(
            url: preConfig.client.refreshURL,
            params: params,
            openId: extraIdentity.openId,
            success: { identity in
                self.store.identity = identity
                onSuccess(identity)
            }, fail: { error in
                KaTokenManager.logger.error("request token fail error: \(error)")
                onError(error)
            })
    }

    struct Const {
        static let apiId: String = "Api_ID"
        static let appSubId: String = "App_Sub_ID"
        static let apiVersion: String = "Api_Version"
        static let ssdp: String = "ssdp"
    }

    private lazy var sessionManager: BaseSessionManager = {
        return BaseSessionManager()
    }()

    private func requestToken(
        url urlString: String,
        params: KaTokenRequestParams,
        openId: String,
        success: @escaping (KaIdentity) -> Void,
        fail: @escaping (Error) -> Void
        ) {
        do {
            let paramsDict = try params.asDictionary()
            guard let url = URL(string: urlString) else {
                fail(V3LoginError.badLocalData("invalid url: \(urlString)"))
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            let requestId = UUID().uuidString
            request.allHTTPHeaderFields = [
                CommonConst.contentType: CommonConst.applicationJson,
                CommonConst.requestId: requestId
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: paramsDict, options: [])
            let session = sessionManager.session
            let mode = sessionManager.sessionType
            KaTokenManager.logger.info("request refresh token request url: \(url) requestId: \(requestId) mode: \(mode)")
            DispatchQueue.global().async {
                let dataTask = session.dataTask(with: request) { (data, resp, error) in
                    KaTokenManager.logger.info("response refresh token request requestId: \(requestId) httpCode: \(String(describing: (resp as? HTTPURLResponse)?.statusCode)) mode: \(mode)")
                    if let d = data {
                        do {
                            let response = try KaTokenResponse.from(d)
                            if response.isReturnSuccess() {
                                KaTokenManager.logger.info("response refresh token success mode: \(mode)")
                                let extraIdentity = ExtraIdentity(
                                    externalToken: response.response.returnData.newToken,
                                    refreshToken: response.response.returnData.refreshKey,
                                    tokenExpires: "\(response.response.returnData.tokenExpires)",
                                    refreshTokenExpires: "\(response.response.returnData.refreshKeyExpires)",
                                    openId: openId
                                )
                                let kaIdentity = KaIdentity(extraIdentity)
                                DispatchQueue.main.async {
                                    success(kaIdentity)
                                }
                            } else {
                                KaTokenManager.logger.info("response refrsh token error returnCode: \(response.response.returnCode) mode: \(mode) dataString: \(String(describing: String(data: d, encoding: .utf8)))")
                                DispatchQueue.main.async {
                                    fail(V3LoginError.badResponse(BundleI18n.suiteLogin.Lark_Passport_BadServerData))
                                }
                            }
                        } catch {
                            KaTokenManager.logger.error("response refrsh token transform json error: \(error), dataString: \(String(describing: String(data: d, encoding: .utf8))) mode: \(mode)")
                            DispatchQueue.main.async {
                                fail(V3LoginError.transformJSON(error))
                            }
                        }
                    } else if let error = error {
                        KaTokenManager.logger.error("response refrsh token error: \(error) mode: \(mode)")
                        DispatchQueue.main.async {
                            fail(V3LoginError.server(error))
                        }
                    }
                }
                dataTask.resume()
            }
        } catch {
            KaTokenManager.logger.error("request token error: \(error)")
        }
    }

    // swiftlint:disable nesting
    // MARK: - KaTokenRequestParams
    struct KaTokenRequestParams: Codable {
        let request: Request

        enum CodingKeys: String, CodingKey {
            case request = "REQUEST"
        }
    }

    // MARK: - Request
    struct Request: Codable {
        let requestData: RequestData
        var apiAttrs: APIAttrs

        enum CodingKeys: String, CodingKey {
            case requestData = "REQUEST_DATA"
            case apiAttrs = "API_ATTRS"
        }

        func localSign(_ appKey: String) -> String {
            var requestDataString: String = ""
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(self.requestData) {
                if let result = String(data: data, encoding: .utf8) {
                    requestDataString = result
                }
            }

            var params: [String: Any] = [:]
            do {
                params = try self.apiAttrs.asDictionary()
                params.removeValue(forKey: APIAttrs.CodingKeys.sign.rawValue)
                params[Request.CodingKeys.requestData.rawValue] = requestDataString
            } catch {
                KaTokenManager.logger.info("fail to handle apiAttr serialization")
            }

            var joinedString = params.sorted { $0.key.lowercased() < $1.key.lowercased() }
                .map { "\($0)=\($1)" }
                .joined(separator: "&")
            joinedString += "&\(appKey)"
            print(joinedString)

            let encrypedString = genMD5(joinedString, salt: nil).uppercased()
            return encrypedString
        }
    }

    // MARK: - APIAttrs
    struct APIAttrs: Codable {
        let apiID, apiVersion, appID, appSubID: String
        let appToken, appVersion, diviceID, diviceVersion: String
        let osVersion, partnerID: String
        var sign: String
        let timeStamp: String
        let userToken: String

        enum CodingKeys: String, CodingKey {
            case apiID = "Api_ID"
            case apiVersion = "Api_Version"
            case appID = "App_ID"
            case appSubID = "App_Sub_ID"
            case appToken = "App_Token"
            case appVersion = "App_Version"
            case diviceID = "Divice_ID"
            case diviceVersion = "Divice_Version"
            case osVersion = "OS_Version"
            case partnerID = "Partner_ID"
            case sign = "Sign"
            case timeStamp = "Time_Stamp"
            case userToken = "User_Token"
        }
    }

    // MARK: - RequestData
    struct RequestData: Codable {
        let refreshKey: String
        let scope = ""
        let remarks = ""

        enum CodingKeys: String, CodingKey {
            case refreshKey = "Refresh_key"
            case scope = "Scope"
            case remarks = "Remarks"
        }
    }

    // MARK: - KaTokenResponse
    struct KaTokenResponse: Codable {
        let response: Response

        enum CodingKeys: String, CodingKey {
            case response = "RESPONSE"
        }

        func isReturnSuccess() -> Bool {
            return response.returnCode.starts(with: "S")
        }

    }

    // MARK: - Response
    struct Response: Codable {
        let returnCode: String
        let returnData: ReturnData
        let returnDesc, returnStamp: String

        enum CodingKeys: String, CodingKey {
            case returnCode = "RETURN_CODE"
            case returnData = "RETURN_DATA"
            case returnDesc = "RETURN_DESC"
            case returnStamp = "RETURN_STAMP"
        }
    }

    // MARK: - ReturnData
    struct ReturnData: Codable {
        let newToken: String
        let refreshKeyExpires: Int
        let refreshKey, remarks: String
        let tokenExpires: Int
        let tokenScope, tokenType, userAccessToken, userRefreshKey: String

        enum CodingKeys: String, CodingKey {
            case newToken = "New_Token"
            case refreshKeyExpires = "Refresh_Key_Expires"
            case refreshKey = "Refresh_key"
            case remarks = "Remarks"
            case tokenExpires = "Token_Expires"
            case tokenScope = "Token_Scope"
            case tokenType = "Token_Type"
            case userAccessToken = "User_Access_Token"
            case userRefreshKey = "User_Refresh_key"
        }
    }
    // swiftlint:enable nesting
}
