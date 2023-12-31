//
//  PassportAPIV3.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/9/18.
//

import Foundation
import LarkLocalizations
import LKCommonsLogging
import Homeric
import LarkFoundation
import LarkPerf
import RoundedHUD
import RxSwift
import LarkAccountInterface
import ECOProbe

typealias OnStepSuccessV3 = (_ step: String, _ info: [String: Any]?) -> Void
typealias OnSimpleResponseSuccessV3 = (_ simpleResponse: V3.SimpleResponse) -> Void
typealias OnConfigSuccessV3 = (V3ConfigInfo) -> Void
typealias OnFailureV3 = (_ error: V3LoginError) -> Void

enum VerifyCodeType: Int {
    case code = 0
    case link = 1
}

class LoginRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {

    convenience init(pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        self.init(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
    }

    required init(pathPrefix: String, pathSuffix: String, uniContext: UniContextProtocol? = nil) {
        super.init(pathPrefix: pathPrefix, pathSuffix: pathSuffix, uniContext: uniContext)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .saveToken,
            .saveEnv,
            .crossUnit,
            .costTimeRecord,
            .toastMessage,
            .checkSession
        ]
        self.requiredHeader = [.passportToken, .proxyUnit]
        // 端内登录逻辑中，需要在用户列表中过滤已登录的用户，需要告知后端所有 session
        self.required(.sessionKeys)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }

    convenience init(appId: APPID, uniContext: UniContextProtocol? = nil) {
        self.init(pathSuffix: appId.apiIdentify(), uniContext: uniContext)
        self.appId = appId
    }
}

class ConfigRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {
    convenience init(pathSuffix: String) {
        let prefix = CommonConst.v4APIPathPrefix
        self.init(pathPrefix:  prefix, pathSuffix: pathSuffix)
        self.method = .get
        self.domain = .passportAccounts()
        self.middlewareTypes = [.fetchDeviceId, .requestCommonHeader]
        
        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }
}

//原生代理WebView端通用请求
class NativeCommonRequest<ResponseData: ResponseV3>: PassportRequest<ResponseData> {
    override var path: String { pathSuffix }
    convenience init(pathSuffix: String) {
        let prefix = ""
        var pathSuffixProcess = pathSuffix
        if pathSuffixProcess.first == "/" {
            pathSuffixProcess.removeFirst()
        }
        self.init(pathPrefix:  prefix, pathSuffix: pathSuffix)
        self.domain = .passportAccounts(usingPackageDomain: true)
        self.middlewareTypes = [
            .captcha,
            .requestCommonHeader,
            .saveToken,
            .saveEnv,
            .crossUnit,
            .costTimeRecord,
            .toastMessage,
            .checkSession,
            .fetchDeviceId
        ]
        self.requiredHeader = [.passportToken, .proxyUnit, .flowKey]
        // 端内登录逻辑中，需要在用户列表中过滤已登录的用户，需要告知后端所有 session
        self.required(.sessionKeys)

        #if DEBUG || BETA || ALPHA
        if let ttEnvHeader = PassportSwitch.shared.ttEnvHeader {
            self.add(headers: ["X-TT-ENV": ttEnvHeader])
        }
        #endif
    }
}

class LoginAPI: APIV3, JoinTeamAPIProtocol, VerifyAPIProtocol, RecoverAccountAPIProtocol, SetPwdAPIProtocol, RetrieveAPIProtocol, V3SetPwdAPIProtocol {

    func config(success: @escaping OnConfigSuccessV3) {
        let request = ConfigRequest<V3.Config>(pathSuffix: "config")
        client.send(request, success: { (resp, _) in
            if let info = resp.dataInfo {
                success(info)
            }
        }, failure: { error in
            LoginAPI.logger.error("Failed to load config: \(error)")
        })
    }

    func loginType(
        serverInfo: ServerInfo,
        contact: String,
        credentialType: Int,
        action: Int,
        sceneInfo: [String: String]?,
        forceLocal: Bool,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.credential: contact,
            CommonConst.credentialType: credentialType,
            CommonConst.action: action,
            CommonConst.usePackageDomain: true
        ]

