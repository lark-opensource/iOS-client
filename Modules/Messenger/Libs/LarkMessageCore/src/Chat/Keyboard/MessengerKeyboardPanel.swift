//
//  MessengerKeyboardPanel.swift
//  LarkMessageCore
//
//  Created by bytedance on 7/1/22.
//

import Foundation
import UIKit
import RustPB
import LarkModel
import LarkSDKInterface
import LarkKeyboardView
import LarkMessageBase
import UniverseDesignActionPanel
import LarkChatOpenKeyboard
import FigmaKit
import UniverseDesignIcon
import UniverseDesignColor

//swiftlint:disable all
public protocol KeyboardPanelRightContainerViewProtocol: UIView {
//swiftlint:enable all
    func layoutWith(superView: UIView)
    func updateFor(_ scene: MessengerKeyboardPanel.Scene)
}

public extension KeyboardPanelRightContainerViewProtocol {
    public func updateFor(_ scene: MessengerKeyboardPanel.Scene) {}
}

public final class MessengerKeyboardPanel: KeyboardPanel {
    public weak var rightContainerViewDelegate: MessengerKeyboardPanelRightContainerViewDelegate?

    private var rightContainerViewCache: (Scene, KeyboardPanelRightContainerViewProtocol)?

    public enum Scene {
        case none
        case sendButton(enable: Bool)
        case submitView(enable: Bool)
        case scheduleSend(enable: Bool)
        case scheduleMsgEdit(enable: Bool,
                             itemId: String,
                             cid: String,
                             itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType)
        case sendQuickAction(enable: Bool)

        var rawValue: Int {
            switch self {
            case .none:
                return 0
            case .sendButton:
                return 1
            case .scheduleSend:
                return 2
            case .scheduleMsgEdit:
                return 3
            case .submitView:
                return 4
            case .sendQuickAction:
                return 5
            }
        }

    }

    public func reLayoutButtonWrapper(_ type: Scene) {
    }

    public func reLayoutRightContainer(_ type: Scene) {
        if let rightContainerViewCache = rightContainerViewCache,
           rightContainerViewCache.0.rawValue == type.rawValue {
            rightContainerViewCache.1.updateFor(type)
            return
        }

        panelTopBarRightContainer.subviews.forEach { child in
            child.removeFromSuperview()
        }
        if let view = getRightContainerView(by: type) {
            panelTopBarRightContainer.addSubview(view)
            view.layoutWith(superView: panelTopBarRightContainer)
            rightContainerViewCache = (type, view)
        } else {
            rightContainerViewCache = nil
        }
    }

