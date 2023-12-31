//
//  UniversalCardLynxIcon.swift
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
import UniverseDesignColor
import UniversalCardInterface


private final class UniversalCardIconView: ByteImageView {
    public override var clipsToBounds: Bool {
        didSet {
            if clipsToBounds == false {
                clipsToBounds = true
            }
        }
    }
}

public final class UniversalCardLynxIconView: LynxUIView {

    public static let name: String = "card-ud-icon"

    static let logger = Logger.log(UniversalCardLynxIconView.self, category: "UniversalCardLynxIconView")

    var cardContext: UniversalCardContext?
    private var props: [AnyHashable: Any]?

    lazy private var iconView: ByteImageView = {
        var iconView: UniversalCardIconView = UniversalCardIconView()
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
    public override func createView() -> UIImageView? { self.iconView }

    @objc func setContext(context: Any?, requestReset _: Bool) {
        guard let cardContext = getCardContext() else {
            Self.logger.error("UniversalCardLynxIconView get cardContext fail"); return
        }
        self.cardContext = cardContext
        if (iconView.image == nil) { setFallbackImage() { self.iconView.image = nil } }
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
           let image = Self.getIconByKey(token, iconColor: color) {
            iconView.image = image
            iconView.contentMode = .scaleAspectFit
        } else {
            self.props = props
            setFallbackImage() { self.iconView.image = nil }
        }
    }

    public static func getIconByKey(_ key: String, renderingMode: UIImage.RenderingMode = .automatic, iconColor: UIColor? = nil, size: CGSize? = nil) -> UIImage? {
        switch key {
        case "wiki-bitable_colorful":
            return UDIcon.getIconByKey(.fileBitableColorful, renderingMode: renderingMode, iconColor: iconColor, size: size)
        default:
            return UDIcon.getIconByString(key, renderingMode: renderingMode, iconColor: iconColor, size: size)
        }
    }

    func setFallbackImage(onError: (() -> Void)){
        guard let cardContext = cardContext,
              let props = props,
              let imageID = props["imageID"] as? String else {
            onError()
            return
        }

        guard let imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty = cardContext.sourceData?.cardContent.attachment.images[imageID] else {
            Self.logger.error("cardContent no imageProperty \(imageID) ")
            onError()
            return
        }
        let imageToken = ImageItemSet.transform(imageProperty:imageProperty).generatePostMessageKey(forceOrigin: false)
        DispatchQueue.main.async {
            self.iconView.bt.setLarkImage(.default(key: imageToken)) { result in
                switch result {
                case .failure(let error):
                    Self.logger.error(" iconView set image fail,error:\(error) \(imageID)")
                default:
                    return
                }
            }
            self.iconView.contentMode = .scaleAspectFill
        }
    }

}
