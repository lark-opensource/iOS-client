//
//  IslandAIChatBottomLayout.swift
//  LarkChat
//
//  Created by ByteDance on 2023/11/15.
//

import Foundation
import LarkContainer
import LarkCore
import LarkMessengerInterface
import UniverseDesignToast
import LKCommonsLogging
import LarkMessageCore
import LarkOpenChat
import RxSwift
import RxCocoa
import LarkModel
import LarkSDKInterface
import LarkRustClient
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import RustPB
import SnapKit
import EditTextView
import LarkChatKeyboardInterface
import LarkNavigator
import TangramService
import ByteWebImage
import LarkSendMessage
import LarkStorage
import LarkKeyCommandKit
import UIKit
import LarkUIKit

class IslandAIChatBottomLayout: NSObject, UserResolverWrapper {
    static let logger = Logger.log(IslandAIChatBottomLayout.self, category: "Module.IM.Message")
    private var componentGenerator: ChatViewControllerComponentGeneratorProtocol
    private let chatWrapper: ChatPushWrapper
    let userResolver: UserResolver
    let chatId: String
    private let pushCenter: PushNotificationCenter
    private let tableView: ChatTableView

    private var chat: BehaviorRelay<Chat> {
        return self.chatWrapper.chat
    }

    weak var delegate: AIChatBottomLayoutDelegate?

    private let disposeBag: DisposeBag = DisposeBag()

    private weak var _containerViewController: UIViewController?
    var containerViewController: UIViewController {
        return self._containerViewController ?? UIViewController()
    }

    private let isMyAIChatMode: Bool
    private var getMessageSender: () -> MessageSender?
    private let context: ChatModuleContext
    private var viewDidAppeared = false

    // 当前状态
    var chatBottomStatus: ChatBottomStatus = .none(display: true)

    private lazy var quasiMsgCreateByNative: Bool = {
        return false
    }()

    init(userResolver: UserResolver,
         context: ChatModuleContext,
         chatWrapper: ChatPushWrapper,
         componentGenerator: ChatViewControllerComponentGeneratorProtocol,
         containerViewController: UIViewController,
         pushCenter: PushNotificationCenter,
         tableView: ChatTableView,
         isMyAIChatMode: Bool,
         getMessageSender: @escaping () -> MessageSender?) {
        self.componentGenerator = componentGenerator
        self._containerViewController = containerViewController
        self.userResolver = userResolver
        self.chatWrapper = chatWrapper
        self.chatId = chatWrapper.chat.value.id
        self.context = context
        self.pushCenter = pushCenter
        self.tableView = tableView
        self.isMyAIChatMode = isMyAIChatMode
        self.getMessageSender = getMessageSender
    }
}

extension IslandAIChatBottomLayout: BottomLayout {
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