        if !V3NormalConfig.enableChangeGeo || forceLocal {
            params[CommonConst.forceLocal] = true
        }

        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = LoginRequest<V3.Step>(appId: .v3LoginType, uniContext: context)
        // 登录流程的第一个接口，保证使用包域名
        req.domain = .passportAccounts(usingPackageDomain: true)
        req.body = params
        req.sceneInfo = sceneInfo
        req.no(.passportToken)
            .required(.injectParams)
            .required(.checkNetwork)
            .required(.fetchDeviceId)
            .required(.flowKey)

        return client
            .send(req)
            .monitor(.loginType, context: context)
    }

    func create(
        _ body: UserCreateReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v3TenantPrepare)
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.sceneInfo = body.sceneInfo
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.create, context: body.context)
    }

    func fetchPrepareTenantInfo(context: UniContextProtocol) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v3RegisterPrepareTenant, uniContext: context)
        req.method = .get
        // 注册的第一个接口无法从先前的 response 里获取 usePackageDomain 字段，明确需要手动 true
        req.domain = .passportAccounts(usingPackageDomain: true)
        req.no(.passportToken).required(.checkNetwork).required(.fetchDeviceId)
        return client.send(req)
            .monitor(.registerType, context: context)
    }

    func joinType() -> Observable<V3.Step> {
        let params: [String: Any] = [
            CommonConst.appId: PassportConf.shared.appID
        ]
        let req = LoginRequest<V3.Step>(appId: .v3JoinType)
        req.body = params
        req.no(.passportToken).required(.injectParams).required(.checkNetwork).required(.fetchDeviceId)
        return client.send(req)
    }

    func bindContact(
        contact: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let params: [String: Any] = [
            CommonConst.contact: contact
        ]
        let req = LoginRequest<V3.Step>(appId: .v3BindContact, uniContext: context)
        req.body = params
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.bindContact, context: context)
    }

    // https://bytedance.feishu.cn/docx/doxcnWrjGTILl651ynT6urMjiXb#doxcncM6cUwIKUUyEQzSdC7Lpyh
    func applyVerifyTokenForPublic(
        contact: String? = nil,
        contactType: Int,
        verifyScope: VerifyScope = .unknown,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [:]
        params["credential_type"] = contactType
        if let contact = contact {
            params["credential"] = contact
        }
        if verifyScope != .unknown {
            params[CommonConst.verifyScope] = verifyScope.rawValue
        }
        let req = LoginRequest<V3.Step>(appId: .applyVerifyToken, uniContext: context)
        req.domain = .passportAccounts()
        req.body = params
        req.required(.suiteSessionKey)
        req.required(.passportToken)
        return client.send(req)
    }

    func applyCodeForPublic(
        sourceType: Int?,
        contact: String? = nil,
        verifyScope: VerifyScope = .unknown,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [:]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        if let contact = contact {
            params[CommonConst.contact] = contact
        }
        if verifyScope != .unknown {
            params[CommonConst.verifyScope] = verifyScope.rawValue
        }
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3ApplyCode.apiIdentify(), uniContext: context)
        req.body = params
        req.required(.suiteSessionKey)
        req.required(.passportToken)
        return client.send(req)
            .monitor(.applyCode, context: context)
    }

    func verifyForPublic(
        sourceType: Int?,
        code: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.code: code]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3VerifyCode.apiIdentify(), uniContext: context)
        req.required(.verifyToken)
        req.body = params
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.verifyCode, context: context)
    }

    /// 新帐号模型实现
    /// 服务端返回的结构，serverInfo 和 flowType 不在同一层级，这里分开传
    func applyCode(
        serverInfo: ServerInfo,
        flowType: String?,
        contactType: Int?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        return applySMSCode(serverInfo: serverInfo, flowType: flowType, codeType: .code, contactType: contactType, context: context)
    }

    // conform for VerifyAPIProtocol, contactType is not need in this implementation
    func applyCode(
        sourceType: Int?,
        contactType: Int? = nil,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        return applyCode(
            codeType: .code,
            sourceType: sourceType,
            contactType: contactType,
            context: context
        )
    }

    @available(*, deprecated, message: "Use new applyCode method instead.")
    func applyCode(
        codeType: VerifyCodeType,
        sourceType: Int?,
        contactType: Int? = nil,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.codeType: codeType.rawValue]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3ApplyCode.apiIdentify(), uniContext: context)
        req.body = params
        return client.send(req)
            .monitor(.applyCode, context: context)
    }

    /// 新帐号模型实现
    /// 服务端返回的结构，serverInfo 和 flowType 不在同一层级，这里分开传
    func applySMSCode(
        serverInfo: ServerInfo,
        flowType: String?,
        codeType: VerifyCodeType,
        contactType: Int? = nil,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.codeType: codeType.rawValue]
        if let flowType = flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = LoginRequest<V3.Step>(appId: .v4ApplyCode, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.applyCode, context: context)
    }
    
    func v3Verify(
          sourceType: Int?,
          code: String,
          contactType: Int?,
          sceneInfo: [String: String]?,
          context: UniContextProtocol
      ) -> Observable<V3.Step> {
          var params: [String: Any] = [CommonConst.code: code]
          if let source = sourceType {
              params[CommonConst.sourceType] = source
          }
          if let contactType = contactType {
              params[CommonConst.contactType] = String(contactType)
          }
          let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3VerifyCode.apiIdentify(), uniContext: context)
          req.body = params
          req.sceneInfo = sceneInfo
          return client.send(req)
              .monitor(.verifyCode, context: context)
      }


    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {

        var params: [String: Any] = [CommonConst.code: code]
        if let flowType = flowType {
            params[CommonConst.flowType] = flowType
        }

        let req = LoginRequest<V3.Step>(appId: .v4VerifyCode, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)

        return client
            .send(req)
            .monitor(.verifyCode, context: context)
    }

    func tenantInformation(
        serverInfo: ServerInfo,
        credentialInfo: V4CredentialInfo,
        name: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.credential: credentialInfo.credential,
            CommonConst.credentialType: credentialInfo.credentialType,
            CommonConst.name: name
        ]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }

        let req = LoginRequest<V3.Step>(appId: .v4TenantInformation, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
        //            .monitor(.registerType, context: context)
    }

    func verify(
        serverInfo: ServerInfo,
        flowType: String?,
        password: String,
        rsaInfo: RSAInfo?,
        contactType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let appID: APPID = .v4VerifyPwd
        let req = LoginRequest<V3.Step>(appId: appID, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.setPwdReqBody(PwdRequestBody(
            pwd: password,
            rsaInfo: rsaInfo,
            sourceType: nil,
            logId: appID.apiIdentify(),
            flowType: flowType
        ))
        req.requiredHeader.insert(.flowKey)
        req.sceneInfo = sceneInfo
        return client
            .send(req)
            .monitor(.verifyPwd, context: context)
    }

    func verifyOtp(
        sourceType: Int?,
        code: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.code: code]
        if let source = sourceType {
            params[CommonConst.sourceType] = source
        }
        let req = LoginRequest<V3.Step>(appId: .v3VerifyOtp, uniContext: context)
        req.body = params
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.verifyOtp, context: context)
    }
    
    func v4VerifyOtp(
        serverInfo: ServerInfo,
        flowType: String?,
        code: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [CommonConst.code: code]
        if let flowType = flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = LoginRequest<V3.Step>(appId: .v4VerifyOtp, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.verifyOtp, context: context)
    }
    
    func verifyMo(serverInfo: ServerInfo,
                  flowType: String?,
                  context: UniContextProtocol
    ) -> RxSwift.Observable<V3.Step> {
        let request = LoginRequest<V3.Step>(appId: .verifyMo, uniContext: context)
        var params: [String:String] = [:]
        if let flowType = flowType {
            params[CommonConst.flowType] = flowType
        }
        request.body = params
        request.configDomain(serverInfo: serverInfo)
        request.requiredHeader.insert(.flowKey)
        return client.send(request)

    }
    

    func setPwd(
        serverInfo: ServerInfo,
        password: String,
        rsaInfo: RSAInfo?,
        sourceType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v4SetPwd, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.method = .post
        req.setPwdReqBody(PwdRequestBody(
            pwd: password,
            rsaInfo: rsaInfo,
            sourceType: sourceType,
            logId: APPID.v4SetPwd.apiIdentify(),
            flowType: serverInfo.flowType
        ))
        req.sceneInfo = sceneInfo
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.setPwd, context: context)
    }

    func v3SetPwd(
        password: String,
        rsaInfo: RSAInfo?,
        sourceType: Int?,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {

        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3SetPwd.apiIdentify(), uniContext: context)
        req.method = .post
        req.setPwdReqBody(PwdRequestBody(
            pwd: password,
            rsaInfo: rsaInfo,
            sourceType: sourceType,
            logId: APPID.v3SetPwd.apiIdentify()
        ))
        req.sceneInfo = sceneInfo
        return client.send(req)
    }

    func enterApp(
        userId: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let params: [String: Any] = [
            "user_id": userId,
            "apply_device_login_id": true
        ]
        let req = LoginRequest<V3.Step>(appId: .v3App, uniContext: context)
        req.body = params
        Self.logger.info("n_action_accounts_app_req", body: "user_id:\(userId)")
        return client.send(req)
            .monitor(.enterApp, context: context)
    }

    func v4EnterApp(
        customDomain: String? = nil,
        serverInfo: ServerInfo,
        userId: String? = nil,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [:]
        if let uid = userId {
            params[CommonConst.userId] = uid
        }
        if let fType = serverInfo.flowType {
            params[CommonConst.flowType] = fType
        }
        let req = LoginRequest<V3.Step>(appId: .v4EnterApp, uniContext: context)
        if let domain = customDomain, !domain.isEmpty {
            req.domain = .custom(domain: domain)
        } else {
            req.configDomain(serverInfo: serverInfo)
        }
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.enterApp, context: context)
    }

    func v4EnterEmailCreate(
        serverInfo: ServerInfo,
        tenantId: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.tenantId: tenantId
        ]
        if let fType = serverInfo.flowType {
            params[CommonConst.flowType] = fType
        }
        let req = LoginRequest<V3.Step>(appId: .v4EnterEmailCreate, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.create, context: context)
    }

    func v4CreateTenant(
        serverInfo: ServerInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v4CreateTenant, uniContext: context)
        if let fType = serverInfo.flowType {
            req.body = [
                CommonConst.flowType: fType
            ]
        }
        req.configDomain(serverInfo: serverInfo)
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.create, context: context)
    }
    
    func chooseOptIn(
        serverInfo: ServerInfo,
        select: Bool,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.optIn: select
        ]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        
        let req = LoginRequest<V3.Step>(appId: .chooseOptIn, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.method = .post
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }

    func setName(
        serverInfo: ServerInfo,
        name: String?,
        optIn: Bool?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params = [String: Any]()
        if let name = name {
            params = [
                CommonConst.name: name
            ]
        }
        
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        if let optIn = optIn {
            params[CommonConst.optIn] = optIn
        }
        let req = LoginRequest<V3.Step>(appId: .v4SetName, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.method = .post
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.setName, context: context)
    }
    
    func joinTenantByCode(
        serverInfo: ServerInfo,
        teamCode: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.tenantCode: teamCode
        ]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        let req = LoginRequest<V3.Step>(appId: .v4JoinTenantByCode, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
            .monitor(.teamCodeJoin, context: context)
    }

    func joinWithQRCode(
        _ body: TeamCodeReqBody,
        serverInfo: ServerInfo
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v4JoinWithQRCode)
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.requiredHeader.insert(.flowKey)
        req.sceneInfo = body.sceneInfo
        return client.send(req)
            .monitor(.teamCodeJoin, context: body.context)
    }

    func officialEmail(
        tenantId: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v3OfficialEmailJoin, uniContext: context)
        req.body = ["tenant_id": tenantId]
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.officialEmailJoin, context: context)
    }

    func verifyPolling(success: @escaping OnStepSuccessV3, failure: @escaping OnFailureV3) -> LoginRequest<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .v3VerifyPolling)
        req.timeout = 15 // verify_polling(8s) + possible process time(4-6s staging)
        client.send(req, success: success, failure: failure)
        return req
    }
}

