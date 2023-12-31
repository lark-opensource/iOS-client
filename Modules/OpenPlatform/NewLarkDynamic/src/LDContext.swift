//
//  LDContext.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/18.
//

import Foundation
import LarkModel
import AsyncComponent
import LarkDatePickerView
import LarkZoomable
import RustPB
import UniverseDesignFont
import UIKit
import ECOProbe
import RichLabel

public typealias RichText = RustPB.Basic_V1_RichText
public typealias RichTextElement = RustPB.Basic_V1_RichTextElement

public typealias Completion = (Error?, UIImage?) -> Void
public typealias OriginalImageParams = (key: String, url: String)

public protocol LDComponentI18n {
    var unknownTag: String { get }
    var cancelText: String { get }
    var sureText: String { get }
}

public enum OpenLinkFromType {
    case cardLink(reason: String? = nil)
    case innerLink(reason: String? = nil)
    case footerLink(reason: String? = nil)
    case newcardOpenLink(reason: String? = nil)
    
    public func reason() -> String? {
        switch self {
        case .cardLink(let reason):
            return reason
        case .innerLink(let reason):
            return reason
        case .innerLink(let reason):
            return reason
        case .newcardOpenLink(let reason):
            return reason
        default:
            return nil
        }
    }
}
public struct ElementContext {
    public var parentElement: RichTextElement
    public init(parentElement: RichTextElement) {
        self.parentElement = parentElement
    }
    public func isLoading() -> Bool? {
        switch parentElement.tag {
        case .button:
            return parentElement.property.button.isLoading
        case .datepicker:
            return parentElement.property.datePicker.isLoading
        case .datetimepicker:
            return parentElement.property.datetimePicker.isLoading
        case .timepicker:
            return parentElement.property.timePicker.isLoading
        case .overflowmenu:
            return parentElement.property.overflowMenu.isLoading
        case .selectmenu:
            return parentElement.property.selectMenu.isLoading
        @unknown default:
            return nil
        }
    }
    public func isDisable() -> Bool? {
        switch parentElement.tag {
        case .button:
            return parentElement.property.button.disable
        case .datepicker:
            return parentElement.property.datePicker.disable
        case .timepicker:
            return parentElement.property.timePicker.disable
        case .datetimepicker:
            return parentElement.property.datetimePicker.disable
        case .overflowmenu:
            return parentElement.property.overflowMenu.disable
        case .selectmenu:
            return parentElement.property.selectMenu.disable
        @unknown default:
            return nil
        }
    }
}

public typealias OverFlowOption = (text: String, id: String, value: String)
public typealias SelectMenuOption = (text: String, value: String)
public typealias ChatType = LarkModel.Chat.TypeEnum
public typealias DateOption = DatePickerType
public protocol LDContext: AsyncComponent.Context {
    var locale: Locale { get }
    var messageID: String { get }
    var cardType: CardContent.TypeEnum { get }
    var i18n: LDComponentI18n { get }
    var actionFinished: Bool { get set }
    /// 是不是转发后的卡片消息
    var isForwardCardMessage: Bool { get }
    /// 卡片可渲染的最大宽度
    var cardAvailableMaxWidth: CGFloat { get set }
    /// 是否展示宽版卡片
    var wideCardMode: Bool { get set }
    /// context动态变化之后触发的回调
    var wideCardContextUpdate: (() -> (Bool, CGFloat)) { get }
    /// 卡片版本
    var cardVersion: Int { get }
    //获取是否24小时制
    var is24HourTime:Bool { get }

    var selectionLabelDelegate: LKSelectionLabelDelegate? { get }
    /// card Action Service
    var actionObsever: ActionObserver { get }
    
    var trace: OPTrace { get }
    
