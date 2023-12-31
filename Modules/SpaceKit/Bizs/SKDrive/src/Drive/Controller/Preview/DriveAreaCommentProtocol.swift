//
//  DriveAreaCommentProtocol.swift
//  Alamofire
//
//  Created by bupozhuang on 2019/7/24.
//

import Foundation
import SKCommon
import SKFoundation

enum DriveAreaCommentMode {
    /// 正常模式
    case normal
    /// 编辑模式，正在编辑选区
    case edit
}
protocol DriveAreaCommentDelegate: NSObjectProtocol {
    var commentViewFrame: CGRect { get }
    func commentAt(_ area: DriveAreaComment.Area, commentSource: DriveCommentSource)
    func didSelectAt(_ area: DriveAreaComment, commentSource: DriveCommentSource)
    func dismissCommentViewController()
    func getCommentVisible() -> Bool
    func commentViewDisplay(controller: DriveSupportAreaCommentProtocol)
    func areaComment(controller: DriveSupportAreaCommentProtocol, enter mode: DriveAreaCommentMode)
}

protocol DriveSupportAreaCommentProtocol: NSObjectProtocol {
    var areaCommentEnabled: Bool { get }
    func showAreaEditView(_ show: Bool)
    func updateAreas(_ areas: [DriveAreaComment])
    func areaDisplayView() -> UIView?
    func deselectArea()
    func selectArea(at index: Int)
    func selectArea(at commentId: String)
    func commentVCWillDismiss()
    var defaultCommentArea: DriveAreaComment.Area { get }
    var showComment: Bool { get set }
    var canComment: Bool { get set }
    var commentSource: DriveCommentSource { get }
    func didTapBlank(_ callback: @escaping (() -> Void))
}

extension DriveSupportAreaCommentProtocol {
    var areaCommentEnabled: Bool {
        return true
    }

    func showAreaEditView(_ show: Bool) {}

    func updateAreas(_ areas: [DriveAreaComment]) {}

    func areaDisplayView() -> UIView? {
        return nil
    }

    func deselectArea() {}

    func selectArea(at index: Int) {}

    func selectArea(at commentId: String) {}

    func commentVCWillDismiss() {}

    var showComment: Bool {
        get {
            return true
        }
        set {
            DocsLogger.driveInfo("showComment is: \(newValue)")
        }
    }

    var canComment: Bool {
        get {
            return true
        }
        set {
            DocsLogger.driveInfo("canComment is: \(newValue)")
        }
    }
    
    func didTapBlank(_ callback: @escaping (() -> Void)) {}
}

enum DriveCommentSource: Int {
    case pdf = 0
    case image
    /// 不支持局部评论的类型
    case unsupportAreaComment
}
