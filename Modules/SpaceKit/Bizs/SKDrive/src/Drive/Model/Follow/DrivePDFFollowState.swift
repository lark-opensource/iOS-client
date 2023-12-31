//
//  DrivePDFFollowState.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/1.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SpaceInterface

// State定义：https://bytedance.feishu.cn/docs/doccnONEDS3d1u1fmkF8C5AWfEg
enum DrivePDFFollowState {

    private static let defaultOffset = 0.5
    private static let defaultSacle = 1.0

    struct Location {
        // 1 ~ N
        var pageNumber: Int
        // 视图中心点相对于所在页左上角的偏移量，取值为 0 ~ 1
        let pageOffset: CGPoint
        // 缩放系数，自适应时为 1
        var scale: Double

        static var zero: Self {
            return Location(pageNumber: 0,
                            offsetLeft: defaultOffset,
                            offsetTop: defaultOffset,
                            scale: defaultSacle)
        }

        init(pageNumber: Int, pageOffset: CGPoint, scale: Double) {
            self.pageNumber = pageNumber
            self.pageOffset = pageOffset
            self.scale = scale
        }

        init(pageNumber: Int, offsetLeft: Double, offsetTop: Double, scale: Double) {
            let pageOffset = CGPoint(x: offsetLeft, y: offsetTop)
            self.init(pageNumber: pageNumber, pageOffset: pageOffset, scale: scale)
        }
    }

    case preview(location: Location, topLocation: Location?)
    case presentation(pageNumber: Int)

    static var `default`: Self {
        return .preview(location: .zero, topLocation: nil)
    }

    init?(json: JSON) {
        guard let pageNumber = json["pageNumber"].int else {
            return nil
        }
        let isPresentationMode = json["isPresentationMode"].bool ?? false
        if isPresentationMode {
            self = .presentation(pageNumber: pageNumber)
            return
        }
        let scale = json["scale"].double ?? Self.defaultSacle
        let pageOffsetTop = json["pageOffsetTop"].double ?? Self.defaultOffset
        let pageOffsetLeft = json["pageOffsetLeft"].double ?? Self.defaultOffset
        let location = Location(pageNumber: pageNumber,
                                offsetLeft: pageOffsetLeft,
                                offsetTop: pageOffsetTop,
                                scale: scale)
        let topLocation: Location?
        if let topPage = json["v2"]["pageNumber"].int,
           let topOffsetTop = json["v2"]["pageOffsetTop"].double {
            topLocation = Location(pageNumber: topPage,
                                   offsetLeft: pageOffsetLeft,
                                   offsetTop: topOffsetTop,
                                   scale: scale)
        } else {
            topLocation = nil
        }
        self = .preview(location: location, topLocation: topLocation)
    }
}

extension DrivePDFFollowState: DriveFollowModuleState {

    static var module: String {
        return FollowNativeModule.pdf.rawValue
    }

    var actionType: String {
        return "drive_pdf_update"
    }

    var data: JSON {
        var data: [String: Any] = [:]
        switch self {
        case let .presentation(pageNumber):
            data["isPresentationMode"] = true
            data["pageNumber"] = pageNumber
        case let .preview(location, topLocation):
            data["isPresentationMode"] = false
            data["pageNumber"] = location.pageNumber
            data["scale"] = location.scale
            data["pageOffsetLeft"] = location.pageOffset.x
            data["pageOffsetTop"] = location.pageOffset.y
            if let topLocation = topLocation {
                let topJSON: [String: Any] = [
                    "pageNumber": topLocation.pageNumber,
                    "pageOffsetTop": topLocation.pageOffset.y
                ]
                data["v2"] = topJSON
            }
        }
        return JSON(data)
    }

    init?(data: JSON) {
        self.init(json: data)
    }
}
