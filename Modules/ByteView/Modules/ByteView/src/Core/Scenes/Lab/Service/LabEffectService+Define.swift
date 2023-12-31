//
//  LabEffectService+Define.swift
//  ByteView
//
//  Created by wangpeiran on 2021/11/16.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon

// effect背景设置类型
enum EffectSettingType {
    case none       // 不设置effect
    case auto       // 美颜自动设置
    case customize  // 美颜自定义
    case set        // 可设置 真effect
}

enum EffectType {
    case virtualbg     // 虚拟背景
    case animoji       // Animoji
    case filter        // 滤镜
    case retuschieren  // 新美颜
}

enum EffectInnerType {
    case animoji
    case filter
    case retuschieren
}

enum RetuschierenType {
    case buffing
    case eyes
    case facelift
    case lipstick
}

struct RetuschierenResource {
    var type: RetuschierenType
    var icon: UDIconType
    var defaultValue: Int

    init(_ type: RetuschierenType, _ icon: UDIconType, _ defaultValue: Int) {
        self.type = type
        self.icon = icon
        self.defaultValue = defaultValue
    }

    var name: String {
        switch type {
        case .buffing:
            return I18n.View_G_Smooth
        case.eyes:
            return I18n.View_G_Eye
        case .facelift:
            return I18n.View_G_Shape
        case .lipstick:
            return I18n.View_G_Lipstick
        }
    }
}

enum EffectResource {
    static let effectAccessKey = "05f43500d79911eab76b63d0864735f8"
    static let effectAppId = "1160"
    static let effectRegion = "zh_CN"
    static let effectChannel = "App Store"
//    static let effectChannel = "test"
    static let effectFeishuDomain = "https://effect-bd.feishu.cn"
    static let effectLarkDomain = "https://effect-bd.larksuite.com"

    static let effectEmptyId = "effectEmptyResourceId"  //resourceid
    static let beautyAutoId = "beautyAutoResourceId"    //resourceid
    static let beautyCustomizeId = "beautyCustomizeResourceId"   //resourceid
    static let selectfilter = "selectfilter"
    static let selectedBeauty = "selectedBeauty"

    // 飞书美颜id
    static let beautyBuffingId = "6920046832198357517"
    static let beautyEyesId = "6920051116172382733"
    static let beautyFaceliftId = "6920051261916058119"
    static let beautyLipstickId = "6920051384008053255"

    // lark美颜id
    static let beautyLarkBuffingId = "6967169337991893506"
    static let beautyLarkEyesId = "6967169107577803265"
    static let beautyLarkFaceliftId = "6967169240860201474"
    static let beautyLarkLipstickId = "6967169668431745537"

    // CoreML资源id
    static let coremlBlurResourceID = "7197243096952738363"
    static let coremlBgResourceID = "7197242826688565820"
    static let coremlBlurLarkResourceID = "7202447676120502786"
    static let coremlBgLarkResourceID = "7202447424923636225"

    static let coremlPanel = "matting"
    static let coremlCategory = "ios_coreml"

    // disable-lint: magic number
    static let retuschieren: [String: RetuschierenResource] =
        [EffectResource.beautyBuffingId: RetuschierenResource(.buffing, .blurOutlined, 30),
         EffectResource.beautyEyesId: RetuschierenResource(.eyes, .bigEyeOutlined, 30),
         EffectResource.beautyFaceliftId: RetuschierenResource(.facelift, .faceLiftOutlined, 30),
         EffectResource.beautyLipstickId: RetuschierenResource(.lipstick, .lipstickOutlined, 0),
         EffectResource.beautyLarkBuffingId: RetuschierenResource(.buffing, .blurOutlined, 30),
         EffectResource.beautyLarkEyesId: RetuschierenResource(.eyes, .bigEyeOutlined, 30),
         EffectResource.beautyLarkFaceliftId: RetuschierenResource(.facelift, .faceLiftOutlined, 30),
         EffectResource.beautyLarkLipstickId: RetuschierenResource(.lipstick, .lipstickOutlined, 0)]
    // enable-lint: magic number

    static func effectPanel(isLark: Bool) -> [EffectInnerType: (String, String)] {
        [.animoji: ("default", isLark ? "overseas-test" : "online335-980"),
         .filter: ("vc-beautyandfilter", "allfilter"),
         .retuschieren: ("vc-beautyandfilter", "beauty")]
    }
}
