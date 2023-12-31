//
//  MsgCardLynxIcon.swift
//  LarkMessageCard
//
//  Created by zhangjie.alonso on 2023/6/14.
//

import Foundation
import Lynx
import LKCommonsLogging
import ByteWebImage
import LarkModel
import RustPB
import ByteDanceKit
import UniverseDesignIcon
import EENavigator
import LarkNavigator
import LarkContainer
import TangramService
import UniverseDesignColor
import LarkOPInterface


private final class MsgCardIconView: ByteImageView {
    public override var clipsToBounds: Bool {
        didSet {
            if clipsToBounds == false {
                clipsToBounds = true
            }
        }
    }
}

public final class MsgCardLynxIconView: LynxUIView {

    public static let name: String = "card-ud-icon"

    static let logger = Logger.oplog(MsgCardLynxIconView.self, category: "MsgCardLynxIconView")

    @InjectedLazy private var cardContextManager: MessageCardContextManagerProtocol
    @InjectedOptional private var openPlatformService: OpenPlatformService?
    var cardContext: MessageCardContainer.Context?
    private var props: [AnyHashable: Any]?

    lazy private var iconView: ByteImageView = {
        var iconView: MsgCardIconView = MsgCardIconView()
        iconView.clipsToBounds = true
        return iconView
    }()

    // 将属性和相应的设置属性函数关联
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
            ["context", NSStringFromSelector(#selector(setContext))]
        ]
    }

    @objc
    public override func createView() -> UIImageView? {
        return self.iconView
    }

    @objc func setContext(context: Any?, requestReset _: Bool) {
        guard let context = context as? [AnyHashable: Any] else { return }
        guard let key = context["key"] as? String,
                let cardContext = cardContextManager.getContext(key: key) else {
            return
        }
        self.cardContext = cardContext
        if (iconView.image == nil) {
            setFallbackImage { self.iconView.image = nil }
        }
    }

    @objc func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [AnyHashable: Any] else  {
            Self.logger.error("iconProps error")
            return
        }
        var color: UIColor?

        //customColor优先级大于原有color
        if let token = props["token"] as? String,
           !token.contains("_colorful") {
            if let customColorHexStr = props["customColor"] as? String {
                color = UIColor.btd_color(withARGBHexString: customColorHexStr)
            } else if let colorToken =  props["color"] as? String {
                color = UDColor.getValueByBizToken(token: colorToken)
            }
        }

        if let token = props["token"] as? String,
           let image = URLPreviewUDIcon.getIconByKey(token, iconColor: color) {
            iconView.image = image
            iconView.contentMode = .scaleAspectFit
        } else {
            self.props = props
            setFallbackImage() { self.iconView.image = nil }
        }
    }

    func setFallbackImage(onError: (() -> Void)){
        guard let cardContext = cardContext,
              let props = props,
              let imageID = props["imageID"] as? String,
              let isTranslateElement: Bool = props["isTranslateElement"] as? Bool else {
            onError()
            return
        }
        var cardContent: LarkModel.CardContent?
        //消息场景
        if let message = cardContext.bizContext["message"] as? Message {
            if isTranslateElement {
                cardContent = message.translateContent as? LarkModel.CardContent
            } else {
                cardContent = message.content as? LarkModel.CardContent
            }
        } else if let content = cardContext.bizContext["pinPreviewContent"] as? LarkModel.CardContent {
            //unpin 预览场景
           cardContent = content
        } else {
            //sendMessageCard
            cardContent = openPlatformService?.fetchCardContent()
        }

        guard  let imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty = cardContent?.jsonAttachment?.images[imageID] else {
            Self.logger.error("cardContent no imageProperty \(imageID) ")
            onError()
            return
        }

        let imageToken = ImageItemSet.transform(imageProperty:imageProperty).generatePostMessageKey(forceOrigin: false)
        DispatchQueue.main.async {
            self.iconView.bt.setLarkImage(with: .default(key: imageToken), completion:  { result in
                switch result {
                case .failure(let error):
                    Self.logger.error(" iconView set image fail,error:\(error) \(imageID)")
                default:
                    return
                }
            })
            self.iconView.contentMode = .scaleAspectFill
        }
    }

}