extension LoginAPI {
    #if ONE_KEY_LOGIN
    func oneKeyLogin(_ body: OneKeyLoginReqBody) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: body.appId())
        req.required(.injectParams).no(.passportToken).required(.checkNetwork).required(.fetchDeviceId).required(.checkLocalSecEnv)
        req.body = body
        req.domain = .passportAccounts()
        return client.send(req)
            .monitor(body.monitorCode(), context: body.context)
    }
    #endif

    func recoverType(
        sourceType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3RecoverType.apiIdentify(), uniContext: context)
        let body = [
            CommonConst.sourceType: sourceType
        ]
        req.body = body
        req.required(.suiteSessionKey).required(.passportToken).required(.flowKey)
        return client.send(req)
    }
    
    func retrieveGuideWay(
        serverInfo: ServerInfo,
        flowType: String?,
        action: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        
        let req = LoginRequest<V3.Step>(appId: .v4RetrieveGuideWay, uniContext: context)
        var body: [String: Any] = [
            CommonConst.action: action
        ]
        if let flowType = flowType {
            body[CommonConst.flowType] = flowType
        }
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.required(.flowKey)
        req.required(.suiteSessionKey)
        return client.send(req)
    }
    
    func retrieveOpThree(
        serverInfo: ServerInfo,
        name: String,
        idNumber: String,
        rsaInfo: RSAInfo,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        
        let req = LoginRequest<V3.Step>(appId: .v4RetrieveOpThree, uniContext: context)
        let content: [String: String] = [
            CommonConst.realName: name,
            CommonConst.idNumber:idNumber,
        ]
        var params = self.generateEncrptedBody(body: content, rsaInfo: rsaInfo)
        params[CommonConst.flowType] = serverInfo.flowType ?? ""
        params[CommonConst.rsaToken] = rsaInfo.token
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.required(.flowKey)
        req.required(.suiteSessionKey)
        return client.send(req)
    }
    
    func retrieveChooseIdentity(
        serverInfo: ServerInfo,
        userID: Int,
        tenant: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step>{
        
        let req = LoginRequest<V3.Step>(appId: .retrieveChoose, uniContext: context)
        let body: [String: Any] = [
            CommonConst.identityId: userID,
            CommonConst.tenant: tenant,
            CommonConst.flowType: serverInfo.flowType ?? ""
        ]
        req.body = body
        req.domain = .passportAccounts()
        req.required(.flowKey)
        return client.send(req)
    }
    
    func retrieveSetCred(
        serverInfo: ServerInfo,
        newCred: String,
        type: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step>{
        
        let req = LoginRequest<V3.Step>(appId: .retrieveSetCred, uniContext: context)
        let body: [String: Any] = [
            "cred_content": newCred,
            "cred_type": type,
            CommonConst.flowType: serverInfo.flowType ?? ""
        ]
        req.configDomain(serverInfo: serverInfo)
        req.body = body
        req.required(.flowKey)
        return client.send(req)
    }
    
    func retrieveAppealGuide(
        token: String,
        type: String?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        
        let req = LoginRequest<V3.Step>(appId: .retrieveAppealGuide, uniContext: context)
        var parmas =  [CommonConst.token: token]
        if let type = type {
            parmas["type"] = type
        }
        req.body = parmas
        req.domain = .passportAccounts()
        return client.send(req)
    }

    func verifyCarrier(
        name: String,
        identityNumber: String,
        sourceType: Int,
        rsaInfo: RSAInfo,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix:APPID.v3RecoverAccountCarrier.apiIdentify(), uniContext: context)
        let body = [
            "name": name,
            "identity": identityNumber
        ]
        var encryptedBody: [String: Any] = self.generateEncrptedBody(body: body, rsaInfo: rsaInfo)
        encryptedBody["source_type"] = sourceType
        req.body = encryptedBody
        req.required(.suiteSessionKey)
        req.required(.passportToken)
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.recoverOperator, context: context)
    }

    func verifyBank(
        bankCardNumber: String,
        mobileNumber: String,
        rsaInfo: RSAInfo,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3RecoverAccountBank.apiIdentify(), uniContext: context)
        let body = [
            "bank_card_id": bankCardNumber,
            "mobile": mobileNumber
        ]
        let encryptedBody = self.generateEncrptedBody(body: body, rsaInfo: rsaInfo)
        req.body = encryptedBody
        req.required(.suiteSessionKey)
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.recoverBankcard, context: context)
    }

    func notifyFaceVerifySuccsss(
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3NotifyFaceVerifySuccess.apiIdentify(), uniContext: context)
        req.required(.suiteSessionKey)
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.recoverFace, context: context)
    }

    func verifyNewCredential(
        mobileNumber: String,
        sceneInfo: [String: String]?,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>.init(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: APPID.v3SetInputCredential.apiIdentify(), uniContext: context)
        req.body = [
            "contact": mobileNumber
        ]
        req.required(.suiteSessionKey)
        req.sceneInfo = sceneInfo
        return client.send(req)
            .monitor(.recoverNewMobile, context: context)
    }

    func refreshVerifyFaceTicket(
        sceneInfo: [String: String]?,
        context: UniContextProtocol,
        success: @escaping OnSimpleResponseSuccessV3,
        failure: @escaping OnFailureV3
    ) {
        let req = LoginRequest<V3.SimpleResponse>(pathPrefix: CommonConst.v3SuiteApiPath, pathSuffix: "recover/change", uniContext: context)
//        let req = LoginRequest<V3.SimpleResponse>(appId: .v3RefreshVerifyTicket)
        req.required(.suiteSessionKey)
        req.sceneInfo = sceneInfo
        client.send(req, success: { (resp, _) in
            success(resp)
        }, failure: failure)
    }
    
    func realNameGuideWay(
        serverInfo: ServerInfo,
        appealType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>.init(appId: .realNameGuideWay, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.required(.flowKey)
        req.body = [
            "flow_type": serverInfo.flowType ?? "",
            "appeal_type": appealType,
        ]
        return client.send(req)
    }

    func generateEncrptedBody(body: [String: String], rsaInfo: RSAInfo) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in body {
            if let encryptedValue = SuiteLoginUtil.rsaEncrypt(plain: v, publicKey: rsaInfo.publicKey) {
                result[k] = encryptedValue
            }
        }
        result[CommonConst.rsaToken] = rsaInfo.token
        return result
    }
}

