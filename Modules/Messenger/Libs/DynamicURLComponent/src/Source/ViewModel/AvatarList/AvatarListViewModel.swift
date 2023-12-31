//
//  AvatarListViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/7/29.
//

import Foundation
import RustPB
import RxSwift
import RxRelay
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

typealias ChatterInfo = Basic_V1_URLPreviewComponent.ChattersPreviewProperty.ChatterInfo

enum AvatarListViewStatus {
    case loading
    case display
    case error
}

// https://bytedance.feishu.cn/docx/doxcnI4kkZGkuxhXEcslUiZ19Ab
final class AvatarListViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    static let logger = Logger.log(AvatarListViewModel.self, category: "AvatarListViewModel")

    private let previewID: String
    private let componentID: String
    private let property: Basic_V1_URLPreviewComponent.ChattersPreviewProperty
    private var chattersMode: Basic_V1_URLPreviewComponent.ChattersPreviewProperty.ChattersMode {
        return property.chattersMode
    }
    @ScopedInjectedLazy private var chatterAPI: ChatterAPI?

    let disposeBag = DisposeBag()
    let title: String
    private var viewStatusSubject = PublishSubject<AvatarListViewStatus>()
    var viewStatusOb: Observable<AvatarListViewStatus> {
        return viewStatusSubject.asObserver()
    }

    private var loadMoreEnabled: Bool = true
    private var nextToken: String = ""
    private(set) var hasMore: Bool = true
    // 都在主线程操作，可不用加锁
    private var chatterInfos: [ChatterInfo] = []

    init(previewID: String, componentID: String, property: Basic_V1_URLPreviewComponent.ChattersPreviewProperty, userResolver: UserResolver) {
        self.previewID = previewID
        self.componentID = componentID
        self.property = property
        self.userResolver = userResolver
        title = property.title.isEmpty ? BundleI18n.DynamicURLComponent.Lark_Groups_member : property.title
    }

    func loadFirstScreen() {
        switch chattersMode {
        case .static: loadFirstScreenForStatic()
        case .dynamic: loadMoreForDynamic(isFirstScreen: true)
        @unknown default: assertionFailure("unknown case")
        }
    }

    // 静态模式，直接使用property里的数据展示
    private func loadFirstScreenForStatic() {
        // name或avatarKey为空时，需要主动拉取Chatter
        let needFetchIDs = property.chatterInfos.filter({ $0.name.isEmpty || $0.avatarKey.isEmpty }).map({ $0.chatterID })
        if needFetchIDs.isEmpty {
            append(new: property.chatterInfos)
        } else {
            viewStatusSubject.onNext(.loading)
            self.chatterAPI?.getChatters(ids: needFetchIDs)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatters) in
                    guard let self = self else { return }
                    let chatterInfos = self.property.chatterInfos.map { chatterInfo -> ChatterInfo in
                        var chatterInfo = chatterInfo
                        if let chatter = chatters[chatterInfo.chatterID] {
                            chatterInfo.name = chatter.name
                            chatterInfo.avatarKey = chatter.avatarKey
                        }
                        return chatterInfo
                    }
                    self.append(new: chatterInfos)
                    Self.logger.info("[URLPreview] loadFirstScreenForStatic -> \(needFetchIDs) -> \(chatters.keys)")
                }, onError: { [weak self] error in
                    self?.viewStatusSubject.onNext(.error)
                    Self.logger.error("[URLPreview] loadFirstScreenForStatic error -> \(needFetchIDs)", error: error)
                }).disposed(by: self.disposeBag)
        }
    }

    // 动态模式，需要调用接口拉取数据
    func loadMoreForDynamic(isFirstScreen: Bool) {
        guard property.chattersMode == .dynamic, hasMore, loadMoreEnabled else { return }
        self.loadMoreEnabled = false
        if isFirstScreen { viewStatusSubject.onNext(.loading) }
        chatterAPI?.fetchURLPreviewChatters(previewID: previewID, componentID: componentID, nextToken: nextToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                Self.logger.info("[URLPreview] loadMoreForDynamic",
                                 additionalData: ["previewID": self.previewID,
                                                  "componentID": self.componentID,
                                                  "paramNextToken": self.nextToken,
                                                  "hasMore": "\(response.hasMore_p)",
                                                  "resNextToken": response.nextToken,
                                                  "chatterIds": "\(response.chatterIds)",
                                                  "chatterInfos": "\(response.chatterInfos.map({ $0.chatterID }))"])
                self.hasMore = response.hasMore_p
                self.nextToken = response.nextToken
                if !response.chatterInfos.isEmpty {
                    self.loadMoreEnabled = true
                    self.append(new: response.chatterInfos)
                } else if !response.chatterIds.isEmpty {
                    self.chatterAPI?.getChatters(ids: response.chatterIds)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { [weak self] chatters in
                            guard let self = self else { return }
                            let chatterInfos = response.chatterIds.compactMap { id -> ChatterInfo? in
                                guard let chatter = chatters[id] else { return nil }
                                var chatterInfo = ChatterInfo()
                                chatterInfo.avatarKey = chatter.avatarKey
                                chatterInfo.chatterID = chatter.id
                                chatterInfo.name = chatter.name
                                return chatterInfo
                            }
                            self.loadMoreEnabled = true
                            self.append(new: chatterInfos)
                            Self.logger.info("[URLPreview] loadMoreForDynamic getChatters: \(chatters.keys)")
                        }, onError: { [weak self] _ in
                            guard let self = self else { return }
                            self.loadMoreEnabled = true
                            self.viewStatusSubject.onNext(.error)
                        }).disposed(by: self.disposeBag)
                } else {
                    // 兜底：取消loading
                    self.loadMoreEnabled = true
                    self.append(new: [])
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.loadMoreEnabled = true
                self.viewStatusSubject.onNext(.error)
                Self.logger.error("[URLPreview] loadMoreForDynamic error for: previewID = \(self.previewID), componentID = \(self.componentID), nextToken = \(self.nextToken)", error: error)
            }).disposed(by: disposeBag)
    }

    func append(new: [ChatterInfo]) {
        assert(Thread.isMainThread, "chatterInfos only accessible on main thread")
        self.chatterInfos.append(contentsOf: new)
        viewStatusSubject.onNext(.display)
    }

    func getChatterInfos() -> [ChatterInfo] {
        assert(Thread.isMainThread, "chatterInfos only accessible on main thread")
        return chatterInfos
    }
}
