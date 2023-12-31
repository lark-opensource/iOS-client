//
//  TopicLynxDependency.swift
//  LarkAI
//
//  Created by bytedance on 2021/9/3.
//

import Foundation
import LKCommonsLogging
import LarkSearchCore
import LarkMessengerInterface
import LarkUIKit
import EENavigator
import CoreImage
import ServerPB
import RxSwift
import Lynx
import SwiftyJSON
import LarkMenuController
import LarkForward
import LarkContainer

/// 用于im&doc场景下的JSB Dependency
final class TopicLynxDependency: ASLynxBridgeDependency, UserResolverWrapper {
    private static let logger = Logger.log(TopicLynxDependency.self, category: "Module.AI.TopicLynxDependency")
    weak var viewModel: TopicLynxViewModel?
    let userResolver: UserResolver

    private var didTapApplink: ((URL) -> Void)?
    private var abbreviationAPI: EnterpriseEntityWordAPI
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver, viewModel: TopicLynxViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.didTapApplink = viewModel.didTapApplink
        self.abbreviationAPI = RustEnterpriseEntityWordAPI(resolver: userResolver)
    }

    func closePage() {
        guard let menuVC = self.viewModel?.menuVC as? MenuViewController else {
            self.viewModel?.hostVC?.dismiss(animated: true)
            TopicLynxDependency.logger.error("ERROR: menuVC is null！")
            return
        }
        menuVC.dismiss(animated: true, params: nil)
        TopicLynxDependency.logger.info("Page closed!")
    }

    func cardAction(id: String, action: Int) {
        guard let actionType = ServerPB_Enterprise_entitiy_UserCardActionRequest.ActionType(rawValue: action), let cardId = self.viewModel?.cardId else {
            return
        }
        self.abbreviationAPI.sendAbbreviationFeedbackRequet(cardId: cardId, actionType: actionType)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { ( _ ) in
                TopicLynxDependency.logger.info("ERROR: sendAbbreviationFeedbackRequet type = \(actionType) success!")
            }, onError: { (error) in
                TopicLynxDependency.logger.error("ERROR: sendAbbreviationFeedbackRequet type = \(actionType) error = \(error)")
            }).disposed(by: self.disposeBag)
    }

    func cardActionPassThrough(jsonString: String) {
        viewModel?.sendCardActionPassThrough(jsonString: jsonString)
        TopicLynxDependency.logger.info("card Action Passed Through!")
    }

    func openProfile(userId: String) {
        guard let fromVC = self.viewModel?.hostVC else {
            TopicLynxDependency.logger.error("ERROR: hostVC is null!")
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

    func openSchema(url: String) {
        guard let url = URL(string: url) else {
            Self.logger.error("ERROR: url is illegal！")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let didTapApplink = self.didTapApplink {
                didTapApplink(url)
            } else {
                guard let viewController = self.userResolver.navigator.mainSceneTopMost else {
                    Self.logger.error("【ERROR: vc is null！")
                    return
                }
                if Display.pad {
                    self.userResolver.navigator.present(url, wrap: LkNavigationController.self, from: viewController)
                } else {
                    self.userResolver.navigator.push(url, from: viewController) // swiftlint:disable:this all
                }
            }
        }
    }

    public func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let fromVC = self.viewModel?.hostVC else {
                TopicLynxDependency.logger.error("ERROR: hostVC is null!")
                return
            }

            let body = ForwardLingoBody(content: msgContent, title: title) { (userIds, chatIds) in
                var responseParam: [String: Any] = [:]
                var data: [String: Any] = [
                    "userIds": userIds,
                    "chatIds": chatIds
                ]
                responseParam["isSuccess"] = true
                responseParam["rawResponse"] = data
                callBack(responseParam)
            }
            if Display.phone {
                self.userResolver.navigator.push(body: body, from: fromVC)
            } else {
                self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC) { vc in
                    vc.modalPresentationStyle = .formSheet
                }
            }
        }

    }
}
