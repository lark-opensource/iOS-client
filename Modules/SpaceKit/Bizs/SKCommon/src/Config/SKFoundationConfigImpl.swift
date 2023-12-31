//
//  SKFoundationConfigImpl.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/4.
//  


import SKFoundation
import SKResource
import SKInfra

public final class SKFoundationConfigImpl {

    public static let shared = SKFoundationConfigImpl()

    private init() { }

    public func config() {
        SKFoundationConfig.shared.delegate = self
    }
}

extension SKFoundationConfigImpl: SKFoundationConfigDelegate {

    public var isStagingEnv: Bool {
        OpenAPI.docs.isStagingEnv
    }

    public var isPreReleaseEnv: Bool {
        OpenAPI.DocsDebugEnv.current == .preRelease
    }

    public var isForQATest: Bool {
        OpenAPI.isForQATest
    }

    public var docsFrontendHost: String {
        OpenAPI.docs.frontendHost
    }

    public var docsFeatureID: String? {
        OpenAPI.docs.featureID
    }

    public var useComplexConnectionForPost: Bool {
         OpenAPI.useComplexConnectionForPost
    }

    public var isBeingTest: Bool {
        DocsSDK.isBeingTest
    }

    public var isInDocsApp: Bool {
        DocsSDK.isInDocsApp
    }

    public var isInLarkDocsApp: Bool {
        DocsSDK.isInLarkDocsApp
    }

    public var isEnableRustHttp: Bool {
        DocsSDK.isEnableRustHttp
    }

    public var kDeviceID: String {
        UserDefaultKeys.deviceID
    }

    public var spaceKitVersion: String {
        SpaceKit.version
    }

    public var domainFirstValidPath: String {
        DomainConfig.validPaths.first!
    }

    public var currentLanguageIdentifer: String {
        I18n.currentLanguage().languageIdentifier
    }

    public var preleaseCcmGrayFG: Bool {
        return LKFeatureGating.preleaseCcmGrayFG
    }

    public var preleaseLarkGrayFG: Bool {
        return LKFeatureGating.preleaseLarkGrayFG
    }


    public var enableFilterBOMChar: Bool {
        return !OpenAPI.docs.disableFilterBOMChar
    }
    
    public var tokenPattern: String? {
        return SettingConfig.tokenPattern
    }

    public func resetNetConfigDomain() {
        CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.validPathsKey)
        DomainConfig.updateUserDomain(nil)
        CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.validURLMatchKey)
        CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.isNewDomainSystemKey)
    }
    
}
