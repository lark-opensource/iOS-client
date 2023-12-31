//
//  SKUIKitConfig.swift
//  SKUIKit
//
//  Created by lijuyou on 2020/5/26.
//


import Foundation

public protocol SKUIKitConfigDelegate: AnyObject {

    var userWatermarkText: String? { get }

    var kGrammarCheckEnabled: String { get }

    //Notification
    var kNotifyMotionDidChangeOrientationNotification: Notification.Name { get }
    
    //是否使用主端水印sdk fg开关
    var enabelUseLarkWaterMarkSDK: Bool { get }
}

public final class SKUIKitConfig {

    public static let shared = SKUIKitConfig()
    public weak var delegate: SKUIKitConfigDelegate?
}

extension SKUIKitConfig: SKUIKitConfigDelegate {
    public var enabelUseLarkWaterMarkSDK: Bool {
        delegate?.enabelUseLarkWaterMarkSDK ?? false
    }
    
    
    public var kGrammarCheckEnabled: String {
        //UserDefaultKeys.grammarCheckEnabled
        return delegate?.kGrammarCheckEnabled ?? ""
    }

    public var userWatermarkText: String? {
        //User.current.watermarkText()
        return delegate?.userWatermarkText
    }

    public var kNotifyMotionDidChangeOrientationNotification: Notification.Name {
        //BrowserOrientationManager.motionDidChangeOrientationNotification
        return delegate?.kNotifyMotionDidChangeOrientationNotification ?? Notification.Name(rawValue: "")
    }
}
