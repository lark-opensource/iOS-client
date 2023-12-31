//
//  DocPreviewComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/19.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkModel
import LarkCore
import SwiftyJSON
import RxSwift
import LarkContainer
import LarkMessengerInterface
import EENavigator
import LKCommonsLogging
import RustPB
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon

/// component 最小依赖
public protocol DocPreviewComponentContext: ComponentContext { }

/// Action
public protocol DocPreviewActionDelegate: AnyObject {
    func docPreviewDidTappedDetail()
    func docPreviewWillChangePermission(sourceView: UIView?)
    var thumbnailDecryptionAvailable: Bool { get }
    func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage>
}

public enum BottomHintViewType {
    case none
    case askOwnerTips
    case externalTips
    case internalTips
    case closeCrossTenantTips ///该文档关闭了对外分享功能
    case wikiSettingCloseCrossTenant ///知识空间关闭了对外分享功能
}

public enum SinglePageState: Int {
    case normal = 0
    case container
    case singlePage
}

/// Props
final public class DocPreviewComponentProps: ASComponentProps {
    public var askOwnerDependency: AskOwnerDependency?
    public var docPermissionDependency: DocPermissionDependency?
    public weak var delegate: DocPreviewActionDelegate?
    public weak var fromVc: UIViewController?
    public var contentPreferMaxWidth: CGFloat = 0
    public var permissionText: String?
    public var permissionDesc: String?
    public var singlePageDesc: String?
    public var shareText: String?
    public var shareStatusText: String = ""

    public var isFromMe: Bool = false
    public var canSelectPermission: Bool = false
    public var bottomHintViewType: BottomHintViewType = .none
    public var docAbstract: String?
    public var contentPadding: CGFloat = 0
    public var shareStatus: Int64 = 0
    public var thumbnailDetail: String?
    public var isChatWithMe: Bool = false
    public var docType: RustPB.Basic_V1_Doc.TypeEnum = .unknown
    public var docKey: String = ""
    public var docOwner: String?
    public var docOwnerID: Int64?
    public var chatID: String = ""
    public var chatName: String = ""
    public var chatIcon: String = ""
    public var description: String = ""
    public var isCrossTenanet: Bool = false
    public var roleType: Int = 0
    public var font: UIFont = UIFont.ud.body2
    public var receiverPerm: Int32 = 0
    public var userPerm: Int32 = 0
    public var singlePageState: SinglePageState = .normal
}

public final class DocPreviewComponent<C: DocPreviewComponentContext>: ASComponent<DocPreviewComponentProps, EmptyState, TappedView, C> {

    private enum Layout {
        static var contentHorizontalMargin: CGFloat { 12 }
    }

    private let logger = Logger.log(DocPreviewComponent.self, category: "DocPreviewComponent")
    private let innerMargin: CSSValue = CSSValue(cgfloat: 0)
    private let leftLineWidth: CSSValue = CSSValue(cgfloat: 3)

    public override init(props: DocPreviewComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        super.init(props: props, style: style, context: context)
        updateProps(props: props)
        setSubComponents([imageContainer, seperator, bottomContainer, descInfo])
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.initEvent(needLongPress: false)
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.backgroundColor = UDMessageColorTheme.imMessageCardBGBodyEmbed
        view.layer.cornerRadius = 6
        view.clipsToBounds = true
        view.onTapped = { [weak self] _ in
            self?.props.delegate?.docPreviewDidTappedDetail()
        }
    }

    // 缩略图容器
    private lazy var imageContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.marginTop = innerMargin
        style.marginBottom = innerMargin
        style.backgroundColor = UDMessageColorTheme.imMessageCardBGBodyEmbed.alwaysLight
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    // 缩略图背景 mask 容器
    private lazy var imageMaskContainer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UDColor.fillImgMask
        style.flexDirection = .column
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    // Doc 图片
    private lazy var image: DocThumbnailComponent<C> = {
        let props = DocThumbnailComponent<C>.Props()
        let style = ASComponentStyle()
        style.height = 140
        style.marginTop = CSSValue(cgfloat: 12)
        style.marginLeft = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginRight = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginBottom = CSSValue(cgfloat: 4)
        return DocThumbnailComponent(props: props, style: style)
    }()

