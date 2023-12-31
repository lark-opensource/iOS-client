//
//  AddCommentToastView.swift
//  SKCommon
//
//  Created by huayufan on 2022/2/9.
//  展示新建评论结果的toast


import UIKit
import UniverseDesignToast
import SKFoundation
import SKResource
import SpaceInterface


extension UDToast: CommentToastViewType {}


extension CommentToastInfo.Action {
    var text: String {
        switch self {
        case .showDetail:
            return BundleI18n.SKResource.CreationMobile_Comment_Added_ViewDetails
        case .retry:
            return BundleI18n.SKResource.CreationMobile_Common_ButtonRetry
        }
    }
}

extension CommentToastInfo.Result {
    /// (标题，操作)
    var showText: (String, String) {
        switch self {
        case .success:
            return (BundleI18n.SKResource.CreationMobile_Comment_Add_Success_Toast,
                    self.action.text)
        case .contentReviewFail:
            return(BundleI18n.SKResource.Doc_Review_Fail_Notify_Member(),
                   self.action.text)
        case .permissionFail:
            return(BundleI18n.SKResource.CreationMobile_Comment_Add_Failed_Toast,
                   self.action.text)
        case .networkFail:
            return(BundleI18n.SKResource.Doc_Comment_Send_Fail_By_Net,
                   self.action.text)
        }
    }
}

extension CommentToastInfo {
    static func serialization(params: [String: Any]) -> CommentToastInfo? {
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            DocsLogger.error("add comment serialization fail", component: LogComponents.comment)
            return nil
        }
        do {
            let model = try JSONDecoder().decode(CommentToastInfo.self, from: data)
            return model
        } catch {
            DocsLogger.error("add comment toast decode fail:\(error)", component: LogComponents.comment)
            return nil
        }
    }
}

class AddCommentToastViewImp: AddCommentToastView {
 
    func show(on: UIView, params: [String: Any], delay: CGFloat = 4, onClick: @escaping (CommentToastInfo) -> Void) {
        guard let info = CommentToastInfo.serialization(params: params) else { return }
        let (title, operationText) = info.result.showText
        if info.result == .success {
            var newTitle = title
            if let message = info.message, !message.isEmpty {
                newTitle = message
            }
            
            UDToast.showSuccess(with: newTitle,
                                operationText: operationText,
                                on: on,
                                delay: delay) { _ in
                onClick(info)
            }.observeKeyboard = false
            
        } else {
            
            UDToast.showFailure(with: title,
                                operationText: operationText,
                                on: on,
                                delay: delay) { _ in
                onClick(info)
            }.observeKeyboard = false

        }
    }
    
    func showLoading(on: UIView) -> CommentToastViewType {
        let toast = UDToast.showLoading(with: BundleI18n.SKResource.CreationMobile_Comment_Add_Sending_Toast, on: on)
        toast.observeKeyboard = false
        return toast
    }
}