    func isMe(_ chatterID: String) -> Bool
    func chatType() -> ChatType
    func setImageProperty(
        _ imageProperty: RichTextElement.ImageProperty,
        imageView: UIImageView,
        completion: Completion?
    )
    func setImageOrigin(_ originImageParams: OriginalImageParams,
                        placeholderImg: UIImage?,
                        imageView: UIImageView,
                        _ completion: Completion?)
    func imagePreview(imageView: UIImageView, imageKey: String)
    func openLink(_ url: URL, from: OpenLinkFromType, complete: ((LDCardError.ActionError?) -> Void)?)
    func openProfile(chatterID: String)
    func presentController(vc: UIViewController, wrap: UINavigationController.Type?)
    func selectChatter(sender: UIControl, chatterIDs: [String], complete: @escaping (_ chatterID: String) -> Void)
    func selectOverflowOption(sender: UIView, options: [OverFlowOption], complete: @escaping (_ option: OverFlowOption) -> Void)
    func selectMenuOption(
        sender: UIControl,
        options: [SelectMenuOption],
        initialValue: String?,
        complete: @escaping (_ option: SelectMenuOption) -> Void
    )
    func selectDate(sender: UIView, initialDate: String?, dateOption: DateOption, complete: @escaping (_ date: Date) -> Void)
    func sendAction(actionID: String, params: [String: String]?)
    //卡片支持复制，获取componentKey
    func getCopyabelComponentKey() -> String
    /// 如果是转发的卡片，那么会走这个方法，返回true表示响应成功，后续不做其他处理
    func forwardMessageAction(actionID: String, params: [String: String]?) -> Bool
    /// 判断卡片字体是否可以放大
    func zoomAble() -> Bool
    /// 字体放大之后的字体
    func zoomFontSize(originSize: CGFloat, elementId: String?) -> CGFloat
    /// 记录按钮标题的element ID
    func recordButtonText(elementId: String, parentElement: ElementContext)
    /// 判断是不是按钮上面的标题
    func isButtonText(elementId: String) -> Bool
    /// 主动刷新宽版卡片的上下文
    func updateWideCardContext()
    /// DarkMode
    func messageCardStyle() -> [String: Any]?
    /// 获取对应的Action
    func action(actionID: String) -> LarkModel.CardContent.CardAction?
    /// 判断按钮上面的标题所在的元素的上下文
    func buttonContext(subTextElementId: String) -> ElementContext
}

///默认不是转发消息，LDContext协议在多处实现，避免引发多处编译错误
extension LDContext {
    
    var actionObsever: ActionObserver {
        get { return ActionObserver(key: "") } set {}
    }
    
    ///协议默认实现，默认不是转发消息
    public var isForwardCardMessage: Bool {
        return false
    }

    ///协议默认实现，处理转发消息，返回是否处理成功
    public func forwardMessageAction(actionID: String, params: [String: String]?) -> Bool {
        return false
    }
    
    /// 协议默认实现，卡片可渲染的最大宽度
    public var cardAvailableMaxWidth: CGFloat {
        return 300.0
    }
    
    /// 协议默认实现，卡片版本
    public var cardVersion: Int {
        #if DEBUG
        return 2
        #endif
        return 0
    }

    /// 协议默认实现，字体是否可以放大
    public func zoomAble() -> Bool {
        guard cardVersion >= 2 else {
            return false
        }
        guard ![UDZoom.normal, UDZoom.small1].contains(Zoom.currentZoom) else {
            return false
        }
        return true
    }
    /// 协议默认实现，字体放大之后的字体
    public func zoomFontSize(originSize: CGFloat, elementId: String? = nil) -> CGFloat {
        guard zoomAble() else {
            return originSize
        }
        if let actionId = elementId, isButtonText(elementId: actionId) {
            return originSize.auto(.s4)
        }
        return originSize.auto()
    }
    /// 记录按钮标题的element ID
    public func recordButtonText(elementId: String, parentElement: ElementContext) {
    }
    /// 判断是不是按钮上面的标题
    public func isButtonText(elementId: String) -> Bool {
        return false
    }
    /// 判断按钮上面的标题所在的元素的上下文
    public func buttonContext(subTextElementId: String) -> ElementContext {
        return ElementContext(parentElement: RichTextElement())
    }
    /// 主动刷新宽版卡片的上下文
    public func updateWideCardContext() {
        let (wideCardMode, cardAvailableMaxWidth) = self.wideCardContextUpdate()
        self.wideCardMode = wideCardMode
        self.cardAvailableMaxWidth = cardAvailableMaxWidth
    }
    ///  DarkMode
    public func messageCardStyle() -> [String: Any]? {
        return nil
    }
    /// 获取对应的Action
    func action(actionID: String) -> LarkModel.CardContent.CardAction? {
        return nil
    }
}
