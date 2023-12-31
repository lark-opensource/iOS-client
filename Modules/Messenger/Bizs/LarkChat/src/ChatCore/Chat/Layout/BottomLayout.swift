//
//  BottomLayout.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/8.
//

import Foundation
import LarkModel
import LarkChatKeyboardInterface
import SnapKit
import RxSwift
import RustPB
import LarkSDKInterface
import LarkKeyCommandKit

// 初始化相关逻辑实现
enum ChatBottomStatus {
    case none(display: Bool)
    case keyboard(display: Bool)   /// 输入框键盘
    case chatMenu(display: Bool) /// 群空间菜单
    case footerView(display: Bool) /// 自定义 footer
    case createThread(display: Bool) ///创建话题
    case frozenMask(display: Bool) /// 群被冻结

    var display: Bool {
        switch self {
        case .keyboard(let display), .chatMenu(let display), .footerView(let display),
                .createThread(let display), .none(let display), .frozenMask(let display):
            return display
        }
    }
}

protocol BottomLayout {
    var containerViewController: UIViewController { get }

    var chatBottomStatus: ChatBottomStatus { get }

    func setupBottomView()

    func toggleBottomStatus(to: ChatBottomStatus, animation: Bool)

    func toggleShowAndHideBottom(display: Bool)

    func getBottomHeight() -> CGFloat

    func getBottomControlTopConstraintInView() -> SnapKit.ConstraintItem?

    // 外部依赖
    func pageSupportReply() -> Bool

    func subProviders() -> [KeyCommandProvider]

    func hasInputViewInFirstResponder() -> Bool

    func keyboardExpending() -> Bool //是否有键盘展开

    func keepTableOffset() -> Bool

    func showToBottomTipIfNeeded() -> Bool

    func canHandleDropInteraction() -> Bool

    // 一些生命周期
    func afterFirstScreenMessagesRender()

    func viewWillAppear(_ animated: Bool)

    func viewDidAppear(_ animated: Bool)

    func viewWillDisappear(_ animated: Bool)

    func menuWillShow(isSheetMenu: Bool)

    func afterInitView()

    func onTable(refresh: ChatTableRefreshType)

    func tapTableHandler()

    func lockForShowEnterpriseEntityWordCard()

    func unlockForHideEnterpriseEntityWordCard()

    func screenCaptured(captured: Bool)

    func widgetExpand(expand: Bool)

    func showGuide(key: String)

    func handleTextTypeDropItem(text: String)
}

extension BottomLayout {
    func toggleBottomStatus(to: ChatBottomStatus, animation: Bool) {}

    func toggleShowAndHideBottom(display: Bool) {}

    func pageSupportReply() -> Bool {
        return false
    }

    // 一些生命周期
    func afterFirstScreenMessagesRender() {}

    func viewWillAppear(_ animated: Bool) {}

    func viewDidAppear(_ animated: Bool) {}

    func viewWillDisappear(_ animated: Bool) {}

    func menuWillShow(isSheetMenu: Bool) {}

    func afterInitView() {}

    func onTable(refresh: ChatTableRefreshType) {}

    func tapTableHandler() {}

    func lockForShowEnterpriseEntityWordCard() {}

    func unlockForHideEnterpriseEntityWordCard() {}

    func screenCaptured(captured: Bool) {}

    func widgetExpand(expand: Bool) {}

    func showGuide(key: String) {}
}

class EmptyBottomLayout: BottomLayout {
    var chatBottomStatus: ChatBottomStatus = .none(display: false)

    var containerViewController: UIViewController {
        return UIViewController()
    }

    func setupBottomView() {
    }

    func getBottomHeight() -> CGFloat {
        return 0
    }

    func getBottomControlTopConstraintInView() -> SnapKit.ConstraintItem? {
        return nil
    }

    func subProviders() -> [LarkKeyCommandKit.KeyCommandProvider] {
        return []
    }

    func hasInputViewInFirstResponder() -> Bool {
        return false
    }

    func keyboardExpending() -> Bool {
        return false
    }

    func keepTableOffset() -> Bool {
        return false
    }

    func showToBottomTipIfNeeded() -> Bool {
        return false
    }

    func canHandleDropInteraction() -> Bool {
        return false
    }

    func handleTextTypeDropItem(text: String) {
    }
}

protocol SaveChatDraft {
    var chatAPI: ChatAPI? { get }
    var chatId: String { get }
    func saveChatDraft(draft: RustPB.Basic_V1_Draft?)
}

extension SaveChatDraft {
    func saveChatDraft(draft: RustPB.Basic_V1_Draft?) {
        guard let chatAPI = self.chatAPI else { return }
        let draftId: String
        if let draft = draft, !draft.messageID.isEmpty {
            draftId = draft.id
        } else {
            draftId = ""
        }
        _ = chatAPI.updateLastDraft(chatId: self.chatId, draftId: draftId).subscribe()
    }
}
