//
//  GlobalConfig.swift
//  SKFoundation
//
//  Created by lijuyou on 2020/5/24.
//  


import Foundation

public protocol SKFoundationConfigDelegate: AnyObject {

    /// OpenAPI
    var isStagingEnv: Bool { get }
    var isPreReleaseEnv: Bool { get }
    var isForQATest: Bool { get }
    var docsFrontendHost: String { get }
    var docsFeatureID: String? { get }
    var useComplexConnectionForPost: Bool { get }


    /// DocsSDK
    var isBeingTest: Bool { get }
    var isInDocsApp: Bool { get }
    var isInLarkDocsApp: Bool { get }
    var isEnableRustHttp: Bool { get }

    /// UserDefaultKeys
    var kDeviceID: String { get }

    /// misc
    var spaceKitVersion: String { get }
    var domainFirstValidPath: String { get }
    var currentLanguageIdentifer: String { get }
    var preleaseCcmGrayFG: Bool { get }
    var preleaseLarkGrayFG: Bool { get }
    var enableFilterBOMChar: Bool { get }
    var tokenPattern: String? { get }

    func resetNetConfigDomain()
    
}

public final class SKFoundationConfig {

    public static let shared = SKFoundationConfig()
    public weak var delegate: SKFoundationConfigDelegate?
}

extension SKFoundationConfig: SKFoundationConfigDelegate {
    public var preleaseCcmGrayFG: Bool {
        return delegate?.preleaseCcmGrayFG ?? false
    }

    public var preleaseLarkGrayFG: Bool {
        return delegate?.preleaseLarkGrayFG ?? false
    }

    public var isStagingEnv: Bool {
        return delegate?.isStagingEnv ?? false
    }

    public var isPreReleaseEnv: Bool {
        return delegate?.isPreReleaseEnv ?? false
    }

    public var isForQATest: Bool {
        return delegate?.isForQATest ?? false
    }

    public var docsFrontendHost: String {
        return delegate?.docsFrontendHost ?? ""
    }

    public var docsFeatureID: String? {
        return delegate?.docsFeatureID
    }

    public var useComplexConnectionForPost: Bool {
        return delegate?.useComplexConnectionForPost ?? false
    }

    public var isBeingTest: Bool {
        return delegate?.isBeingTest ?? false
    }

    public var isInDocsApp: Bool {
        return delegate?.isInDocsApp ?? false
    }

    public var isInLarkDocsApp: Bool {
        return delegate?.isInLarkDocsApp ?? false
    }

    public var isEnableRustHttp: Bool {
        return delegate?.isEnableRustHttp ?? false
    }

    public var spaceKitVersion: String {
        return delegate?.spaceKitVersion ?? ""
    }

    public var domainFirstValidPath: String {
        return delegate?.domainFirstValidPath ?? ""
    }

    public var currentLanguageIdentifer: String {
        //I18n.currentLanguage().languageIdentifer
        return delegate?.currentLanguageIdentifer ?? ""
    }

    public var kDeviceID: String {
        //UserDefaultKeys.deviceID
        return delegate?.kDeviceID ?? ""
    }

    public var enableFilterBOMChar: Bool {
        return delegate?.enableFilterBOMChar ?? false
    }
    
    public var tokenPattern: String? {
        delegate?.tokenPattern
    }

    public func resetNetConfigDomain() {
        delegate?.resetNetConfigDomain()
    }

}
