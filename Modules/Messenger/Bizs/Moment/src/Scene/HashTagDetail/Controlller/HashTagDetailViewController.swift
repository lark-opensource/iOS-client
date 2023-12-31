//
//  HashTagDetailViewController.swift
//  Moment
//
//  Created by liluobin on 2021/7/20.
//

import Foundation
import UIKit
import LarkRustClient
import UniverseDesignToast
import UniverseDesignEmpty

final class HashTagDetailViewController: BasePostListViewController {
    var onFirstScreenLoadFinish: ((Bool) -> Void)?

    override func emptyTitle() -> String {
        guard let vm = self.viewModel as? HashTagDetailViewModel else {
            return ""
        }
        return vm.hashTagOrder == .participateCount ? BundleI18n.Moment.Lark_Community_HotTopicEmptyDesc : super.emptyTitle()
    }
    override func emptyType() -> UDEmptyType {
        guard let vm = self.viewModel as? HashTagDetailViewModel else {
            return super.emptyType()
        }
        return vm.hashTagOrder == .participateCount ? .noContent : super.emptyType()
    }
    override func firstScreenLoadFinish(_ isEmpty: Bool) {
        onFirstScreenLoadFinish?(isEmpty)
    }

    override func onLoadError(_ error: Error) {
        if let error = error as? RCError {
            switch error {
            case .businessFailure(errorInfo: let info):
                // 读取失败 || 板块被删除
                switch info.code {
                case 330_300, 330_503:
                    //没有公司圈权限
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
