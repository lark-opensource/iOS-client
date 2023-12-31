//
//  BTFieldData.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/30.
//

import Foundation
import SKInfra
import SKBrowser

/// 对应 链接/数字/自动编号/扫码/位置/货币/电话号码/邮箱
struct BTSimpleTextData: SKFastDecodable {
    var text: String = ""
    var textColor: String = ""
    var leftIcon: BTIcon? = nil
    var rightIcon: BTIcon? = nil

    static func deserialized(with dictionary: [String: Any]) -> BTSimpleTextData {
        var model = BTSimpleTextData()
        model.text <~ (dictionary, "text")
        model.textColor <~ (dictionary, "textColor")
        model.leftIcon <~ (dictionary, "leftIcon")
        model.rightIcon <~ (dictionary, "rightIcon")
        return model
    }
}
/// 文本字段 对应数据
struct BTRichTextData: SKFastDecodable {
    var segments: [BTRichTextSegmentModel]? = nil
    
    static func deserialized(with dictionary: [String: Any]) -> BTRichTextData {
        var model = BTRichTextData()
        model.segments <~ (dictionary, "segments")
        return model
    }
}

/// 单/多选数据
struct BTCapsuleData: SKFastDecodable {
    // 选项文字
    var text: String = ""
    // 背景颜色值
    var capsuleColor: String = ""
    // 文字颜色
    var textColor: String = ""

    static func deserialized(with dictionary: [String: Any]) -> BTCapsuleData {
        var model = BTCapsuleData()
        model.text <~ (dictionary, "text")
        model.capsuleColor <~ (dictionary, "capsuleColor")
        model.textColor <~ (dictionary, "textColor")
        return model
    }
    
    func toCapsule() -> BTCapsuleModel {
        return BTCapsuleModel(id: UUID().uuidString, text: self.text,
                              color: BTColorModel(color: self.capsuleColor,
                                                  id: 0,
                                                  textColor: self.textColor),
                              isSelected: false)
    }
}

/// 人员/群数据
struct BTIConCapsuleData: SKFastDecodable {
    var text: String = ""
    var icon: BTIcon? = nil

    static func deserialized(with dictionary: [String: Any]) -> BTIConCapsuleData {
        var model = BTIConCapsuleData()
        model.text <~ (dictionary, "text")
        model.icon <~ (dictionary, "icon")
        return model
    }
    
    func toCapsule() -> BTCapsuleModel {
        return BTCapsuleModel(id: UUID().uuidString,
                              text: self.text,
                              color: BTColorModel(color: "1F23291A"),
                              isSelected: false,
                              avatarUrl: self.icon?.url ?? "",
                              name: self.text,
                              enName: self.text)
    }
}

/// Check Box
struct BTCheckBoxData: SKFastDecodable {
    var checked: Bool = false

    static func deserialized(with dictionary: [String: Any]) -> BTCheckBoxData {
        var model = BTCheckBoxData()
        model.checked <~ (dictionary, "checked")
        return model
    }
}
/// 进度数据
struct BTProgressData: SKFastDecodable {
    // 进度比例
    var progress: Double = 0
    // 进度结果
    var text: String = ""
    // 进度条颜色值
    var color: String = ""

    static func deserialized(with dictionary: [String: Any]) -> BTProgressData {
        var model = BTProgressData()
        model.progress <~ (dictionary, "progress")
        model.text <~ (dictionary, "text")
        model.color <~ (dictionary, "color")
        return model
    }
}
/// 评分
struct BTRateData: SKFastDecodable {
    var rate: Int = 0
    var minRate: Int = 0
    var maxRate: Int = 5
    var symbol: String = "star" // 默认评分的icon

    static func deserialized(with dictionary: [String: Any]) -> BTRateData {
        var model = BTRateData()
        model.rate <~ (dictionary, "rate")
        model.minRate <~ (dictionary, "minRate")
        model.maxRate <~ (dictionary, "maxRate")
        model.symbol <~ (dictionary, "symbol")
        return model
    }
}
/// Button字段 value 数据
struct BTButtonData: SKFastDecodable {
    var text: String = ""
    var background: String = "" // 背景色
    var textColor: String = "#FFFFFF"

    static func deserialized(with dictionary: [String: Any]) -> BTButtonData {
        var model = BTButtonData()
        model.text <~ (dictionary, "text")
        model.background <~ (dictionary, "background")
        model.textColor <~ (dictionary, "textColor")
        return model
    }
}
/// Date 字段 value数据
struct BTDateData: SKFastDecodable {
    var text: String = ""
    var textColor: String = ""
    var remind: Bool = false // remind

    static func deserialized(with dictionary: [String: Any]) -> BTDateData {
        var model = BTDateData()
        model.text <~ (dictionary, "text")
        model.textColor <~ (dictionary, "textColor")
        model.remind <~ (dictionary, "remind")
        return model
    }
}

/// 阶段字段 value数据
struct BTStageData: SKFastDecodable {
    var text: String = ""
    var textColor: String = ""
    var capsuleColor: String = ""
    var type: BTStageModel.StageType = .defualt // 阶段字段当前阶段

    static func deserialized(with dictionary: [String: Any]) -> BTStageData {
        var model = BTStageData()
        model.text <~ (dictionary, "text")
        model.textColor <~ (dictionary, "textColor")
        model.capsuleColor <~ (dictionary, "capsuleColor")
        model.type <~ (dictionary, "type")
        return model
    }
}

/// 单/双向关联字段 value 数据
struct BTLinkData: SKFastDecodable {
    var text: String = ""

    static func deserialized(with dictionary: [String: Any]) -> BTLinkData {
        var model = BTLinkData()
        model.text <~ (dictionary, "text")
        return model
    }
}

/// 附件字段
//struct BTAttachmentData: SKFastDecodable {
//    var data: [BTAttachmentModel] = []
//    var srcObjToken: String? = nil
//
//    static func deserialized(with dictionary: [String: Any]) -> BTAttachmentData {
//        var model = BTAttachmentData()
//        model.data <~ (dictionary, "data")
//        model.srcObjToken <~ (dictionary, "srcObjToken")
//        return model
//    }
//}

typealias BTAttachmentData = BTAttachmentModel
