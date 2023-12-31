//
//  ChatPinCardCellViewModel.swift
//  LarkOpenChat
//
//  Created by zhaojiachen on 2023/5/12.
//

import Foundation
import LarkOpenIM
import RustPB

open class ChatPinCardCellViewModel: Module<ChatPinCardContext, ChatPinCardCellMetaModel> {
    open class var type: RustPB.Im_V1_UniversalChatPin.TypeEnum {
        assertionFailure("need override")
        return .unknown
    }

    public final override func canHandle(model: ChatPinCardCellMetaModel) -> Bool {
        return true
    }

    // MARK: 数据更新
    open override func modelDidChange(model: ChatPinCardCellMetaModel) {}
}

// MARK: 卡片的 UI 相关生命周期
public protocol ChatPinCardCellLifeCycle {
    /// 时机：视图将要显示
    func willDisplay()
    /// 时机：视图不再显示
    func didEndDisplay()
    /// 时机：容器尺寸发生变化
    func onResize()
}

// MARK: 卡片的 UI 渲染
public protocol ChatPinCardRenderAbility {
    // MARK: 复用标识符
    /// 为 nil 标识不需要复用
    static var reuseIdentifier: String? { get }

    // MARK: title 区域渲染
    associatedtype TV: UIView
    /// 初始化一个 title view
    func createTitleView() -> TV
    /// 更新 title view
    func updateTitletView(_ view: TV)
    /// 获取 title 区域 size
    func getTitleSize() -> CGSize

    // MARK: content 区域渲染
    associatedtype CV: UIView
    /// 初始化一个 content view
    func createContentView() -> CV
    /// 更新 content view
    func updateContentView(_ view: CV)
    /// 获取 content 区域 size
    func getContentSize() -> CGSize

    // MARK: icon 区域渲染
    func getIconConfig() -> ChatPinIconConfig?

    // MARK: 展示卡片 footer 区域
    var showCardFooter: Bool { get }

    // MARK: 卡片是否支持折叠
    var supportFold: Bool { get }
}

public extension ChatPinCardRenderAbility {
    var showCardFooter: Bool {
        return true
    }

    var supportFold: Bool {
        return false
    }
}

public protocol ChatPinCardActionProvider {
    /// 返回一组 Action 菜单
    func getActionItems() -> [ChatPinActionItemType]
}
