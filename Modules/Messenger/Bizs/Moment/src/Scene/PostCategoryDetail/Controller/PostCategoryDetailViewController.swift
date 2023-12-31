//
//  PostCategoryDetailViewController.swift
//  Moment
//
//  Created by liluobin on 2021/7/18.
//

import Foundation
import UIKit
import UniverseDesignToast
import LarkRustClient
import EENavigator
import LarkTab

final class PostCategoryDetailViewController: BasePostListViewController {
    override func onLoadError(_ error: Error) {
        if let error = error as? RCError {
            switch error {
            case .businessFailure(errorInfo: let info) where !info.displayMessage.isEmpty:
                // 读取失败 || 板块被删除
                switch info.code {
                case 330_503:
                    //版块被删除
                    if !info.displayMessage.isEmpty {
                        UDToast.showFailure(with: info.displayMessage, on: self.view.window ?? self.view)
                        delegate?.exitCurrentPostList()
                        userResolver.navigator.switchTab(Tab.moment.url, from: self, animated: false) { _ in }
                    }
                case 330_300:
                    //没有权限
                    UDToast.showFailure(with: info.displayMessage, on: self.view.window ?? self.view)
                    delegate?.exitCurrentPostList()
                default:
                    UDToast.showFailure(with: BundleI18n.Moment.Lark_Community_LoadingFailed, on: self.view.window ?? self.view)
                }
            default:
                break
            }
        }
    }
}