extension LoginAPI: SetSpareCredentialAPIProtocol {
    func setSpareCredential(
        serverInfo: ServerInfo,
        credential: String,
        credentialType: Int,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.credential: credential,
            CommonConst.credentialType: credentialType
        ]
        if let flowType = serverInfo.flowType {
            params[CommonConst.flowType] = flowType
        }
        
        let req = LoginRequest<V3.Step>(appId: .setSpareCredential, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.body = params
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }
}

// MARK: - QRCode Login
extension LoginAPI {
    func qrLoginInit() -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(pathSuffix: "qrlogin/init")
        // TODO: query
        req.body = [
            "biz_type": "default"
        ]
        req.domain = .passportAccounts()
        req.required(.fetchDeviceId)
        return client.send(req)
    }

    func qrLoginPolling() -> (observable: Observable<V3.Step>, request: LoginRequest<V3.Step>) {
        let req = LoginRequest<V3.Step>(pathSuffix: "qrlogin/polling")
        req.domain = .passportAccounts()
        req.requiredHeader.insert(.flowKey)
        return (client.send(req), req)
    }
}

extension LoginAPI {
    func fetchRegisterDiscovery() -> Observable<V3.Step> {
        Self.logger.info("n_action_discovery_req")
        let req = LoginRequest<V3.Step>(appId: .v4RegisterDiscovery)
        req.method = .get
        req.domain = .passportAccounts()
        req.requiredHeader.insert(.flowKey)
        return client.send(req)
    }
}


