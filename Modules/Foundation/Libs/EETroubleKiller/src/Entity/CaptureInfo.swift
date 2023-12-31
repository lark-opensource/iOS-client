//
//  CaptureInfo.swift
//  EETroubleKiller
//
//  Created by lixiaorui on 2019/5/13.
//

import UIKit
import Foundation

/// 录/截屏日志信息
///
/// - none: 主动打点
/// - shot: 截屏
/// - captrue: 录屏
enum CaptureType: Int {

    case none = 0

    case record = 1

    case shot = 2
}

struct CaptureInfo {

    struct Frame: Codable {

        var x: CGFloat

        var y: CGFloat

        var w: CGFloat

        var h: CGFloat

    }

    var name: String

    var frame: Frame

    var visible: Bool

    var domainKey: [String: String]

    var subInfos: [CaptureInfo]

    init(name: String, frame: CGRect, visible: Bool, domainKey: [String: String] = [:], subInfos: [CaptureInfo] = []) {
        self.name = name
        self.frame = Frame(x: frame.origin.x, y: frame.origin.y, w: frame.width, h: frame.height)
        self.visible = visible
        self.domainKey = domainKey
        self.subInfos = subInfos
    }

}

extension CaptureInfo: Codable {

    enum CodingKeys: String, CodingKey {
        case name = "n"
        case frame = "f"
        case visible = "v"
        case domainKey = "k"
        case subInfos = "subs"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: CodingKeys.name)
        frame = try container.decode(CaptureInfo.Frame.self, forKey: CodingKeys.frame)
        visible = try container.decode(Bool.self, forKey: CodingKeys.visible)
        domainKey = try container.decode([String: String].self, forKey: CodingKeys.domainKey)
        subInfos = try container.decode([CaptureInfo].self, forKey: CodingKeys.subInfos)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: CodingKeys.name)
        try container.encode(visible, forKey: CodingKeys.visible)
        try container.encode(frame, forKey: CodingKeys.frame)
        try container.encode(domainKey, forKey: CodingKeys.domainKey)
        try container.encode(subInfos, forKey: CodingKeys.subInfos)
    }
}
