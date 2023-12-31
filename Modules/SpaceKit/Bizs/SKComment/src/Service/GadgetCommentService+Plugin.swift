//
//  GadgetCommentService+Plugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/15.
//  


import SKFoundation
import UniverseDesignToast
import SpaceInterface
import SKCommon


extension GadgetCommentService: DocsCommentDependency {
    
    
    var businessConfig: CommentBusinessConfig {
        CommentBusinessConfig(canOpenURL: false, canOpenProfile: false, canShowDarkName: false)
    }
 
    /// 打开个人信息页
    /// - Parameters:
    ///   - userId: 用户ID或者unionId（小程序使用）
    ///   - from: 有值时表示期望在from页面展示个人信息页
    func showUserProfile(userId: String, from: UIViewController?) {
        // 目前from是在reaction detail才会传，小程序目前不支持
        if docInfo?.commentUser?.useOpenId == true {
            self.delegate?.openProfile(id: userId)
            DocsLogger.info("showUserProfile with openId", component: LogComponents.gadgetComment)
        } else {
            DocsLogger.info("showUserProfile with userId", component: LogComponents.gadgetComment)
            guard let currentVC = commentModule?.topMost else {
                DocsLogger.info("currentBrowserVC cannot be nil", component: LogComponents.gadgetComment)
                return
            }
            HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fileName: "", fromVC: currentVC))
        }
    }
    /// aside comment需要业务接入方自己关闭
    func dismissCommentView() {
        commentModule?.hide()
    }
}


extension GadgetCommentService: CommentRNAPIAdaperDependency {
    
    func showError(msg: String) {
        let view = commentModule?.topMost?.view.window ?? UIView()
        UDToast.showFailure(with: msg, on: view)
    }
}
