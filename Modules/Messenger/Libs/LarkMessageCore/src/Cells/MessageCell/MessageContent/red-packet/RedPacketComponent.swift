//
//  RedPacketComponent.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/10.
//

import UIKit
import LarkCore
import Foundation
import EEFlexiable
import ByteWebImage
import AsyncComponent
import LarkModel
import LarkSDKInterface

public final class RedPacketComponent<C: AsyncComponent.Context>: ASComponent<RedPacketComponent.Props, EmptyState, RedPacketView, C> {
    public final class Props: ASComponentProps {
        var mainTip: String = ""
        var statusText: String = ""
        var isShowShadow: Bool = false
        // 红包类型描述
        var typeDescription = ""
        // 企业标识图
        var companyImagePassThrough = ImagePassThrough()
        // 封面图
        var coverImagePassThrough = ImagePassThrough()
        // 是否是自定义封面
        var isCustomCover: Bool = false
        var isExclusive: Bool = false
        var previewChatters: [Chatter]?
        var totalNum: Int32?
        // 企业定制描述
        var hongbaoCoverDisplayName: HongbaoCoverDisplayName?
        var tapAction: (() -> Void)?
        var shrinkScale: CGFloat = 1
        var isB2C: Bool = false
        var b2cCoverDisplayName: String?
        var chatComponentTheme: ChatComponentTheme = ChatComponentTheme.getChatDefault()
    }

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> RedPacketView {
        let view = RedPacketView(frame: rect)
        return view
    }

    public override func update(view: RedPacketView) {
        super.update(view: view)
        /// 红包有展示的名字
        if let displayName = props.hongbaoCoverDisplayName, displayName.displayName.isEmpty == false {
            /// 如果企业红包名字不存在 使用displayName.displayName
            view.descriptionLabel.text = props.b2cCoverDisplayName ?? displayName.displayName
            view.descriptionLabel.isHidden = false
            view.descriptionBackgroundView.isHidden = false
            var pass = ImagePassThrough()
            pass.key = displayName.backgroundImg.key
            pass.fsUnit = displayName.backgroundImg.fsUnit
            let placeholder = self.processImage(BundleResources.hongbao_message_background,
                                                scale: 1,
                                                bgBorderWidth: CGFloat(10))
            view.descriptionBackgroundView.bt.setLarkImage(with: .default(key: displayName.backgroundImg.key ?? ""),
                                                           placeholder: placeholder,
                                                           passThrough: pass,
                                                           options: [.disableAutoSetImage],
                                                           completion: { [weak self] result in
                guard let icon = try? result.get().image, !displayName.backgroundImg.key.isEmpty else { return }
                let scale = RedPacketView.Config.descriptionBackgroundViewHeight / icon.size.height
                view.descriptionBackgroundView.image = self?.processImage(icon,
                                                                          scale: scale,
                                                                          bgBorderWidth: CGFloat(displayName.bgBorderWidth) * scale)
           })
        } else {
            view.descriptionBackgroundView.isHidden = true
            view.descriptionLabel.isHidden = true
        }
        view.statusLabel.isHidden = props.statusText.isEmpty
        if let previewChatters = props.previewChatters,
            let totalNum = props.totalNum {
            view.mainLabel.numberOfLines = 1
            view.exclusiveAvatarListView.isHidden = false
            view.exclusiveTipLabel.isHidden = false
            view.updateExclusiveAvatarList(previewChatters)
            if totalNum == 1 {
                let name = previewChatters.first?.name ?? (previewChatters.first?.localizedName ?? "")
                view.exclusiveTipLabel.text = BundleI18n.LarkMessageCore.Lark_DesignatedRedPacket_DesignatedToName_Text(name)
            } else {
                view.exclusiveTipLabel.text = BundleI18n.LarkMessageCore.Lark_DesignatedRedPacket_DesignatedToNumMembers_Text(totalNum)
            }
        } else {
            view.mainLabel.numberOfLines = 2
            view.exclusiveAvatarListView.isHidden = true
            view.exclusiveTipLabel.isHidden = true
        }
        // 如果子视图全部隐藏则让centerStack约束消失
        if view.centerStack.arrangedSubviews.allSatisfy { $0.isHidden } {
            view.centerStack.snp.remakeConstraints { make in
                make.top.equalTo(view.mainLabel.snp.bottom)
                make.height.equalTo(0)
            }
        } else {
            view.centerStack.snp.remakeConstraints { make in
                make.top.equalTo(view.mainLabel.snp.bottom).offset(8)
                make.left.right.equalToSuperview().inset(view.centerStackHorizontalMargin)
            }
        }
        view.typeDescription.text = props.typeDescription
        view.mainLabel.text = props.mainTip
        view.statusLabel.text = props.statusText
        if props.isCustomCover {
            view.topShadow.isHidden = false
            if props.isExclusive {
                view.topShadowHeightConstraint?.update(offset: view.topViewHeight)
            } else {
                view.topShadowHeightConstraint?.update(offset: view.defaultTopShadowHeight)
            }
            view.topView.bt.setLarkImage(with: .default(key: props.coverImagePassThrough.key ?? ""),
                                         placeholder: BundleResources.hongbao_bg_top,
                                         passThrough: props.coverImagePassThrough)
        } else {
            view.topShadow.isHidden = true
            view.topView.bt.setLarkImage(with: .default(key: ""),
                                         placeholder: BundleResources.hongbao_bg_top)
        }
        if props.isCustomCover || props.isExclusive {
            view.mainLabel.snp.updateConstraints { $0.top.equalTo(24) }
        } else {
            view.mainLabel.snp.updateConstraints { $0.top.equalTo(36) }
        }
        if props.companyImagePassThrough.key?.isEmpty == false {
            view.bussinessIcon.bt.setLarkImage(with: .default(key: props.companyImagePassThrough.key ?? ""), passThrough: props.companyImagePassThrough)
            let iconWidth: CGFloat = 15
            view.bussinessIcon.snp.remakeConstraints { make in
                make.bottom.equalTo(-5)
                make.width.height.equalTo(iconWidth).priority(.required)
                make.right.equalTo(-10)
                make.left.greaterThanOrEqualTo(view.typeDescription.snp.right).offset(10)
            }
            view.setBussinessIconStyle(props.isB2C ? .B2C(iconWidth / 2.0) : .normal)
        } else {
            view.bussinessIcon.snp.remakeConstraints { make in
                make.width.height.equalTo(0)
            }
        }

        view.tapAction = props.tapAction
        view.themeBackgroundView.isHidden = !(props.isShowShadow && props.chatComponentTheme.isDefaultScene == false)
        if props.isShowShadow {
            view.topView.autoPlayAnimatedImage = false
            view.topView.stopAnimating()
            view.containerView.alpha = 0.5
            view.openImageView.image = BundleResources.hongbao_close_icon
        } else {
            view.topView.autoPlayAnimatedImage = true
            view.topView.startAnimating()
            view.openImageView.image = BundleResources.hongbao_open_icon
            view.containerView.alpha = 1
        }
    }

    private func processImage(_ image: UIImage,
                              scale: CGFloat,
                              bgBorderWidth: CGFloat) -> UIImage? {
        // 缩放
        let scaledIcon = image.ud.scaled(by: scale)
        // 控制可拉伸范围
        let inset = UIEdgeInsets(top: 0, left: bgBorderWidth, bottom: 0, right: bgBorderWidth)
        let resizableImage = scaledIcon.resizableImage(withCapInsets: inset,
                                                       resizingMode: .stretch)
        return resizableImage
    }
}
