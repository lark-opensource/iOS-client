//
//  SKUIKitConfigImpl.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/4.
//


import Foundation
import SKUIKit
import SKInfra


public final class SKUIKitConfigImpl {

    public static let shared = SKUIKitConfigImpl()

    private init() {
    }

    public func config() {
        SKUIKitConfig.shared.delegate = self
    }
}

extension SKUIKitConfigImpl: SKUIKitConfigDelegate {

    public var userWatermarkText: String? {
        User.current.watermarkText()
    }

    public var kGrammarCheckEnabled: String {
        UserDefaultKeys.grammarCheckEnabled
    }

    public var kNotifyMotionDidChangeOrientationNotification: Notification.Name {
        Notification.Name.motionDidChangeOrientationNotification
    }
    
    //是否使用主端水印sdk fg开关
    public var enabelUseLarkWaterMarkSDK: Bool {
        LKFeatureGating.enabelUseLarkWaterMarkSDK
    }
    
}
