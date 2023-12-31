//
//  WikiContainerViewController+Follow.swift
//  SKWikiV2
//
//  Created by bytedance on 2021/6/28.
//

import Foundation

import SKFoundation
import SpaceInterface
import SwiftyJSON
import RxSwift
import SKCommon
import SKUIKit

extension WikiContainerViewController: FollowableViewController {

    var isEditingStatus: Bool {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow isEditingStatus: The lastChildVC not implement FollowableViewController")
            return false
        }
        return childFollowVC.isEditingStatus
    }

    var followTitle: String {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow Title: The lastChildVC not implement FollowableViewController")
            return ""
        }
        return childFollowVC.followTitle
    }

    var canBackToLastPosition: Bool {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow View: The lastChildVC not implement FollowableViewController")
            return false
        }
        return childFollowVC.canBackToLastPosition
    }

    var followScrollView: UIScrollView? {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow View: The lastChildVC not implement FollowableViewController")
            return nil
        }
        return childFollowVC.followScrollView
    }

    func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        self.spaceFollowAPIDelegate = followAPIDelegate
    }

    func refreshFollow() {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow refresh: The lastChildVC not implement FollowableViewController")
            return
        }
        childFollowVC.refreshFollow()
    }

    var followVC: UIViewController {
        return self
    }

    func onDestroy() {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow onDestroy: The lastChildVC not implement FollowableViewController")
            return
        }
        childFollowVC.onDestroy()
    }

    func onOperate(_ operation: SpaceFollowOperation) {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow onOperate: The lastChildVC not implement FollowableViewController")
            return
        }
        childFollowVC.onOperate(operation)
    }

    func onRoleChange(_ newRole: FollowRole) {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow oonRoleChange: The lastChildVC not implement FollowableViewController")
            return
        }
        childFollowVC.onRoleChange(newRole)
    }

    func executeJSFromVcfollow(operation: String, params: [String: Any]?) {
        guard let childFollowVC = lastChildVC as? FollowableViewController else {
            DocsLogger.warning("Follow keepCurrentPosition: The lastChildVC not implement FollowableViewController")
            return
        }
        childFollowVC.executeJSFromVcfollow(operation: operation, params: params)
    }
}
