//
//  ShareImageAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/22.
//

import LarkMessengerInterface
import LarkSetting
import LKCommonsLogging

final class ShareImageAlertConfig: ForwardAlertConfig {
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    private static let logger = Logger.log(ShareImageAlertConfig.self, category: "ShareImageAlertConfig")
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? ShareImageAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let imageContent = self.content as? ShareImageAlertContent else { return nil }
        if !forwardDialogContentFG {
            Self.logger.info("getContentView old \(imageContent.type) \(forwardDialogContentFG)")
            if imageContent.type == .forward {
                return ShareImageConfirmFooter(image: imageContent.image)
            }
            return nil
        }

        var view: UIView?
        Self.logger.info("getContentView new \(imageContent.type) \(forwardDialogContentFG)")
        switch imageContent.type {
        case .forward:
            /// forward类型需要添加footer
            view = ShareImageConfirmFooter(image: imageContent.image)
        case .forwardPreview:
            view = ShareNewImageConfirmFooter(image: imageContent.image)
        case .normal:
            //无footer
            return nil
        @unknown default:
            assert(false, "new value")
            return nil
        }
        return view
    }
}
