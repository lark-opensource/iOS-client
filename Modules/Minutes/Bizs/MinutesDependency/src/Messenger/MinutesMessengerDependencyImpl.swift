//
//  MinutesMessengerDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import Minutes
import Swinject
import EENavigator
#if MessengerMod
import LarkMessengerInterface
import LarkNavigation
import LarkUIKit
#endif
import LarkContainer
import LarkKAFeatureSwitch
import RustPB
import LarkSDKInterface
import RxSwift

public class MinutesMessengerDependencyImpl: MinutesMessengerDependency, UserResolverWrapper {
    var enterpriseEntityWordService: EnterpriseEntityWordService? {
        try? userResolver.resolve(assert: EnterpriseEntityWordService.self)
    }

    public let userResolver: UserResolver


    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }


    public func showEnterpriseTopic(abbrId: String, query: String) {
        #if MessengerMod
        let vc = userResolver.navigator.mainSceneTopMost
        enterpriseEntityWordService?.showEnterpriseTopicForIM(
            abbrId: abbrId,
            query: query,
            chatId: "",
            msgId: "",
            sense: .vc,
            targetVC: vc,
            clientArgs: nil,
            completion: nil,
            passThroughAction: nil
        )
        #endif
    }


    public func dismissEnterpriseTopic() {
        #if MessengerMod
        let vc = userResolver.navigator.mainSceneTopMost
        enterpriseEntityWordService?.dismissEnterpriseTopic(animated: true)
        #endif
    }

    public func pushOrPresentShareContentBody(text: String, from: NavigatorFrom?) {
        #if MessengerMod
        var fromViewController: NavigatorFrom?

        if let from = from {
            fromViewController = from
        } else {
            fromViewController = userResolver.navigator.mainSceneTopMost
        }

        if let fromViewController = fromViewController {
            let body = ShareContentBody(title: text, content: text)
            userResolver.navigator.present(body: body, from: fromViewController, prepare: { $0.modalPresentationStyle = .formSheet
            })
        }
        #endif
    }
    
    public func pushOrPresentPersonCardBody(chatterID: String, from: NavigatorFrom?) {
        #if MessengerMod
        var fromViewController: NavigatorFrom?

        if let from = from {
            fromViewController = from
        } else {
            fromViewController = userResolver.navigator.mainSceneTopMost
        }

        let body = PersonCardBody(chatterId: chatterID,
                                  source: .minutes)
        if let fromViewController = fromViewController {
            if Display.phone {
                userResolver.navigator.push(body: body, from: fromViewController)
            } else {
                userResolver.navigator.present(
                    body: body,
                    wrap: LkNavigationController.self,
                    from: fromViewController,
                    prepare: { vc in
                        vc.modalPresentationStyle = .formSheet
                    })
            }
        }
        #endif
    }
}