    // 缩略图下分隔线
    private lazy var seperator: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UDColor.lineDividerDefault
        style.height = 1
        style.marginLeft = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginRight = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginBottom = CSSValue(cgfloat: 10)
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    // 底部容器
    private lazy var bottomContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .flexStart
        style.alignItems = .center
        style.marginLeft = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginRight = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginBottom = CSSValue(cgfloat: 12)
        icon.style.display = .none
        return ASLayoutComponent(style: style, context: context, [icon, desc, permissionButton])
    }()

    private lazy var icon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let image: UIImage = BundleResources.icon_chat_warning
        props.setImage = { $0.set(image: image) }

        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: 16)
        style.height = CSSValue(cgfloat: 16)
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    // 描述
    private lazy var desc: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 0
        props.textColor = UIColor.ud.N900
        props.font = self.props.font
        props.lineBreakMode = .byWordWrapping
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = CSSValue(cgfloat: 0)
        style.flexShrink = 1
        return UILabelComponent<C>(props: props, style: style)
    }()

    // 仅当前页面/当前页面及子页面
    private lazy var singlePageDesc: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 0
        props.textColor = UIColor.ud.N900
        props.font = self.props.font
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = CSSValue(cgfloat: 0)
        style.flexShrink = 1
        return UILabelComponent<C>(props: props, style: style)
    }()

    // 接收消息最先下边的info展示
    private lazy var descInfo: DocsPreviewLeftInfoViewComponent<C> = {
        let props = DocsPreviewLeftInfoViewComponentProps()
        props.icon = BundleResources.icon_chat_warning
        props.iconAndLabelSpacing = 5
        props.font = self.props.font
        let style = ASComponentStyle()
        style.backgroundColor = UDColor.fillHover
        style.flexShrink = 0
        style.marginLeft = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginRight = CSSValue(cgfloat: Layout.contentHorizontalMargin)
        style.marginBottom = CSSValue(cgfloat: 12)
        return DocsPreviewLeftInfoViewComponent(props: props, style: style)
    }()

    // 修改权限Button
    private lazy var permissionButton: RightButtonComponent<C> = {
        let props = RightButtonComponentProps()
        let icon = UDIcon.getIconByKey(.avSetDownOutlined, renderingMode: .alwaysOriginal, size: .init(width: 10, height: 10))
        props.icon = icon.ud.withTintColor(UIColor.ud.primaryContentDefault)
        props.iconSize = .init(width: 10, height: 10)
        props.iconAndLabelSpacing = 2
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexShrink = 0
        return RightButtonComponent(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: DocPreviewComponentProps,
                                          _ new: DocPreviewComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }

    private func updateProps(props: DocPreviewComponentProps) {
        style.maxWidth = CSSValue(cgfloat: props.contentPreferMaxWidth - 2 * props.contentPadding)
        imageContainer.setSubComponents([imageMaskContainer])
        imageMaskContainer.setSubComponents([image])
        // fix：SUITE-39741，权限按钮超出气泡
        bottomContainer.style.maxWidth = CSSValue(cgfloat: props.contentPreferMaxWidth - 2 * props.contentPadding - 2 * Layout.contentHorizontalMargin)

        // image
        image.props.imageUrlString = props.docAbstract
        let value = props.thumbnailDetail?.data(using: .utf8, allowLossyConversion: false)
        var tmpJson: [String: Any] = [:]
        let jso = JSON(value as Any).dictionaryObject
        if jso != nil {
            tmpJson["url"] = jso?["thumbnail_url_mobile"]
            tmpJson["nonce"] = jso?["decrypt_nonce_mobile"]
            tmpJson["secret"] = jso?["decrypt_key_mobile"]
            tmpJson["type"] = jso?["cipher_type"]
            image.props.thumbNai = tmpJson
        }
        image.props.docType = props.docType
        image.props.delegate = props
        // Size
        let imageWidth = props.contentPreferMaxWidth - 2 * props.contentPadding - 2 * Layout.contentHorizontalMargin
        image.style.width = CSSValue(cgfloat: imageWidth)
        image.style.height = CSSValue(cgfloat: floor(imageWidth / 12 * 7)) // 按照设计稿上 12/7 的宽高比，向下取整，调整图片高度
        // Text
        permissionButton.style.display = .flex
        permissionButton.props.text = props.permissionText
        // 触发willReceiveUpdate
        if props.canSelectPermission {
            permissionButton.props.textColor = UDColor.primaryContentDefault
            permissionButton.props.iconSize = CGSize(width: 10, height: 10)
            permissionButton.props.onViewClicked = { [weak self] sourceView in
                self?.props.delegate?.docPreviewWillChangePermission(sourceView: sourceView)
            }
        } else {
            //发送方如果没有可选x权限的时候需要使用单独的样式，并且去掉icon
            permissionButton.props.textColor = UDColor.N900
            permissionButton.props.iconSize = .zero
        }
        permissionButton.props = permissionButton.props
        desc.props.text = props.permissionDesc
        descInfo.props.text = props.shareText
        if props.isFromMe && props.bottomHintViewType != .none {
            configBottomHintView(type: props.bottomHintViewType, props: props)
        }

        if props.isFromMe {
            //显示bottomContainer
            //分享失败，但是接收方有权限，不需要感叹号
            if props.shareStatus >= Int64(6) &&
                props.receiverPerm == 0 {
                //分享失败，且接收方没权限，需要显示感叹号
                icon.style.display = .flex

                desc.style.alignSelf = .flexStart
                icon.style.alignSelf = .flexStart
                desc.style.marginLeft = CSSValue(cgfloat: 5)
            } else {
                icon.style.display = .none
                icon.style.alignSelf = .auto
                desc.style.alignSelf = .auto
                desc.style.marginLeft = CSSValue(cgfloat: 0)
            }
        } else {
            //没有权限的文档需要展示感叹号
            if props.userPerm == 0 {
                descInfo.props.iconSize = CGSize(width: 16, height: 16)
            } else {
                //有权限的文档不需要展示感叹号
                descInfo.props.iconSize = CGSize(width: 0, height: 0)
                descInfo.props.iconAndLabelSpacing = 0
            }
        }

        descInfo.props = descInfo.props
        permissionButton.style.marginLeft = 8
        // ShareStatus > 1 需要增加desc,其他返回码按照之前逻辑处理
        if props.shareStatus > Int64(1) {
            desc.props.text = props.shareStatusText
            permissionButton.style.display = .none
        }
//        singlePageDesc.style.marginLeft = 8
//        singlePageDesc.props.text = props.singlePageDesc
        configUI(props: props)
    }

    private func configUI(props: DocPreviewComponentProps) {
        switch props.bottomHintViewType {
        case .askOwnerTips:
            bottomContainer.style.display = .none
            descInfo.style.display = .flex
        case .internalTips, .externalTips, .closeCrossTenantTips, .wikiSettingCloseCrossTenant:
            bottomContainer.style.display = .flex
            descInfo.style.display = .flex
        case .none:
            bottomContainer.style.display = props.isFromMe ? .flex : .none
            descInfo.style.display = props.isFromMe ? .none : .flex
            if !props.isFromMe && props.userPerm != 0 {
                // 发送人非自己，且有权限，使用 descInfo 展示权限状态，此时不展示 icon，且不需要背景色
                descInfo.style.backgroundColor = .clear
            } else if !props.isFromMe, props.userPerm == 0 {
                // 发送人非自己，且无权限，展示无权限提示
                descInfo.style.display = .none
                permissionButton.style.display = .none
                desc.props.text = props.shareText
                desc.style.marginLeft = CSSValue(cgfloat: 5)
                icon.style.display = .flex
                desc.style.alignSelf = .flexStart
                icon.style.alignSelf = .flexStart
                bottomContainer.style.display = .flex
            } else {
                // 其他场景，需要重置 descInfo 的背景色
                descInfo.style.backgroundColor = UDColor.fillHover
            }
        }
        // 发送给自己全部不展示
        // TODO: Android、PC 在发送给自己时也会展示 bottomContainer，后续对齐
        if props.isChatWithMe {
            bottomContainer.style.display = .none
            descInfo.style.display = .none
            seperator.style.display = .none
            image.style.marginBottom = CSSValue(cgfloat: 12)
        } else {
            // 除发送给自己外，底部至少会展示一个信息，需要分隔线
            seperator.style.display = .flex
            image.style.marginBottom = CSSValue(cgfloat: 4)
        }
    }

    private func configBottomHintView(type: BottomHintViewType, props: DocPreviewComponentProps) {
        switch type {
        case .none:
            descInfo.props.linkRange = nil
        case .askOwnerTips:
            configDescInfoCore()
            descInfo.style.backgroundColor = .clear
            descInfo.style.paddingTop = CSSValue(cgfloat: 0)
            descInfo.style.paddingBottom = CSSValue(cgfloat: 0)
            descInfo.style.paddingRight = 0
            descInfo.style.paddingLeft = 0
            // 发送者是自己，若用户无分享权限，显示Ask Owner按钮
            descInfo.props.onLabelClicked = {
                let needPopover = Display.pad &&
                    props.fromVc?.view.window?.lkTraitCollection.horizontalSizeClass == .regular
                let body = AskOwnerBody(collaboratorID: props.chatID,
                                        ownerName: props.docOwner ?? "",
                                        ownerID: props.docOwnerID?.description ?? "",
                                        docsType: props.docType.rawValue,
                                        objToken: props.docKey,
                                        imageKey: props.chatIcon,
                                        title: props.chatName,
                                        detail: props.description,
                                        isExternal: props.isCrossTenanet,
                                        isCrossTenanet: props.isCrossTenanet,
                                        needPopover: needPopover,
                                        roleType: props.roleType)
                props.askOwnerDependency?.openAskOwnerView(body: body, from: props.fromVc)
            }
            let btnCount = BundleI18n.LarkMessageCore.Lark_Docs_ChatDocAskOwnerButton.count
            guard props.shareStatusText.count - btnCount >= 0 else { return }
            let linkRange = NSRange(location: props.shareStatusText.count - btnCount, length: btnCount)
            descInfo.props.linkRange = linkRange
        case .externalTips, .closeCrossTenantTips, .wikiSettingCloseCrossTenant:
            configDescInfoCore()
            descInfo.props.lineSpacing = 20
            descInfo.props.onLabelClicked = { [weak self] in
                guard let self = self else { return }
                self.deleteCollaborators(with: props)
            }
            let btnCount = BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton.count
            guard props.shareStatusText.count - btnCount >= 0 else { return }
            let linkRange = NSRange(location: props.shareStatusText.count - btnCount, length: btnCount)
            descInfo.props.linkRange = linkRange
        case .internalTips:
            configDescInfoCore()
            descInfo.props.lineSpacing = 20
            descInfo.props.onLabelClicked = { [weak self] in
                guard let self = self else { return }
                self.deleteCollaborators(with: props)
            }
            if props.roleType == 0 {
                // 单聊
                let btnCount = BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton.count
                guard props.shareStatusText.count - btnCount >= 0 else { return }
                let linkRange = NSRange(location: props.shareStatusText.count - btnCount, length: btnCount)
                descInfo.props.linkRange = linkRange
            } else {
                // 群
                let btnCount = BundleI18n.LarkMessageCore.Lark_Permission_CancelGrantButton.count
                guard props.shareStatusText.count - btnCount >= 0 else { return }
                let linkRange = NSRange(location: props.shareStatusText.count - btnCount, length: btnCount)
                descInfo.props.linkRange = linkRange
            }
        }
    }

    private func configDescInfoCore() {
        descInfo.props.iconAndLabelSpacing = 7
        descInfo.props.width = props.contentPreferMaxWidth - 2 * props.contentPadding - 2 * Layout.contentHorizontalMargin
        descInfo.style.paddingTop = CSSValue(cgfloat: 8)
        descInfo.style.paddingBottom = CSSValue(cgfloat: 8)
        descInfo.props.iconSize = CGSize(width: 16, height: 16)
        descInfo.style.paddingLeft = 12
        descInfo.style.paddingRight = 12
        descInfo.style.cornerRadius = 4
        descInfo.style.backgroundColor = UDColor.fillHover
        descInfo.props.text = props.shareStatusText
    }

    private func deleteCollaborators(with props: DocPreviewComponentProps) {
        props.docPermissionDependency?.deleteCollaborators(type: props.docType.docsTypeRawValue,
                                                          token: props.docKey,
                                                          ownerID: props.chatID,
                                                          ownerType: props.roleType,
                                                          permType: props.singlePageState.rawValue) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                self.logger.info("deleteCollaborators success!")
            case .failure(let error):
                self.logger.error("deleteCollaborators failed with \(error)")
            }
        }
    }
}

extension DocPreviewComponentProps: DocThumbnailComponentDelegate {
    public var thumbnailDecryptionAvailable: Bool {
        return delegate?.thumbnailDecryptionAvailable ?? false
    }
    public func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        guard let delegate = delegate else { return .empty() }
        return delegate.downloadThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: imageViewSize)
    }
}

extension RustPB.Basic_V1_Doc.TypeEnum {
    var docsTypeRawValue: Int {
        switch self {
        case .doc:
            return 2
        case .sheet:
            return 3
        case .bitable:
            return 8
        case .mindnote:
            return 11
        case .file:
            return 12
        case .slide:
            return 15
        case .slides:
            return 30
        case .docx:
            return 22
        case .wiki:
            return 16
        case .folder:
            return 0
        case .catalog:
            return 111
        case .unknown:
            return -1
        case .shortcut: // 移动端尚未接入
            return -1
        @unknown default:
            return -1
        }
    }
}
