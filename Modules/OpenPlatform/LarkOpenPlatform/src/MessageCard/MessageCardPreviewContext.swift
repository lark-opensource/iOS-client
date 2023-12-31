//
//  MessageCardPreviewContext.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/13.
//

import UIKit
import NewLarkDynamic
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import LarkContainer
import EENavigator
import LarkNavigator
import ByteWebImage
import RxSwift
import RustPB
import LarkAlertController
import LarkUIKit
import LarkActionSheet
import SelectMenu
import LarkDatePickerView
import LarkSDKInterface
import LarkMessengerInterface
import LarkAppLinkSDK
import LarkFeatureGating
import ECOProbe
import RichLabel

class MessageCardPreviewContext: LDContext {
    private let cardContent: CardContent
    public let trace: OPTrace = OPTraceService.default().generateTrace()
    public var locale: Locale {
        BundleI18n.currentLanguage
    }
    public var messageID: String {
        return ""
    }
    /// 返回卡片的版本
    public var cardVersion: Int {
        return Int(cardContent.version)
    }
    public var cardAvailableMaxWidth: CGFloat
    /// 是否是宽版卡片
    public var wideCardMode: Bool
    /// 主动更新宽版卡片上下文
    public var wideCardContextUpdate: (() -> (Bool, CGFloat))
    /// 记录按钮的标题的elementId
    private var buttonTextElementMap: [String: ElementContext] = [:]
    private lazy var buttonTextLock: NSLock = NSLock()
    var selectionLabelDelegate: LKSelectionLabelDelegate?

    ///获取是否24小时制
    var is24HourTime:Bool = false
    ///获取时间配置服务
    @InjectedLazy private var timeFormatSettingService: TimeFormatSettingService
    ///
    public let actionObsever: ActionObserver

    public func getCopyabelComponentKey() -> String {
        return ""
    }
    /// 记录按钮标题的element ID
    public func recordButtonText(elementId: String, parentElement: ElementContext) {
        buttonTextLock.lock()
        buttonTextElementMap[elementId] = parentElement
        buttonTextLock.unlock()
    }
    /// 判断是不是按钮上面的标题
    public func isButtonText(elementId: String) -> Bool {
        buttonTextLock.lock()
        defer {
            buttonTextLock.unlock()
        }
        return buttonTextElementMap.keys.contains(elementId)
    }
    /// 判断按钮上面的标题所在的元素的上下文
    public func buttonContext(subTextElementId: String) -> ElementContext {
        return buttonTextElementMap[subTextElementId] ?? ElementContext(parentElement: RichTextElement())
    }
    public var cardType: LarkModel.CardContent.TypeEnum = .unknownType
    public var i18n: LDComponentI18n {
        return CardContentI18n()
    }
    public var actionFinished: Bool = true

    public func isMe(_ chatterID: String) -> Bool {
        return true
    }
    public func chatType() -> ChatType {
        return .p2P
    }
    init(cardContent: CardContent) {
        self.cardContent = cardContent
        self.wideCardMode = false
        self.cardAvailableMaxWidth = narrowCardMaxLimitWidth
        self.wideCardContextUpdate = {
            return (false, narrowCardMaxLimitWidth)
        }
        self.actionObsever = ActionObserver(key: "")
        self.is24HourTime = timeFormatSettingService.is24HourTime
    }
    public func setImageProperty(
        _ imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty,
        imageView: UIImageView,
        completion: NewLarkDynamic.Completion?) {
        let key = ImageItemSet.transform(imageProperty: imageProperty).generatePostMessageKey(forceOrigin: false)
        imageView.bt.setLarkImage(with: .default(key: key),
                                  trackStart: {
                                    return TrackInfo(scene: .Chat, fromType: .card)
                                  },
                                  completion: { result in
                                    switch result {
                                    case .success(let imageResult):
                                        completion?(nil, imageResult.image)
                                    case .failure(let error):
                                        completion?(error, nil)
                                    }
                                  })
    }

    public func setImageOrigin(
        _ originImageParams: OriginalImageParams,
        placeholderImg: UIImage? = nil,
        imageView: UIImageView,
        _ completion: NewLarkDynamic.Completion?) {
        imageView.bt.setLarkImage(with: .default(key: originImageParams.url),
                                  trackStart: {
                                    return TrackInfo(scene: .Chat, fromType: .card)
                                  },
                                  completion: { result in
                                    switch result {
                                    case .success(let imageResult):
                                        completion?(nil, imageResult.image)
                                    case .failure(let error):
                                        completion?(error, nil)
                                    }
                                  })
    }

    public func imagePreview(
        imageView: UIImageView,
        imageKey: String) {

    }

    public func openLink(_ url: URL, from: OpenLinkFromType, complete: ((LDCardError.ActionError?) -> Void)? = nil){
    }

    private func trackOpenLink(url: URL) {
    }

    public func openProfile(chatterID: String) {
    }

    public func presentController(vc: UIViewController, wrap: UINavigationController.Type?) {

    }

    public func selectChatter(sender: UIControl, chatterIDs: [String], complete: @escaping (String) -> Void) {

    }

    public func selectOverflowOption(sender: UIView,
                                     options: [OverFlowOption],
                                     complete: @escaping (OverFlowOption) -> Void) {

    }

    public func selectMenuOption(sender: UIControl, options: [SelectMenuOption], initialValue: String?, complete: @escaping (SelectMenuOption) -> Void) {
    }

    public func selectDate(sender: UIView, initialDate: String?, dateOption: DateOption, complete: @escaping (Date) -> Void) {

    }

    public func sendAction(actionID: String, params: [String: String]?) {

    }

    private func allowToAction(cardType: LarkModel.CardContent.TypeEnum) -> Bool {
        return false
    }

    private func triggerInterceptAction() -> Bool {
        return false
    }
    internal func updateWideCardContext() {
    }
    /// 获取对应的Action
    func action(actionID: String) -> LarkModel.CardContent.CardAction? {
        return nil
    }
}
