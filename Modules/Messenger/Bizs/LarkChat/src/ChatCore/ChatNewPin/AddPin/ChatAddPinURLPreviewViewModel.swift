//
//  ChatAddPinURLPreviewViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/5.
//

import Foundation
import LKCommonsLogging
import LarkModel
import LarkCore
import LarkMessageCore
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkContainer
import LarkMessengerInterface
import EENavigator
import LarkOpenChat
import UniverseDesignToast
import DynamicURLComponent
import TangramService
import RustPB

enum ChatAddPinURLPreviewRefreshType: OuputTaskTypeInfo {
    case refreshTable

    func canMerge(type: ChatAddPinURLPreviewRefreshType) -> Bool {
        return true
    }

    var describ: String {
        switch self {
        case .refreshTable:
            return "refreshTable"
        }
    }

    func duration() -> Double {
        return 0
    }
    func isBarrier() -> Bool {
        return false
    }
}

final class ChatAddPinURLPreviewViewModel: AsyncDataProcessViewModel<ChatWidgetsRefreshType, [ChatAddPinURLPreviewTableViewCellViewModel]>, UserResolverWrapper {
    var userResolver: UserResolver
    private static let logger = Logger.log(ChatAddPinURLPreviewViewModel.self, category: "Module.IM.ChatPin")

    var availableMaxWidth: CGFloat = 0
    weak var targetVC: UIViewController?
    var chat: Chat {
        return self.chatBehaviorRelay.value
    }

    lazy var titleTypeDriver: Driver<ChatAddPinURLPreviewTitleType> = {
        return titleTypeBehaviorRelay.asDriver()
    }()
    private let titleTypeBehaviorRelay: BehaviorRelay<ChatAddPinURLPreviewTitleType>

