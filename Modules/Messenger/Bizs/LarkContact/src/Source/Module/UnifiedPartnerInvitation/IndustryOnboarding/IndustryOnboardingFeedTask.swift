//
//  IndustryOnboardingFeedTask.swift
//  LarkContact
//
//  Created by Yuri on 2023/6/30.
//

import Foundation
import RxSwift
import BootManager
import EENavigator
import LarkTab
import LarkSplitViewController
import LarkUIKit
import LarkMessengerInterface
import LarkOpenFeed

final class IndustryOnboardingFeedTask: UserFlowBootTask, Identifiable {
    static var identify = "IndustryOnboardingFeedTask"

    typealias Module = ContactLogger.Module

    let disposeBag = DisposeBag()

    deinit {
        ContactLogger.shared.info(module: ContactLogger.Module.onboarding, event: "\(self) deinit")
    }

    override func execute(_ context: BootContext) {
        guard Display.pad,
              let urlString = IndustryOnboardingContext.shared.applink,
              !urlString.isEmpty else {
            ContactLogger.shared.info(module: Module.onboarding, event: "industry no applink")
            return
        }
        IndustryOnboardingContext.shared.applink = nil
        openApplink(urlString: urlString)
    }

    private func openApplink(urlString: String) {
        ContactLogger.shared.info(module: Module.onboarding, event: "industry - open app link: ", parameters: urlString)
        if URL(string: urlString) == nil {
            return
        }
        let map = parseURL(urlString)
        let seqID = "0"
        guard let feedId = map["feedId"],
              let feedType = map["entityType"],
              let schema = map["schema"],
              let codingStr = schema.removingPercentEncoding,
              let url = URL(string: codingStr) else {
            ContactLogger.shared.error(module: Module.onboarding, event: "industry - open app link failed: ", parameters: "\(urlString)")
            return
        }
        // 点击小程序仅进行跳转操作，连续点击 feed item 都做打开小程序的处理
        let context: [String: Any] = [
            FeedSelection.contextKey: FeedSelection(feedId: feedId),
            "from": "feed",
            "feedInfo": [
                "appID": feedId,
                "seqID": seqID,
                "type": feedType
            ]
        ]
        guard let feedService = try? self.userResolver.resolve(assert: FeedContextService.self) else {
            ContactLogger.shared.error(module: Module.onboarding, event: "industry - get feed service failed")
            return
        }
        let feedViewDidAppear: FeedPageState = .viewDidAppear
        feedService.pageAPI.pageStateObservable.asObservable().single { $0.rawValue >= feedViewDidAppear.rawValue }
            .subscribe(onNext: { _ in
                if let page = feedService.page {
                    feedService.userResolver.navigator.showDetailOrPush(url, context: context, wrap: LkNavigationController.self, from: page)
                } else {
                    ContactLogger.shared.error(module: Module.onboarding, event: "industry - get feed page failed")
                }
            }).disposed(by: disposeBag)
    }

    func parseURL(_ urlString: String) -> [String: String] {
        guard let url = URL(string: urlString) else {
            return [:]
        }
        var queryDict: [String: String] = [:]
        if let query = url.query {
            let components = URLComponents(string: urlString)
            // Handle multiple queries
            if let queryItems = components?.queryItems {
                for queryItem in queryItems {
                    queryDict[queryItem.name] = queryItem.value ?? ""
                }
            } else {
                let pairs = query.components(separatedBy: "&")
                for pair in pairs {
                    let keyValue = pair.components(separatedBy: "=")
                    if keyValue.count == 2 {
                        queryDict[keyValue[0]] = keyValue[1]
                    }
                }
            }
        }

        return queryDict
    }
}
