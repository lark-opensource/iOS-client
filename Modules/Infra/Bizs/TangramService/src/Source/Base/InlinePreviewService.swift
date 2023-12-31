//
//  InlinePreviewService.swift
//  TangramService
//
//  Created by 袁平 on 2021/6/1.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkModel
import ByteWebImage
import LarkContainer
import UniverseDesignIcon

public protocol InlinePreviewServiceAbility: AnyObject {
    // 刷新inline
    func update(push: URLPreviewPush)
}

/// https://bytedance.feishu.cn/docs/doccnv6m7dGxUCSOwfKcLPjzxib
public final class InlinePreviewService {
    public typealias PushHandler = (URLPreviewPush) -> Void

    public weak var ability: InlinePreviewServiceAbility?
    private var disposeBag = DisposeBag()

    public init(ability: InlinePreviewServiceAbility? = nil) {
        self.ability = ability
    }

    /// 由调用方决定是否接入Push更新
    public func subscribePush(ability: InlinePreviewServiceAbility?) {
        self.ability = ability
        disposeBag = DisposeBag()
        try? Container.shared.getCurrentUserResolver(compatibleMode: URLPreview.userScopeCompatibleMode).userPushCenter //Global
            .observable(for: URLPreviewPush.self)
            .subscribe(onNext: { [weak self] push in
                self?.ability?.update(push: push)
            }).disposed(by: disposeBag)
    }

    public func hasIcon(entity: InlinePreviewEntity) -> Bool {
//        return entity.iconKey != nil || entity.iconUrl != nil || entity.iconImage != nil
        // inline默认需要有icon
        return true
    }

    /// https://bytedance.feishu.cn/docx/MF7Jded5Mo1FDmxGtCOcjC07n1d#ORhQdIUpEoCGQkxx4T6cqrMon7f
    /// 优先级：udIcon > iconKey > iconUrl > iconImage
    public func iconView(entity: InlinePreviewEntity,
                         iconColor: UIColor?,
                         completion: ((UIImageView?, UIImage?, Error?) -> Void)? = nil) -> UIImageView {
        let imageView = UIImageView()

        // 彩色icon不使用iconColor染色
        if entity.useColorIcon, let header = entity.unifiedHeader, header.hasIcon {
            let colorIcon = header.icon
            if let image = colorIcon.udIcon.unicodeImage {
                imageView.setImage(image, tintColor: nil)
                completion?(imageView, image, nil)
                return imageView
            } else if let image = colorIcon.udIcon.udImage {
                imageView.setImage(image, tintColor: nil)
                completion?(imageView, image, nil)
                return imageView
            }
            let key = !colorIcon.icon.key.isEmpty ? colorIcon.icon.key : colorIcon.faviconURL
            if !key.isEmpty {
                // placeholder也需要染色，通过setLarkImage设置的placeholder无法染色
                imageView.setImage(BundleResources.TangramService.inline_icon_placeholder, tintColor: iconColor)
                let customIconColor = colorIcon.iconColor.color
                imageView.bt.setLarkImage(.default(key: key), completion: { [weak imageView] res in
                    switch res {
                    case .success(let imageResult):
                        if let image = imageResult.image { imageView?.setImage(image, tintColor: customIconColor) }
                        completion?(imageView, imageResult.image, nil)
                    case .failure(let error):
                        completion?(imageView, nil, error)
                    }
                })
                return imageView
            }
        }

        if let image = entity.udIcon?.unicodeImage {
            // unicode不染色
            imageView.setImage(image, tintColor: nil)
            completion?(imageView, image, nil)
            return imageView
        } else if let image = entity.udIcon?.udImage {
            imageView.setImage(image, tintColor: iconColor)
            completion?(imageView, image, nil)
            return imageView
        }
        let key = entity.iconKey ?? entity.iconUrl
        if let key = key, !key.isEmpty {
            // placeholder也需要染色，通过setLarkImage设置的placeholder无法染色
            imageView.setImage(BundleResources.TangramService.inline_icon_placeholder, tintColor: iconColor)
            imageView.bt.setLarkImage(.default(key: key), completion: { [weak imageView] res in
                switch res {
                case .success(let imageResult):
                    if let image = imageResult.image { imageView?.setImage(image, tintColor: iconColor) }
                    completion?(imageView, imageResult.image, nil)
                case .failure(let error):
                    completion?(imageView, nil, error)
                }
            })
            return imageView
        }

        // inline默认需要有icon
        let image = entity.iconImage ?? BundleResources.TangramService.inline_icon_placeholder
        imageView.setImage(image, tintColor: iconColor)
        completion?(imageView, image, nil)
        return imageView
    }

    public func hasTag(entity: InlinePreviewEntity) -> Bool {
        let tag = entity.tag ?? ""
        return !tag.isEmpty
    }

    /// - Parameters:
    ///     - text: tag text
    ///     - titleFont: tagFont = round(titleFont * 0.7)，即0.7倍标题字号四舍五入取整，最小为10px
    ///     - type: tag type；目前inline仅两种类型
    public func tagView(text: String, titleFont: UIFont, type: TagType) -> UILabel {
        let tagFont = Self.tagFont(titleFont: titleFont)
        return tagView(text: text, tagFont: tagFont, type: type)
    }

    public func tagView(text: String, tagFont: UIFont, type: TagType) -> UILabel {
        let tag = PaddingUILabel()
        tag.backgroundColor = type.backgroundColor
        tag.textColor = type.textColor
        tag.text = text
        tag.font = tagFont
        tag.layer.cornerRadius = 2
        tag.clipsToBounds = true
        tag.padding = PaddingUILabel.defaultPadding
        return tag
    }

    public func tagViewSize(text: String, titleFont: UIFont) -> CGSize {
        let tagFont = Self.tagFont(titleFont: titleFont)
        return tagViewSize(text: text, tagFont: tagFont)
    }

    public func tagViewSize(text: String, tagFont: UIFont) -> CGSize {
        return PaddingUILabel.sizeToFit(text: text, font: tagFont)
    }

    public static func tagFont(titleFont: UIFont) -> UIFont {
        let tagFontSize = max(10, round(titleFont.pointSize * 0.7))
        return UIFont.systemFont(ofSize: tagFontSize)
    }
}
