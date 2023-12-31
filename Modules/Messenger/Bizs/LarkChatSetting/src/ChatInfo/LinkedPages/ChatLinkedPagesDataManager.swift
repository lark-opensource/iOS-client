//
//  ChatLinkedPagesDataManager.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/19.
//

import RustPB
import LarkCore
import LarkModel
import Foundation
import EENavigator
import LarkOpenChat
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkSetting
import TangramService
import RxSwift
import RxCocoa
import LarkNavigator
import UniverseDesignToast

struct ChatLinkedPageModel {
    let url: String
    let hangPoint: RustPB.Basic_V1_PreviewHangPoint
    var inlineEntity: InlinePreviewEntity?

    var title: String {
        if let inlineTitle = inlineEntity?.title, !inlineTitle.isEmpty {
            return inlineTitle
        }
        return url
    }
}

class ChatLinkedPagesDataManager: UserResolverWrapper {

    var userResolver: UserResolver
    lazy var modelsDriver: Driver<[ChatLinkedPageModel]> = {
        return modelsBehaviorRelay.asDriver()
    }()
    private var modelsBehaviorRelay: BehaviorRelay<[ChatLinkedPageModel]> = BehaviorRelay<[ChatLinkedPageModel]>(value: [])

    private let logger = Logger.log(ChatLinkedPagesDataManager.self, category: "Module.IM.ChatLinkedPages")
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private let chatID: Int64
    private let disposeBag = DisposeBag()
    private var pushCenter: PushNotificationCenter? {
        return try? userResolver.userPushCenter
    }
    private weak var targetVC: UIViewController?

    init(userResolver: UserResolver, chatID: Int64, targetVC: UIViewController?) {
        self.userResolver = userResolver
        self.chatID = chatID
        self.targetVC = targetVC
    }

    func delete(_ pageURL: String) {
        self.chatAPI?.deleteChatLinkedPages(chatID: chatID, pageURLs: [pageURL])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                var models = self.modelsBehaviorRelay.value
                models.removeAll(where: { $0.url == pageURL })
                self.modelsBehaviorRelay.accept(models)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("delete ChatLinkedPages fail chatId: \(String(describing: self.chatID))", error: error)
                if let targetVC = self.targetVC {
                    UDToast.showFailureIfNeeded(on: targetVC.view, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    func setup() {
        pushCenter?.observable(for: URLPreviewScenePush.self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }

                let inlinePreviewEntities = push.inlinePreviewEntities
                var needUpdate: Bool = false
                var models = self.modelsBehaviorRelay.value
                for index in 0..<models.count {
                    var model = models[index]
                    if let inlineEntity = inlinePreviewEntities[model.hangPoint.previewID] {
                        if let oldInlineEntity = model.inlineEntity {
                            if inlineEntity.version >= oldInlineEntity.version {
                                model.inlineEntity = inlineEntity
                                needUpdate = true
                            }
                        } else {
                            model.inlineEntity = inlineEntity
                            needUpdate = true
                        }
                    }
                    models[index] = model
                }
                if needUpdate {
                    self.modelsBehaviorRelay.accept(models)
                }
            }).disposed(by: self.disposeBag)

        let chatID = self.chatID
        pushCenter?.observable(for: PushLocalDeleteChatLinkedPages.self)
            .filter { $0.chatID == chatID }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                let deleteURLs = Set(push.pageURLs)
                var models = self.modelsBehaviorRelay.value
                models.removeAll(where: { deleteURLs.contains($0.url) })
                if self.modelsBehaviorRelay.value.count != models.count {
                    self.modelsBehaviorRelay.accept(models)
                }
            }).disposed(by: self.disposeBag)

        var localFetchFail: Bool = false
        self.chatAPI?.fetchChatLinkedPages(chatID: chatID, isFromServer: false)
            .catchError { [weak self] error -> Observable<Im_V1_GetChatLinkedPagesResponse> in
                guard let self = self else { return .empty() }
                localFetchFail = true
                self.logger.error("fetchChatLinkedPages from local fail chatId: \(String(describing: self.chatID))", error: error)
                return self.chatAPI?.fetchChatLinkedPages(chatID: self.chatID, isFromServer: true) ?? .empty()
            }
            .flatMap { [weak self] response -> Observable<Im_V1_GetChatLinkedPagesResponse> in
                guard let self = self else { return .empty() }

                if localFetchFail {
                    /// 本地拉取失败，这里返回的是远端的
                    return .just(response)
                } else {
                    /// 先处理本地数据，再拉远端
                    self.handleResponse(response)
                    return self.chatAPI?.fetchChatLinkedPages(chatID: self.chatID, isFromServer: true) ?? .empty()
                }
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                self?.handleResponse(response)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("fetchChatLinkedPages from server fail chatId: \(String(describing: self.chatID))", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func handleResponse(_ response: RustPB.Im_V1_GetChatLinkedPagesResponse) {
        let inlinePreviewEntities = response.previewEntities.mapValues({ InlinePreviewEntity.transform(from: $0) })
        self.logger.info("fetchChatLinkedPages chatId: \(self.chatID) link count \(response.linkedPages.count)")
        let models = response.linkedPages.map { pageDetail in
            return ChatLinkedPageModel(
                url: pageDetail.url,
                hangPoint: pageDetail.urlPreviewHangPoint,
                inlineEntity: inlinePreviewEntities[pageDetail.urlPreviewHangPoint.previewID]
            )
        }
        self.modelsBehaviorRelay.accept(models)
    }
}
