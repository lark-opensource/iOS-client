//
//  DriveCommentRegion.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/13.
//

import Foundation
import SKCommon
import SpaceInterface

struct DriveAreaComment: Codable, Equatable {
    /// type = 1 时为矩形的定义 左上角与右下角 相对位置
    enum AreaType: Int, Codable {
        case unknow = 0
        /// 有选区，选区为矩形
        case rect = 1
        /// 历史全文评论洗数据为局部评论，没有选区信息
        case history = 2
        /// 用户没有选择区域直接评论，没有选区信息
        case noArea = 3
        /// pdf文字选区
        case text = 4
        var hasArea: Bool {
            return self == .rect || self == .text
        }
        var noArea: Bool {
            return self == .unknow || self == .history || self == .noArea
        }
    }
    struct Area: Codable {
        /// 页数，图片默认0，pdf的话是页数 index
        let page: Int
        let originX: CGFloat
        let originY: CGFloat
        let endX: CGFloat
        let endY: CGFloat
        let quads: [DrivePDFQuadPoint]?
        let text: String?
        init(page: Int = 0, originX: CGFloat, originY: CGFloat,
             endX: CGFloat, endY: CGFloat, quads: [DrivePDFQuadPoint]? = nil, text: String? = nil) {
            self.page = page
            self.originX = originX
            self.originY = originY
            self.endX = endX
            self.endY = endY
            self.quads = quads
            self.text = text
        }
        private enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case page
            case originX = "left"
            case originY = "top"
            case endX = "right"
            case endY = "bottom"
            case quads = "quads"
            case text = "text"
        }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            page = (try? container.decodeIfPresent(Int.self, forKey: .page)) ?? 0
            originX = (try? container.decodeIfPresent(CGFloat.self, forKey: .originX)) ?? 0.0
            originY = (try? container.decodeIfPresent(CGFloat.self, forKey: .originY)) ?? 0.0
            endX = (try? container.decodeIfPresent(CGFloat.self, forKey: .endX)) ?? 0.0
            endY = (try? container.decodeIfPresent(CGFloat.self, forKey: .endY)) ?? 0.0
            quads = try? container.decodeIfPresent([DrivePDFQuadPoint].self, forKey: .quads)
            text = try? container.decodeIfPresent(String.self, forKey: .text)
        }
        func areaFrame(in supperView: UIView) -> CGRect {
            let origin = CGPoint(x: supperView.frame.width * originX.roundInOne(),
                                 y: supperView.frame.height * originY.roundInOne())
            let width = supperView.frame.width * (endX.roundInOne() - originX.roundInOne())
            let height = supperView.frame.height * (endY.roundInOne() - originY.roundInOne())
            return CGRect(origin: origin, size: CGSize(width: width, height: height))
        }
    }
    var commentID: String
    let version: String?
    let type: AreaType
    var region: Area?
    var createTimeStamp: TimeInterval = 0
    var comment: Comment?
    private enum CodingKeys: String, CodingKey {
        case commentID = "comment_id"
        case version = "version"
        case areaCoordinate = "drive_area_coordinate"
        case type = "type"
        case region = "position"
    }
    init(commentID: String, version: String, type: AreaType, area: Area?) {
        self.commentID = commentID
        self.version = version
        self.type = type
        self.region = area
    }
    // 可选值都使用用try? 避免可选值key存在但是解析失败的情况导致整个comment解析失败
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commentID = try container.decode(String.self, forKey: .commentID)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        let areaCoordinate = try container.nestedContainer(keyedBy: CodingKeys.self,
                                                           forKey: .areaCoordinate)
        type = (try? areaCoordinate.decodeIfPresent(AreaType.self, forKey: .type)) ?? .unknow
        region = try? areaCoordinate.decodeIfPresent(Area.self, forKey: .region)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commentID, forKey: .commentID)
        try container.encode(version, forKey: .version)
        var areaCoordinate = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .areaCoordinate)
        try areaCoordinate.encode(type, forKey: .type)
        try areaCoordinate.encode(region, forKey: .region)
    }

    static func == (lhs: DriveAreaComment, rhs: DriveAreaComment) -> Bool {
        return lhs.commentID == rhs.commentID
    }
}

extension CGRect {
    func relativeArea(in frame: CGRect) -> DriveAreaComment.Area {
        guard frame.width > 0 && frame.height > 0 else {
            return DriveAreaComment.Area(originX: 0, originY: 0, endX: 0, endY: 0)
        }
        let originX = origin.x / frame.width
        let originY = origin.y / frame.height
        let endX = (origin.x + width) / frame.width
        let endY = (origin.y + height) / frame.height
        return DriveAreaComment.Area(originX: originX,
                                     originY: originY,
                                     endX: endX,
                                     endY: endY)
    }
}
extension CGPoint {
    func relativePoint(in frame: CGRect) -> CGPoint {
        guard frame.width > 0 && frame.height > 0 else {
            return .zero
        }
        let relativeX = x / frame.width
        let relativeY = y / frame.height
        return CGPoint(x: relativeX.roundInOne(), y: relativeY.roundInOne())
    }
    func absolutedPoint(in frame: CGRect) -> CGPoint {
        let absX = x * frame.width
        let absY = y * frame.height
        return CGPoint(x: absX.roundIn(min: 0, max: frame.width),
                       y: absY.roundIn(min: 0, max: frame.height))
    }
}
extension CGFloat {
    func roundIn(min: CGFloat, max: CGFloat) -> CGFloat {
        if self < min {
            return 0
        } else if self > max {
            return max
        }
        return self
    }
    func roundInOne() -> CGFloat {
        return roundIn(min: 0, max: 1)
    }
}

extension DriveAreaComment.Area {
    var width: CGFloat {
        return endX - originX
    }
    var height: CGFloat {
        return endY - originY
    }
    static var blankArea: DriveAreaComment.Area {
        return DriveAreaComment.Area(page: 0,
                                     originX: 0,
                                     originY: 0,
                                     endX: 0,
                                     endY: 0,
                                     quads: nil,
                                     text: nil)
    }
    var isPageComment: Bool {
        return self.originX == 0 && self.originY == 0
            && self.endX == 0 && self.endY == 0
            && self.quads == nil && self.text == nil
    }
    var isBlankArea: Bool {
        return self.page == 0
        && self.originX == 0 && self.originY == 0
        && self.endX == 0 && self.endY == 0
        && self.quads == nil && self.text == nil
    }
}

extension Array where Element == DriveAreaComment {
    /// 局部评论commentId数组
    var partCommentIds: [String] {
        var result = [String]()
        self.forEach { item in
            if item.type.hasArea { // 有选区
                result.append(item.commentID)
            }
        }
        return result
    }
}