extension LoginAPI {

    func joinTenant(
        serverInfo: ServerInfo,
        userIds: [String],
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .joinTenant, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.requiredHeader.insert(.flowKey)
        req.body = [
            "user_ids": userIds,
            "flow_type": serverInfo.flowType ?? ""
        ]
        return client.send(req)
    }
    
    func checkRefuseInvitation(
        serverInfo: ServerInfo,
        userIds: [String],
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .checkRefuseInvitation, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.requiredHeader.insert(.flowKey)
        req.body = [
            "user_ids": userIds,
            "flow_type": serverInfo.flowType
        ]
        return client.send(req)
    }
    
    func refuseInvitation(
        serverInfo: ServerInfo,
        userIds: [String],
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        let req = LoginRequest<V3.Step>(appId: .refuseInvitation, uniContext: context)
        req.configDomain(serverInfo: serverInfo)
        req.requiredHeader.insert(.flowKey)
        req.body = [
            "user_ids": userIds,
            "flow_type": serverInfo.flowType ?? ""
        ]
        return client.send(req)
    }
}

extension LoginAPI {

    func checkABTestForUG(
        context: UniContextProtocol
    ) -> Observable<V3.CommonResponse<CheckABTestForUGResp>> {
        let req = LoginRequest<V3.CommonResponse<CheckABTestForUGResp>>(appId: .abTestForUG, uniContext: context)
        req.domain = .passportAccounts()
        req.method = .get
        req.required(.fetchDeviceId)
        return client.send(req)
    }
}

