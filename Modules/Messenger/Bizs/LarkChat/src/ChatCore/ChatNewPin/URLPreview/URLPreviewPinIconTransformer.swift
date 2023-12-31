//
//  URLPreviewPinIconTransformer.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/1.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkOpenChat
import ByteWebImage
import RustPB
import LarkModel
import TangramService
import LarkRichTextCore
import LKCommonsLogging
import LarkDocsIcon

struct URLPreviewPinIconTransformer {
    private static let logger = Logger.log(URLPreviewPinIconTransformer.self, category: "Module.IM.ChatPin")

    static func transformToPinIconType(_ docType: RustPB.Basic_V1_Doc.TypeEnum) -> RustPB.Im_V1_UniversalChatPinIcon.ChatPinIconType {
        switch docType {
        case .unknown:
            return .unknown
        case .doc:
            return .docTypeDoc
        case .sheet:
            return .docTypeSheet
        case .bitable:
            return .docTypeBitable
        case .mindnote:
            return .docTypeMindnote
        case .file:
            return .docTypeFile
        case .slide:
            return .docTypeSlide
        case .wiki:
            return .docTypeWiki
        case .docx:
            return .docTypeDocx
        case .slides:
            return .docTypeSlides
        case .folder, .catalog, .shortcut:
            return .unknown
        @unknown default:
            return .unknown
        }

    }

    private static func transformToDocype(_ pinIconType: RustPB.Im_V1_UniversalChatPinIcon.ChatPinIconType) -> RustPB.Basic_V1_Doc.TypeEnum {
        switch pinIconType {
        case .unknown, .custom:
            return .unknown
        case .docTypeDoc:
            return .doc
        case .docTypeSheet:
            return .sheet
        case .docTypeBitable:
            return .bitable
        case .docTypeMindnote:
            return .mindnote
        case .docTypeFile:
            return .file
        case .docTypeSlide:
            return .slide
        case .docTypeWiki:
            return .wiki
        case .docTypeDocx:
            return .docx
        case .docTypeSlides:
            return .slides
        @unknown default:
            return .unknown
        }
    }

    static func transform(_ icon: RustPB.Im_V1_UniversalChatPinIcon,
                          iconSize: CGSize,
                          defaultIcon: UIImage,
                          placeholder: UIImage?) -> ChatPinIconResource {

        guard case .custom = icon.type else {
            if case .taskList = icon.type {
                return .image(.just(UDIcon.getIconByKey(.tabTodoColorful, size: iconSize)))
            }
            let docType = self.transformToDocype(icon.type)
            if case .unknown = docType {
                return .image(.just(defaultIcon))
            } else {
                return .image(.just(LarkRichTextCoreUtils.docIconColorful(docType: docType, fileName: "")))
            }
        }

        // 彩色 icon
        let colorIcon = icon.colorIcon

        // CCM支持自定义inline icon需求，unicode优先级需要最高
        if !colorIcon.udIcon.unicode.isEmpty,
           let unicodeIcon = DocsIconManager.changeEmojiKeyToImage(key: colorIcon.udIcon.unicode) {
            return .image(.just(unicodeIcon))
        }

        var imageResource: LarkImageResource?
        if !colorIcon.faviconURL.isEmpty {
            imageResource = .default(key: colorIcon.faviconURL)
        } else if !colorIcon.imageSet.origin.key.isEmpty {
            imageResource = .rustImage(key: colorIcon.imageSet.origin.key, fsUnit: colorIcon.imageSet.origin.fsUnit, crypto: colorIcon.imageSet.origin.crypto)
        }

        if let imageResource = imageResource {
            let imageConfig = ChatPinIconResource.ImageConfig(
                tintColor: colorIcon.iconColor.color,
                placeholder: placeholder,
                imageSetPassThrough: nil
            )
            return .resource(resource: imageResource, config: imageConfig)
        }

        if !colorIcon.udIcon.key.isEmpty {
            let udIcon = URLPreviewUDIcon.getIconByKey(colorIcon.udIcon.key, iconColor: colorIcon.udIcon.color.color, size: iconSize) ?? defaultIcon
            return .image(.just(udIcon))
        }

        // 旧版 icon
        let iconColor = icon.useOriginColor ? nil : UIColor.ud.textLinkNormal

        if !icon.udIcon.isEmpty {
            let icon = URLPreviewUDIcon.getIconByKey(icon.udIcon, iconColor: iconColor, size: iconSize) ?? defaultIcon
            return  .image(.just(icon))
        }

        let imageConfig = ChatPinIconResource.ImageConfig(
            tintColor: iconColor,
            placeholder: placeholder,
            imageSetPassThrough: icon.hasImageSetPassThrough ? icon.imageSetPassThrough : nil
        )
        if !icon.imageSetPassThrough.key.isEmpty {
            return .resource(resource: LarkImageResource.default(key: icon.imageSetPassThrough.key), config: imageConfig)
        }
        if !icon.iconKey.isEmpty {
            return .resource(resource: LarkImageResource.default(key: icon.iconKey), config: imageConfig)
        }
        if !icon.iconURL.isEmpty {
            return .resource(resource: LarkImageResource.default(key: icon.iconURL), config: imageConfig)
        }
        return .image(.just(defaultIcon))
    }

