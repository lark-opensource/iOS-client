//
//  SearchCardBridgeImpl.swift
//  LarkSearch
//
//  Created by bytedance on 2021/8/5.
//

import Foundation
import LarkSearchCore
import EENavigator
import LKCommonsLogging
import LarkUIKit
import Lynx
import LarkContainer

protocol ASLynxBridgeDependencyDelegate: AnyObject {
    func contentChange(indexPath: IndexPath?)
    func changeQuery(_ query: String, vm: SearchCardViewModel)
    func sendClickEvent(vm: SearchCardViewModel, params: [String: Any])
    func openProfile(userId: String, vm: SearchCardViewModel)
    func openSearchTab(appId: String, tabName: String, vm: SearchCardViewModel)
}

extension ASLynxBridgeDependencyDelegate {
    func openSearchTab(appId: String, tabName: String, vm: SearchCardViewModel) {
    }

    func changeQuery(_ query: String, vm: SearchCardViewModel) {
    }
}

final class ASLynxBridgeDependencyWrapper: ASLynxBridgeDependency {
    weak var cell: SearchCardTableViewCell?

    private static let logger = Logger.log(ASLynxBridgeDependencyWrapper.self, category: "Module.Search.ASLynxBridgeDependencyWrapper")

    let userResolver: UserResolver
    init(userResolver: UserResolver, cell: SearchCardTableViewCell) {
        self.userResolver = userResolver
        self.cell = cell
    }

    func contentChange() {
        guard let vm = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        vm.jsBridgeDependency?.contentChange(indexPath: vm.indexPath)
        guard let storeVM = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        storeVM.isContentChangeByJSB = true
    }

    func changeQuery(_ query: String) {
        guard let vm = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        vm.jsBridgeDependency?.changeQuery(query, vm: vm)
    }

    func sendClickEvent(params: [String: Any]) {
        guard let vm = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        vm.jsBridgeDependency?.sendClickEvent(vm: vm, params: params)
    }

    func openProfile(userId: String) {
        guard let vm = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        vm.jsBridgeDependency?.openProfile(userId: userId, vm: vm)
    }

    func openSearchTab(appId: String, tabName: String) {
        guard let vm = self.cell?.viewModel as? SearchCardViewModel else {
            return
        }
        vm.jsBridgeDependency?.openSearchTab(appId: appId, tabName: tabName, vm: vm)
    }

    func openSchema(url: String) {
        guard let url = URL(string: url) else {
            Self.logger.error("【LarkSearch.ASLynxBridgeDependencyWrapper】- ERROR: url is illegal！")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let vc = self.userResolver.navigator.mainSceneTopMost else {
                Self.logger.error("【LarkSearch.ASLynxBridgeDependencyWrapper】- ERROR: vc is null！")
                return
            }
            if Display.pad {
                self.userResolver.navigator.present(url, wrap: LkNavigationController.self, from: vc)
            } else {
                self.userResolver.navigator.push(url, from: vc) // swiftlint:disable:this all
            }
        }
    }

    func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock) {}
}
