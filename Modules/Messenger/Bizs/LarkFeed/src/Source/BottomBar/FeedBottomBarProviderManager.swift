//
//  FeedBottomBarProviderManager.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/27.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkContainer
import RxRelay
import RxSwift
import RxCocoa

struct FeedBottomBarProvider {
    let type: FeedBottomBarItemType
    var item: FeedBottomBarItem
    var view: UIView?
}

final class FeedBottomBarProviderManager {
    typealias AuthKey = String
    private let disposeBag = DisposeBag()
    private let context: UserResolver
    private var providerMap: [AuthKey: FeedBottomBarProvider] = [:]

    // 业务方持有 relay, manager 监听 observable
    private let commandRelay = PublishRelay<FeedBottomBarItemCommand>()
    private var commandObservable: Observable<(FeedBottomBarItemCommand)> {
        return commandRelay.asObservable()
    }

    // providerView变化
    private let visibleViewRelay = BehaviorRelay<(UIView?)>(value: nil)
    var visibleViewObservable: Observable<(UIView?)> {
        return visibleViewRelay.asObservable()
    }

    init(context: UserResolver) {
        self.context = context
        setupProviders()
        subscribeCommand()
    }

    private func setupProviders() {
        FeedBottomBarFactory.typeMap.forEach { [weak self] (authKey, type) in
            guard let self = self else { return }
            guard let item = FeedBottomBarFactory.item(context: self.context,
                                                       authKey: authKey,
                                                       relay: self.commandRelay) else { return }
            self.providerMap[authKey] = FeedBottomBarProvider(type: type, item: item, view: nil)
        }
    }

    private func subscribeCommand() {
        commandObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] command in
                guard let self = self else { return }
                switch command {
                case .render(let item):
                    self.updateProvider(by: item)
                    self.updateVisibleView()
                @unknown default:
                    return
                }
            }).disposed(by: disposeBag)
    }

    private func updateProvider(by item: FeedBottomBarItem) {
        guard var provider = providerMap[item.authKey] else { return }
        provider.item = item
        if item.display {
            if provider.view == nil {
                provider.view = FeedBottomBarFactory.view(context: context, for: item)
            }
        } else {
            provider.view = nil
        }
        providerMap[item.authKey] = provider
        FeedContext.log.info("feedlog/bottomBar/updateProvider. type: \(provider.type), "
                             + "display: \(provider.item.display), "
                             + "hasView: \(provider.view != nil)")
    }

    private func updateVisibleView() {
        var activeItem: FeedBottomBarProvider?
        for sortType in FeedBottomBarItemType.allCases {
            for provider in providerMap.values {
                if provider.type == sortType,
                   provider.item.display == true,
                   provider.view != nil {
                    activeItem = provider
                    break
                }
            }
        }
        visibleViewRelay.accept(activeItem?.view)

        if let provider = activeItem {
            FeedContext.log.info("feedlog/bottomBar/updateView. type: \(provider.type), "
                                 + "display: \(provider.item.display), "
                                 + "hasView: \(provider.view != nil)")
        } else {
            FeedContext.log.info("feedlog/bottomBar/updateView. none provider")
        }
    }
}