    private func getRightContainerView(by type: Scene) -> KeyboardPanelRightContainerViewProtocol? {
        switch type {
        case .submitView(let enable):
            let submitView = KeyboardSubmitView(commitButtonEnable: enable)
            submitView.onCloseCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelCancel()
            }
            submitView.onCommitCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelCommit()
            }
            return submitView
        case .sendButton(let enable):
            let sendButton = DefaultKeyboardSendButton(enable: enable)
            sendButton.onTapCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelSendTap()
            }
            sendButton.onLongPressCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelSendLongPress()
            }
            return sendButton
        case .scheduleSend(let enable):
            let scheduleSendButtn = KeyboardSchuduleSendButton(enable: enable)
            scheduleSendButtn.onTapCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelSchuduleSendButtonTap()
            }
            return scheduleSendButtn
        case .scheduleMsgEdit(let enable, let itemId, let cid, let itemType):
            let submitView = KeyboardSubmitView(commitButtonEnable: enable)
            submitView.onCloseCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: itemId, itemType: itemType)
            }
            submitView.onCommitCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: itemId, cid: cid, itemType: itemType)
            }
            return submitView
        case .sendQuickAction(let enable):
            let submitView = KeyboardSubmitView(commitButtonEnable: enable)
            submitView.onCloseCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelCancel()
            }
            submitView.onCommitCallback = { [weak self] in
                self?.rightContainerViewDelegate?.onMessengerKeyboardPanelCommit()
            }
            submitView.commitButtonConfigurator = { commitButton in
                // 设置 normal 样式
                let sendIcon = UDIcon.getIconByKey(.sendFilled, size: .square(18)).ud.withTintColor(UIColor.ud.staticWhite)
                let normalGradientLayer = FKGradientLayer.fromPattern(UDColor.AILoading)
                let normalBgImage = UIImage.fromGradient(normalGradientLayer, frame: CGRect(origin: .zero, size: .square(10)))
                commitButton.setBackgroundImage(normalBgImage, for: .normal)
                commitButton.setImage(sendIcon, for: .normal)
                // 设置 highlight 样式
                let highlightGradientLayer = FKGradientLayer.fromPattern(UDColor.AIPrimaryFillPressed)
                let highlightBgImage = UIImage.fromGradient(highlightGradientLayer, frame: CGRect(origin: .zero, size: .square(10)))
                commitButton.setBackgroundImage(highlightBgImage, for: .highlighted)
                commitButton.setImage(sendIcon, for: .highlighted)
                // 设置 disable 样式
                let disableGradientLayer = FKGradientLayer.fromPattern(UDColor.AIPrimaryFillLoading)
                let disableBgImage = UIImage.fromGradient(disableGradientLayer, frame: CGRect(origin: .zero, size: .square(10)))
                commitButton.setBackgroundImage(disableBgImage, for: .disabled)
                commitButton.setImage(sendIcon, for: .disabled)
            }
            return submitView
        default:
            return nil
        }
    }

    public func getSendButton() -> KeyboardPanelRightContainerViewProtocol? {
        guard let rightContainerViewCache = rightContainerViewCache else { return nil }
        switch rightContainerViewCache.0 {
        case .sendButton:
            return rightContainerViewCache.1
        case .scheduleSend:
            return rightContainerViewCache.1
        case .sendQuickAction:
            return rightContainerViewCache.1
        default:
            return nil
        }
    }

    public func updateSendButtonEnableIfNeed(_ enable: Bool) {
        guard let view = getSendButton() else { return }
        guard let rightContainerViewCache = rightContainerViewCache else { return }
        switch rightContainerViewCache.0 {
        case .sendButton:
            view.updateFor(.sendButton(enable: enable))
        case .scheduleSend:
            view.updateFor(.scheduleSend(enable: enable))
        case .sendQuickAction:
            view.updateFor(.sendQuickAction(enable: enable))
        default:
            break
        }
    }
}

public protocol KeyboardSubmitViewDelegate: AnyObject {
    func onMessengerKeyboardPanelCommit()
    func onMessengerKeyboardPanelCancel()
}
public extension KeyboardSubmitViewDelegate {
    func onMessengerKeyboardPanelCommit() {}
    func onMessengerKeyboardPanelCancel() {}
}

public protocol KeyboardSendButtonDelegate: AnyObject {
    func onMessengerKeyboardPanelSendTap()
    func onMessengerKeyboardPanelSendLongPress()
}
public extension KeyboardSendButtonDelegate {
    func onMessengerKeyboardPanelSendTap() {}
    func onMessengerKeyboardPanelSendLongPress() {}
}

public protocol KeyboardSchuduleSendButtonDelegate: AnyObject {
    // 定时发送按钮点击
    func onMessengerKeyboardPanelSchuduleSendButtonTap()
    // 定时发送关闭按钮点击
    func onMessengerKeyboardPanelSchuduleExitButtonTap()
    func updateTip(_ tip: KeyboardTipsType)
    // 定时消息发送提示展示
    func scheduleTipDidShow(date: Date)
    // 定时消息编辑关闭按钮点击
    func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                        itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType)
    // 定时消息编辑确认按钮点击
    func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                          cid: String,
                                                          itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType)
    // 发送时间点击
    func onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: Date,
                                                     sendMessageModel: SendMessageModel,
                                                     _ task: @escaping (Date) -> Void)
}

public extension KeyboardSchuduleSendButtonDelegate {
    func onMessengerKeyboardPanelSchuduleSendButtonTap() {}
    func onMessengerKeyboardPanelSchuduleExitButtonTap() {}
    func updateTip(_ tip: KeyboardTipsType) {}
    func scheduleTipDidShow(date: Date) {}
    func onMessengerKeyboardPanelSchuduleCloseButtonTap(itemId: String,
                                                        itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {}
    func onMessengerKeyboardPanelSchuduleConfrimButtonTap(itemId: String,
                                                          cid: String,
                                                          itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType) {}
    func onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: Date,
                                                     sendMessageModel: SendMessageModel,
                                                     _ task: @escaping (Date) -> Void) {}
}

public typealias MessengerKeyboardPanelRightContainerViewDelegate = KeyboardSubmitViewDelegate & KeyboardSendButtonDelegate & KeyboardSchuduleSendButtonDelegate
