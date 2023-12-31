//
//  FeedActionShortcutFactory.swift
//  LarkFeedPlugin
//
//  Created by liuxianyu on 2023/6/28.
//

import LarkModel
import LarkOpenFeed
import LarkSDKInterface
import RustPB
import RxSwift
import UniverseDesignDialog
import UniverseDesignToast

final class FeedActionShortcutFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .shortcut
    }

    func createActionViewModel(model: FeedActionModel, context: FeedCardContext) -> FeedActionViewModelInterface? {
        return FeedActionShortcutViewModel(model: model)
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return FeedActionShortcutHandler(type: type, model: model, context: context)
    }
}

final class FeedActionShortcutViewModel: FeedActionViewModelInterface {
    let title: String
    let contextMenuImage: UIImage
    let swipeEditImage: UIImage?
    let swipeBgColor: UIColor?
    init(model: FeedActionModel) {
        self.title = model.feedPreview.basicMeta.isShortcut ? BundleI18n.LarkFeed.Lark_Chat_FeedClickTipsUnpin :
                                                    BundleI18n.LarkFeed.Lark_Core_PinChatToTop_Button
        self.contextMenuImage = model.feedPreview.basicMeta.isShortcut ? Resources.feed_unpin_contextmenu : Resources.feed_pin_contextmenu
        self.swipeEditImage = model.feedPreview.basicMeta.isShortcut ? Resources.quickSwitcher_top : Resources.quickSwitcher_toTop
        self.swipeBgColor = UIColor.ud.colorfulBlue
    }
}

final class FeedActionShortcutHandler: FeedActionHandler {
    private let disposeBag = DisposeBag()
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        self.willHandle()

        let feedAPI = try? context.userResolver.resolve(assert: FeedAPI.self)
        var shortcut = Feed_V1_Shortcut()
        shortcut.channel = model.channel
        let toDeleteShortcut = model.feedPreview.basicMeta.isShortcut
        if toDeleteShortcut {
            feedAPI?.deleteShortcuts([shortcut])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.didHandle()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.didHandle(error: error)
                }).disposed(by: self.disposeBag)
        } else {
            feedAPI?.createShortcuts([shortcut])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    self.didHandle()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.didHandle(error: error)
                }).disposed(by: self.disposeBag)
        }
    }

    override func handleResultByDefault(error: Error?) {
        let toDeleteShortcut = model.feedPreview.basicMeta.isShortcut
        if error == nil {
            let tipText = toDeleteShortcut ? BundleI18n.LarkFeed.Lark_Chat_QuickswitcherUnpinClickToasts :
                                             BundleI18n.LarkFeed.Lark_Chat_QuickswitcherPinClickToasts
            if let window = model.fromVC?.view.window {
                UDToast.showTips(with: tipText, on: window)
            }
        } else {
            guard let apiError = error?.underlyingError as? APIError else {
                let tipText = toDeleteShortcut ? BundleI18n.LarkFeed.Lark_Feed_RemoveQuickSwitcherFail :
                                                 BundleI18n.LarkFeed.Lark_Feed_AddQuickSwitcherFail
                if let window = model.fromVC?.view.window, let failError = error {
                    UDToast.showFailure(with: tipText, on: window, error: failError)
                }
                return
            }
            guard let window = model.fromVC?.view.window else { return }
            let tipText = toDeleteShortcut ? BundleI18n.LarkFeed.Lark_Feed_RemoveQuickSwitcherFail :
            BundleI18n.LarkFeed.Lark_Feed_AddQuickSwitcherFail
            UDToast.showFailure(with: tipText, on: window, error: apiError)
        }
    }

    override func trackHandle(status: FeedActionStatus) {
        let toDeleteShortcut = model.feedPreview.basicMeta.isShortcut
        let shortcutID = model.feedPreview.id
        let chatID = model.feedPreview.id
        let chatTotalType = model.feedPreview.chatTotalType
        let chatSubType = model.feedPreview.chatSubType

        if case .willHandle = status {
            if let event = model.event {
                switch event {
                case .leftSwipe:
                    if let filterType = model.groupType {
                        FeedTracker.Leftslide.Click.Top(
                            toShortcut: !toDeleteShortcut,
                            feedPreview: model.feedPreview,
                            basicData: model.basicData,
                            bizData: model.bizData)
                    }
                case .longPress:
                    FeedTracker.Press.Click.Item(
                        itemValue: FeedActionType.clickTrackValue(type: .shortcut, feedPreview: model.feedPreview),
                        feedPreview: model.feedPreview,
                        basicData: model.basicData
                    )
                case .rightSwipe:
                    break
                @unknown default:
                    break
                }
            }

            if toDeleteShortcut {
                FeedPerfTrack.trackHandleShortcutStart(action: .delete, shortcutID: shortcutID)
                FeedTeaTrack.trackRemoveShortCut(chatID: chatID, type: chatTotalType, subType: chatSubType)
            } else {
                FeedPerfTrack.trackHandleShortcutStart(action: .add, shortcutID: shortcutID)
                FeedTeaTrack.trackAddShortCut(chatID: chatID, type: chatTotalType, subType: chatSubType)
            }
        } else if case .didHandle(let error) = status {
            if error == nil {
                FeedPerfTrack.updateShortcutSdkCost()
            } else if let apiError = error?.underlyingError as? APIError {
                FeedPerfTrack.trackHandleShortcutError(apiError, action: toDeleteShortcut ? .delete : .add)
            }
        }
    }
}