extension LoginAPI {
    func applyForm(
        approvalType: String,
        appID: String,
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            CommonConst.approvalType: approvalType,
            CommonConst.appId: appID
        ]

        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.applyForm.apiIdentify())
        req.required(.suiteSessionKey)
        req.domain = .passportAccounts()
        req.method = .post
        req.body = params
        return client.send(req)
    }

    func submitForm(
        approvalType: String,
        appID: String,
        approvalCode: String,
        approvalUserIDList: [String],
        form: [[String: String]],
        context: UniContextProtocol
    ) -> Observable<V3.Step> {
        var params: [String: Any] = [
            "approval_code": approvalCode,
            "approval_user_id_list": approvalUserIDList,
            "approval_type": approvalType,
            CommonConst.appId: appID,
            "form": form
        ]

        let req = AfterLoginRequest<V3.Step>(pathPrefix: CommonConst.v4APIPathPrefix, pathSuffix: APPID.submitForm.apiIdentify())
        req.required(.suiteSessionKey)
        req.domain = .passportAccounts()
        req.method = .post
        req.body = params
        return client.send(req)
    }
}

extension HTTPClient {
    func send<ResponseData: V3.Step>(
        _ request: PassportRequest<ResponseData>,
        success: @escaping OnStepSuccessV3,
        failure: @escaping OnFailureV3
    ) {
        send(
            request,
            success: { (resp, _) in
                success(resp.stepData.nextStep, resp.stepData.stepInfo)
            }, failure: failure)
    }
}

extension Observable where Element == V3.Step {
    func post(
        _ additionalInfo: Codable? = nil,
        vcHandler: EventBusVCHandler? = nil,
        context: UniContextProtocol
    ) -> RxSwift.Observable<Void> {
        return flatMap { (resp) -> RxSwift.Observable<Void> in
            return RxSwift.Observable<Void>.create({ (ob) -> Disposable in
                LoginPassportEventBus.shared.post(
                    event: resp.stepData.nextStep,
                    context: V3RawLoginContext(
                        stepInfo: resp.stepData.stepInfo,
                        additionalInfo: additionalInfo,
                        vcHandler: vcHandler,
                        backFirst: resp.stepData.backFirst,
                        context: context
                    ),
                    success: {
                        ob.onNext(())
                        ob.onCompleted()
                    }, error: { error in
                        ob.onError(error)
                    })
                return Disposables.create()
            })
        }.observeOn(MainScheduler.instance)
    }
}