    static func convertToChatPinIcon(_ inlineEntity: InlinePreviewEntity) -> RustPB.Im_V1_UniversalChatPinIcon? {
        var chatPinIcon = RustPB.Im_V1_UniversalChatPinIcon()
        var customIcon: Bool = false

        if let icon = inlineEntity.unifiedHeader?.icon {
            customIcon = true
            var colorIcon = Im_V1_UniversalChatPinIcon.ColorIcon()
            if icon.hasIcon {
                colorIcon.imageSet = icon.icon
            }
            if icon.hasIconColor {
                colorIcon.iconColor = icon.iconColor
            }
            if icon.hasUdIcon {
                colorIcon.udIcon = icon.udIcon
            }
            colorIcon.faviconURL = icon.faviconURL
            chatPinIcon.colorIcon = colorIcon
            chatPinIcon.useOriginColor = true
        }
        if let key = inlineEntity.iconKey, !key.isEmpty {
            customIcon = true
            chatPinIcon.iconKey = key
        }
        if let key = inlineEntity.iconUrl, !key.isEmpty {
            customIcon = true
            chatPinIcon.iconURL = key
        }
        if let key = inlineEntity.udIcon?.key, !key.isEmpty {
            customIcon = true
            chatPinIcon.udIcon = key
        }
        if let imageSetPassThrough = inlineEntity.imageSetPassThrough {
            chatPinIcon.imageSetPassThrough = imageSetPassThrough
        }

        if customIcon {
            chatPinIcon.type = .custom
            return chatPinIcon
        } else {
            return nil
        }
    }

    static func renderIcon(_ iconView: UIImageView,
                           iconResource: ChatPinIconResource,
                           iconCornerRadius: CGFloat,
                           disposeBag: DisposeBag?,
                           successHandler: (() -> Void)? = nil,
                           errorHandler: ((Error) -> Void)? = nil) {
        iconView.image = nil
        iconView.bt.setLarkImage(with: .default(key: ""))
        iconView.layer.cornerRadius = iconCornerRadius

        switch iconResource {
        case .image(let imageOb):
            let disposable = imageOb
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak iconView] image in
                    iconView?.image = image
                    successHandler?()
                })
            if let disposeBag = disposeBag {
                disposable.disposed(by: disposeBag)
            }
        case .resource(resource: let resource, config: let config):
            var passThrough: ImagePassThrough?
            if let pbModel = config?.imageSetPassThrough {
                passThrough = ImagePassThrough.transform(passthrough: pbModel)
            }
            iconView.bt.setLarkImage(with: resource,
                                     placeholder: config?.placeholder,
                                     passThrough: passThrough,
                                     completion: { [weak iconView] res in
                guard let iconView = iconView else { return }
                switch res {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    if let tintColor = config?.tintColor {
                        iconView.image = image.ud.withTintColor(tintColor)
                    } else {
                        iconView.image = image
                    }
                    successHandler?()
                case .failure(let error):
                    Self.logger.error("chatPinCardTrace set icon image fail", error: error)
                    errorHandler?(error)
                }
            })
        @unknown default:
            break
        }
    }
}
