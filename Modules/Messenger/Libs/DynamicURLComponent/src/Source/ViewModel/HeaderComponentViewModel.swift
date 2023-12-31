//
//  HeaderComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/19.
//

import UIKit
import Foundation
import RustPB
import LarkEMM
import LarkCore
import ByteWebImage
import TangramService
import LKCommonsLogging
import TangramComponent
import TangramUIComponent
import UniverseDesignToast
import LarkSensitivityControl
import UniverseDesignActionPanel

public final class HeaderComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(HeaderComponentViewModel.self, category: "DynamicURLComponent.HeaderComponentViewModel")

    private lazy var _component: TangramHeaderComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let header = property?.header ?? .init()
        let props = buildComponentProps(stateID: stateID, property: header, style: style)
        _component = TangramHeaderComponent<EmptyContext>(props: props, style: renderStyle)
    }

    public override func buildComponentStyle(style: Basic_V1_URLPreviewComponent.Style) -> RenderComponentStyle {
        let renderStyle = super.buildComponentStyle(style: style)
        renderStyle.clipsToBounds = false
        return renderStyle
    }

    private func buildComponentProps(stateID: String,
                                     property: Basic_V1_URLPreviewComponent.PreviewHeaderProperty,
                                     style: Basic_V1_URLPreviewComponent.Style) -> TangramHeaderComponentProps {
        let props = TangramHeaderComponentProps()
        // iconColor仅作用于IconKey & Favicon，UDIcon自带color
        let iconColor = property.iconColor.color
        let placeholder = Resources.inline_icon_placeholder.ud.withTintColor(UIColor.ud.textLinkNormal)
        // 优先级：UDIcon > IconKey > Favicon
        if property.hasUdIcon, let image = property.udIcon.unicodeImage ?? property.udIcon.udImage {
            props.iconProvider.update { imageView in
                imageView.image = image
            }
        } else if property.hasIconKey {
            props.iconProvider.update { [weak self] imageView in
                let item = ImageItemSet.transform(imageSet: property.iconKey)
                let key = item.generateImageMessageKey(forceOrigin: false)
                let isOrigin = item.isOriginKey(key: key)
                imageView.bt.setLarkImage(
                    with: .default(key: key),
                    placeholder: Resources.inline_icon_placeholder,
                    options: [.onlyLoadFirstFrame],
                    trackStart: {
                        return TrackInfo(scene: .Chat, isOrigin: isOrigin, fromType: .urlPreview)
                    },
                    completion: { [weak imageView, weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let imageRes):
                            if let iconColor = iconColor, let image = imageRes.image {
                                imageView?.setImage(image, tintColor: iconColor)
                            }
                        case .failure:
                            Self.logger.error("setImage error: \(self.entity.previewID) -> \(key)")
                        }
                    }
                )
            }
        } else if property.hasFaviconURL, !property.faviconURL.isEmpty {
            props.iconProvider.update { [weak self] imageView in
                imageView.bt.setLarkImage(
                    with: .default(key: property.faviconURL),
                    placeholder: Resources.inline_icon_placeholder,
                    options: [.onlyLoadFirstFrame],
                    trackStart: {
                        return TrackInfo(scene: .Chat, fromType: .urlPreview)
                    },
                    completion: { [weak imageView, weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let imageRes):
                            if let iconColor = iconColor, let image = imageRes.image {
                                imageView?.setImage(image, tintColor: iconColor)
                            }
                        case .failure:
                            Self.logger.error("setImage error: \(self.entity.previewID)")
                        }
                    }
                )
            }
        } else { // 没有给图片时，给个兜底图
            props.iconProvider.update { imageView in
                imageView.image = placeholder
            }
        }
        props.title = property.title
        if let textColor = style.tcTextColor {
            props.titleColor = textColor
        }
        props.titleNumberOfLines = Int(property.numberOfLines)
        if property.hasLarkTag, let tag = property.larkTag.larkTag {
            props.headerTag = TangramHeaderConfig.HeaderTag(tagType: tag)
        } else if property.hasHeaderTag, !property.headerTag.isEmpty {
            props.headerTag = TangramHeaderConfig.HeaderTag(tag: property.headerTag)
            if let backgroundColor = property.tagColor.color {
                props.headerTag?.backgroundColor = backgroundColor
            }
            if let textColor = property.tagTextColor.color {
                props.headerTag?.textColor = textColor
            }
            if let font = style.tcFont {
                props.headerTag?.font = font
            }
        }
        props.theme = property.theme.headerTheme
        if property.hasChildComponentID,
           let state = self.entity.previewBody?.states[stateID],
           let template = dependency.templateService?.getTemplate(id: state.templateID) ?? self.entity.localTemplates[state.templateID] {
            let childVM = ComponentCardRegistry.createPreview(entity: self.entity,
                                                              stateID: stateID,
                                                              state: state,
                                                              componentID: property.childComponentID,
                                                              template: template,
                                                              ability: self.ability,
                                                              dependency: self.dependency)
            if let timerComponent = childVM?.component as? TimerViewComponent<EmptyContext>,
               let childComponent = childVM?.component as? VirtualNodeAbility {
                // Timer组件现在是定宽，暂不支持根据内容自适应宽度，因此在Header里面，文字右对齐，
                // 用作单独组件时，文字默认左对齐
                timerComponent.props.textAlignment = .right
                let customViewSize = childComponent._sizeToFit(UIScreen.main.bounds.size)
                props.customViewSize = customViewSize
                props.customView.update {
                    childComponent.createView(.init(origin: .zero, size: customViewSize))
                }
            }
        }
        if (dependency.supportClosePreview && property.isNeedClose) || property.isNeedCopyLink {
            props.showMenu = true
            props.menuTapHandler.update(new: { [weak self] button in
                self?.menuTapHandler(button: button, property: property)
            })
        }
        return props
    }

    private func menuTapHandler(button: UIButton, property: Basic_V1_URLPreviewComponent.PreviewHeaderProperty) {
        guard let targetVC = dependency.targetVC else { return }
        let source = UDActionSheetSource(sourceView: button,
                                         sourceRect: button.bounds,
                                         arrowDirection: .up)
        let actionsheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
        if property.isNeedCopyLink {
            actionsheet.addItem(.init(
                title: BundleI18n.DynamicURLComponent.Lark_Chat_CopyLink,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self,
                          let view = self.dependency.targetVC?.view else { return }
                    var copyURL = self.dependency.getOriginURL(previewID: self.entity.previewID)
                    copyURL = copyURL.isEmpty ? self.entity.url.url : copyURL
                    let config = PasteboardConfig(token: Token("LARK-PSDA-url_preview_header_menu_cpoy"))
                    do {
                        try SCPasteboard.generalUnsafe(config).string = copyURL
                        UDToast.showSuccess(with: BundleI18n.DynamicURLComponent.Lark_Legacy_JssdkCopySuccess, on: view)
                        Self.logger.info("[URLPreview] header copy url succeeded -> \(copyURL.count)")
                    } catch {
                        // 复制失败兜底逻辑
                        UDToast.showFailure(with: BundleI18n.DynamicURLComponent.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: view)
                        Self.logger.warn("[URLPreview] header copy url failed -> \(copyURL.count)")
                    }
                })
            )
        }
        if dependency.supportClosePreview, property.isNeedClose {
            actionsheet.addItem(.init(
                title: BundleI18n.DynamicURLComponent.Lark_Legacy_DeleteUrlPreview,
                titleColor: UIColor.ud.functionDangerContentDefault,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.ability.closePreview()
                    Self.logger.info("[URLPreview] user close preview -> \(self.entity.previewID)")
                })
            )
        }
        actionsheet.setCancelItem(text: BundleI18n.DynamicURLComponent.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(actionsheet, from: targetVC)
    }
}

private extension Basic_V1_URLPreviewComponent.Theme {
    var headerTheme: TangramHeaderConfig.Theme {
        switch self {
        case .light: return .light
        case .dark: return .dark
        @unknown default: return .light
        }
    }
}
