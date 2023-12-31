//
//  OpenPluginModal.swift
//  OPPlugin
//
//  Created by yi on 2021/4/6.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import LKCommonsLogging
import UniverseDesignDialog
import LarkSetting
import LarkContainer
import TTMicroApp

final class OpenPluginModal: OpenBasePlugin {
    
    @RealTimeFeatureGatingProvider(key: "openplatform.api.showmodal_refactor_disabled") private var refactorDisabled: Bool
    
    @RealTimeFeatureGatingProvider(key: "openplatform.show.modal.top.most.fix") private var topMostOpt: Bool

    func showModal(params: OpenAPIShowModalParams, context: OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowModalResult>) -> Void) {
        
        let uniqueID = gadgetContext.uniqueID

        let modalController = Self.presentBaseController(appType: uniqueID.appType, inController: gadgetContext.controller)
        context.apiTrace.info("bdp_showModalWithModel")
        
        let config = UDDialogUIConfig()
        if !refactorDisabled {
            config.titleNumberOfLines = 2
        }
        let alert = UDDialog(config: config)

        // UDDialog设置空字符串也会创建titleLabel会留空白,因此这边进行判断处理,效果和安卓对齐;
        if !params.title.isEmpty {
            alert.setTitle(text: params.title)
        }

        // 同title设置
        if !params.content.isEmpty {
            let contentView = self.configContentView(text: params.content)
            alert.setContent(view: contentView)
        }

        if params.showCancel {
            alert.addSecondaryButton(text: params.cancelText, numberOfLines: 0, dismissCompletion: {
                callback(.success(data: OpenAPIShowModalResult(confirm: false, cancel: true)))
            })
        }

        alert.addPrimaryButton(text: params.confirmText, numberOfLines: 0, dismissCompletion: {
            callback(.success(data: OpenAPIShowModalResult(confirm: true, cancel: false)))
        })

        var vc = topMostOpt ? nil : modalController
        if vc == nil {
            vc = OPNavigatorHelper.topMostAppController(window: modalController?.view.window)
        }
        alert.overrideSupportedInterfaceOrientations = UDRotation.supportedInterfaceOrientations(from: vc)
        vc?.present(alert, animated: true, completion: nil)
    }

    /**
     由于showModal接入了UDDialog, 这边需要对超长文本进行处理, 同时需要使用**'UniverseDesignDialog', '0.4.13'**及以上.
     */
    private func configContentView(text: String,
                                   color: UIColor = UIColor.ud.textTitle,
                                   font: UIFont = UIFont.systemFont(ofSize: 16),
                                   alignment: NSTextAlignment = .center,
                                   lineSpacing: CGFloat = 4,
                                   numberOfLines: Int = 0) -> UIView {
        let dialogWidth = UDDialog.Layout.dialogWidth
        // UDDialog中horizontalPadding为20
        let horizontalPadding:CGFloat = 20;
        let paragraphStyle = NSMutableParagraphStyle()
        let textWidth = text.size(withAttributes: [NSAttributedString.Key.font: font]).width
        let textViewWidth = dialogWidth - 2 * horizontalPadding
        paragraphStyle.lineSpacing = textWidth > textViewWidth ? lineSpacing : 0
        paragraphStyle.alignment = alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: color
        ]

        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .clear
        textView.bounces = false
        textView.attributedText = NSAttributedString(string: text, attributes: attributes)
        let contentSize = textView.sizeThatFits(CGSize(width: textViewWidth, height: CGFloat.infinity))
        let contentView = UIView()
        contentView.addSubview(textView)

        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            //这边约束等级要小于UDDialog中对设置contentView的约束等级;
            make.width.equalTo(contentSize.width).priority(.low)
            make.height.equalTo(ceil(contentSize.height)).priority(.low)
        }

        return contentView
    }


    class func presentBaseController(appType: OPAppType, inController: UIViewController?) -> UIViewController? {
        var controller: UIViewController?
        switch appType {
        case .webApp:
            controller = nil
            break
        case .widget, .gadget:
            controller = BDPAppController.currentAppPageController(inController, fixForPopover: false)
            break
        default:
            controller = BDPAppController.currentAppPageController(inController, fixForPopover: false)
            break
        }
        return controller
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandlerGadget(for: "showModal", pluginType: Self.self, paramsType: OpenAPIShowModalParams.self, resultType: OpenAPIShowModalResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.showModal(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }

    }
}