    lazy var errorDriver: Driver<Error> = {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<Error>.empty() })
    }()
    private let errorPublish = PublishSubject<Error>()

    private var deleteToken: String = ""
    private var cellViewModels: [ChatAddPinURLPreviewTableViewCellViewModel] = []
    private var templateService: URLTemplateChatPinService?
    private var previewService: URLPreviewChatPinService?
    private var urlCardService: URLCardService?
    private let disposeBag = DisposeBag()
    private let chatBehaviorRelay: BehaviorRelay<Chat>
    private let addCompletion: (() -> Void)?
    let fromSearch: Bool
    @ScopedInjectedLazy private var chatAPI: ChatAPI?

    init(userResolver: UserResolver, chatBehaviorRelay: BehaviorRelay<Chat>, titleType: ChatAddPinURLPreviewTitleType, fromSearch: Bool, addCompletion: (() -> Void)?) {
        self.userResolver = userResolver
        self.chatBehaviorRelay = chatBehaviorRelay
        self.titleTypeBehaviorRelay = BehaviorRelay<ChatAddPinURLPreviewTitleType>(value: titleType)
        self.addCompletion = addCompletion
        self.fromSearch = fromSearch
        super.init(uiDataSource: [])
    }

    func setup() {
        guard let pushCenter = try? userResolver.userPushCenter else { return }
        self.urlCardService = URLCardService(userID: userResolver.userID)

        let urlPreviewAPI = try? self.userResolver.resolve(assert: URLPreviewAPI.self)
        self.previewService = URLPreviewChatPinServiceImp(
            pushCenter: pushCenter,
            urlPreviewAPI: urlPreviewAPI,
            chatId: self.chat.id
        )

        self.templateService = URLTemplateChatPinServiceImp(
            chatId: self.chat.id,
            pushCenter: pushCenter,
            updateHandler: { [weak self] missingTemplateIDs in
                guard let self = self else { return }
                let missingTemplateIDSet = Set(missingTemplateIDs)
                self.queueManager.addDataProcess { [weak self] in
                    guard let self = self else { return }
                    var previewIdsForLog: String = ""
                    var needUpdate: Bool = false
                    self.cellViewModels.forEach { cellVM in
                        guard let previewBody = cellVM.urlPreviewEntity?.previewBody else { return }
                        if previewBody.states.values.contains(where: {
                            return missingTemplateIDSet.contains($0.templateID)
                        }) {
                            needUpdate = true
                            previewIdsForLog += " \(cellVM.previewInfo.urlPreviewHangPoint.previewID)"
                            cellVM.handleSkeleton()
                            cellVM.updatePreview()
                        }
                    }
                    if needUpdate {
                        Self.logger.info("chatPinCardTrace add update templatePush chatId: \(self.chat.id) update previewIds \(previewIdsForLog)")
                        self.refresh()
                    }
                }
            },
            urlAPI: urlPreviewAPI
        )

        pushCenter.observable(for: URLPreviewScenePush.self)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }

                var previewIdsForLog: String = ""
                var needUpdate: Bool = false
                var updatedEntities = [URLPreviewEntity]()
                var dataSourcePreviewIDs: Set<String> = []

                self.cellViewModels.forEach { cellVM in
                    let previewID = cellVM.previewInfo.urlPreviewHangPoint.previewID
                    dataSourcePreviewIDs.insert(previewID)

                    let newUrlPreviewEntity = push.urlPreviewEntities[previewID]
                    let newInlineEntity = push.inlinePreviewEntities[previewID]
                    if cellVM.updateEntity(newUrlPreviewEntity: newUrlPreviewEntity,
                                           newInlineEntity: newInlineEntity) {
                        if let newUrlPreviewEntity = newUrlPreviewEntity {
                            updatedEntities.append(newUrlPreviewEntity)
                        }
                        needUpdate = true
                        previewIdsForLog += " \(previewID)"
                        /// 当解析 URL 链接 && 仅有一个预览链接（未分裂）的时候
                        /// 根据 inline 数据更新 title view
                        if self.cellViewModels.count == 1,
                           case .url(let urlModel) = self.titleTypeBehaviorRelay.value,
                           let newInlineEntity = newInlineEntity {
                            self.titleTypeBehaviorRelay.accept(.url(ChatAddPinURLPreviewTitleType.URLModel(url: urlModel.url, inlineEntity: newInlineEntity)))
                        }
                    }
                }

                self.previewService?.handleURLPreviews(entities: updatedEntities)
                if push.type == .sdk {
                    let previewIDs = push.needLazyLoadPreviews
                        .filter { $0.appID == URLPreviewChatPinSceneConfig.appID
                            && $0.appSceneType == URLPreviewChatPinSceneConfig.appSceneType
                            && dataSourcePreviewIDs.contains($0.previewID)
                        }
                        .map { return $0.previewID }
                    self.previewService?.fetchNeedLazyLoadPreviews(previewIds: previewIDs)
                }

                if needUpdate {
                    Self.logger.info("chatPinCardTrace add update scenePush chatId: \(self.chat.id) update previewIds \(previewIdsForLog)")
                    self.refresh()
                }
            }).disposed(by: self.disposeBag)
    }

    func createURLPreview() {
        guard let chatId = Int64(self.chat.id) else { return }

        let urlStr: String
        switch self.titleTypeBehaviorRelay.value {
        case .doc(let docModel):
            urlStr = docModel.url
        case .url(let urlModel):
            urlStr = urlModel.url
        }
        self.chatAPI?.notifyCreateUrlChatPinPreview(chatId: chatId, url: urlStr, deleteToken: deleteToken)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }

                self.deleteToken = res.nextDeleteToken
                let defaultTitle: String
                switch self.titleTypeBehaviorRelay.value {
                case .doc(let docModel):
                    defaultTitle = docModel.title
                case .url(let urlModel):
                    defaultTitle = urlModel.url
                }
                let isDefaultSelected: Bool = res.previewInfos.count <= 1
                let chatBehaviorRelay = self.chatBehaviorRelay

                res.previewInfos.forEach { previewInfo in
                    let cellVM = ChatAddPinURLPreviewTableViewCellViewModel(
                        userResolver: self.userResolver,
                        urlCardService: self.urlCardService,
                        templateService: self.templateService,
                        isSelected: isDefaultSelected,
                        previewInfo: previewInfo,
                        title: defaultTitle,
                        getAvailableMaxWidth: { [weak self] in
                            return self?.availableMaxWidth ?? .zero
                        },
                        getChat: { return chatBehaviorRelay.value },
                        updateHandler: { [weak self] in
                            guard let self = self else { return }
                            self.queueManager.addDataProcess {
                                self.refresh()
                            }
                        },
                        getTargetVC: { [weak self] in
                            return self?.targetVC
                        })

                    if let entityPB = res.previewEntities[previewInfo.urlPreviewHangPoint.previewID] {
                        _ = cellVM.updateEntity(newUrlPreviewEntity: URLPreviewEntity.transform(from: entityPB),
                                                newInlineEntity: InlinePreviewEntity.transform(from: entityPB))
                    }
                    self.cellViewModels.append(cellVM)
                }

                self.templateService?.update(templates: res.previewTemplates)
                self.previewService?.fetchMissingURLPreviews(models: self.cellViewModels)
                self.refresh()
                Self.logger.info("chatPinCardTrace createURLPreview success chatId: \(chatId) previewInfos count: \(res.previewInfos.count)")
            }, onError: { [weak self] error in
                self?.errorPublish.onNext(error)
                Self.logger.error("chatPinCardTrace createURLPreview fail chatId: \(chatId)", error: error)
            }).disposed(by: disposeBag)
    }

    func addPins() {
        guard let chatId = Int64(self.chat.id), let targetVC = targetVC else { return }
        let params = self.uiDataSource
            .filter { $0.isSelected }
            .map { cellVM in
                var previewInfo = cellVM.previewInfo
                previewInfo.title = cellVM.title
                if let inlineEntity = cellVM.inlineEntity,
                   let chatPinIcon = URLPreviewPinIconTransformer.convertToChatPinIcon(inlineEntity) {
                    previewInfo.icon = chatPinIcon
                } else {
                    Self.logger.info("chatPinCardTrace createUrlChatPin icon can not get from inlineEntity chatId: \(chatId) previewId: \(previewInfo.urlPreviewHangPoint.previewID)")
                }
                return (previewInfo, previewInfo.title != cellVM.inlineEntity?.title)
            }
        DelayLoadingObservableWraper
            .wraper(observable: self.chatAPI?.createUrlChatPin(chatId: chatId, params: params, deleteToken: self.deleteToken) ?? .empty(),
                    delay: 0.3,
                    showLoadingIn: targetVC.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, let targetView = self.targetVC?.view.window else { return }
                self.deleteToken = ""
                UDToast.showSuccess(with: BundleI18n.LarkChat.Lark_IM_NewPin_AddedToPinned_Toast, on: targetView)
                let addCompletion = self.addCompletion
                self.targetVC?.dismiss(animated: true, completion: { addCompletion?() })
            }, onError: { [weak targetVC] error in
                guard let targetVC = targetVC else { return }
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                Self.logger.error("chatPinCardTrace createUrlChatPin fail chatId: \(chatId)", error: error)
            }).disposed(by: self.disposeBag)

        var searchDoc = false
        if case .doc(_) = self.titleTypeBehaviorRelay.value {
            searchDoc = true
        }
        IMTracker.Chat.AddTop.Click.add(self.chat, fromSearch: fromSearch, addNum: params.count, searchDoc: searchDoc, isEdit: params.contains(where: { $0.1 }))
    }

    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            for cellVM in self.cellViewModels {
                cellVM.onResize()
            }
            self.refresh()
        }
    }

    func refresh() {
        self.tableRefreshPublish.onNext((.refreshTable, newDatas: self.cellViewModels, outOfQueue: false))
    }

    deinit {
        if !self.deleteToken.isEmpty, let chatId = Int64(self.chat.id) {
            _ = self.chatAPI?.deleteUrlChatPinPreview(chatId: chatId, deleteToken: self.deleteToken).subscribe()
        }
    }
}
