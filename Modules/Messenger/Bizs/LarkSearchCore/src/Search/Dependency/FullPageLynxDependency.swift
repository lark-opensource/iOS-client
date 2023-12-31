//
//  FullPageLynxDependency.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/6/29.
//

import Foundation
import LKCommonsLogging
import LarkMessengerInterface
import LarkUIKit
import EENavigator
import CoreImage
import Lynx
import LarkContainer

/// 用于通用场景下的JSB Dependency
final public class FullPageLynxDependency: ASLynxBridgeDependency {

    public weak var viewModel: FullPageLynxViewModel?

    private static let logger = Logger.log(FullPageLynxDependency.self, category: "LarkSearchCore.FullPageLynxDependency")

    public var userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: FullPageLynxViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
    }

    public func closePage() {
        self.viewModel?.hostVC?.dismiss(animated: true)
        FullPageLynxDependency.logger.info("Page closed!")
    }

    public func openProfile(userId: String) {
        guard let fromVC = self.viewModel?.hostVC else {
            FullPageLynxDependency.logger.error("ERROR: hostVC is null!")
            return
        }
        let body = PersonCardBody(chatterId: userId, fromWhere: .search)
        if Display.phone {
            userResolver.navigator.push(body: body, from: fromVC)
        } else {
            userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC) { vc in
                vc.modalPresentationStyle = .formSheet
            }
        }
    }

    public func openSchema(url: String) {
        guard let url = URL(string: url) else {
            Self.logger.error("【LarkSearchCore.FullPageLynxDependency】- ERROR: url is illegal！")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let viewController = self.userResolver.navigator.mainSceneTopMost else { Self.logger.error("【LarkSearchCore.FullPageLynxDependency】- ERROR: vc is null！")
                return
            }
            if Display.pad {
                self.userResolver.navigator.present(url, wrap: LkNavigationController.self, from: viewController)
            } else {
                self.userResolver.navigator.push(url, from: viewController) // swiftlint:disable:this all
            }
        }
    }

    public func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock) {}
}
