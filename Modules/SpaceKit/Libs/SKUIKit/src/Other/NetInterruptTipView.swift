//
//  NetInterruptTipView.swift
//  SpaceKit
//
//  Created by Webster on 2018/12/3.
//

import SnapKit
import Foundation
import SKFoundation
import SKResource
import RichLabel
import EENavigator
import LarkUIKit
import UniverseDesignNotice
import UniverseDesignFont

public enum TipType {
    case listOffline
    case listFeedOffline
    case docOfflineOpen
    case docOfflineCreate
    case sheetOffline
    case bitableOffline
    case mindnoteOffline
    case slideOffline
    case custom(ShowStyle)
    case machineAuditFailed
    case humanAuditFailed
    case announcementEditingIllegal // 群公告违规

   public enum ShowStyle {
        case levelStyleWarning
        case levelStyleError
        case levelStyleNormal
    }

    public func details() -> String {
        switch self {
        case .listOffline, .docOfflineOpen, .docOfflineCreate, .mindnoteOffline:
            return BundleI18n.SKResource.Doc_Facade_SyncedNextOnline
        case .listFeedOffline:
            return BundleI18n.SKResource.Doc_Feed_SyncBackOnline
        case .sheetOffline:
            return BundleI18n.SKResource.Doc_Facade_SheetSyncedNextOnline
        case .bitableOffline:
            return BundleI18n.SKResource.Bitable_Common_CannotEditWhenOffline
        case .slideOffline:
            return BundleI18n.SKResource.LarkCCM_Slides_NoNetwork_Mob
        case .machineAuditFailed:
            return BundleI18n.SKResource.Drive_Drive_DisableShareByPolicy()
        case .humanAuditFailed:
            return BundleI18n.SKResource.Drive_Drive_DiscardedFileHint()
        case .announcementEditingIllegal:
            return BundleI18n.SKResource.Doc_Review_Fail_Notify_Member()
        case .custom:
            return ""
        }
    }

    public func stylesDetail() -> UDNoticeType {
        switch self {
        case .listOffline, .docOfflineOpen, .bitableOffline, .docOfflineCreate, .mindnoteOffline, .slideOffline:
            return .warning
        case .sheetOffline:
            return .warning
        case let .custom(style):
            if style == .levelStyleNormal { return .info }
            if style == .levelStyleError { return .error }
            if style == .levelStyleWarning { return .warning }
        default :
            return .info
        }
        return .info
    }
}

extension TipType: Equatable {
    public static func == (lhs: TipType, rhs: TipType) -> Bool {
        switch (lhs, rhs) {
        case (.listOffline, .listOffline),
             (.listFeedOffline, .listFeedOffline),
             (.docOfflineOpen, .docOfflineOpen),
             (.docOfflineCreate, .docOfflineCreate),
             (.sheetOffline, .sheetOffline),
             (.bitableOffline, .bitableOffline),
             (.mindnoteOffline, .mindnoteOffline),
             (.slideOffline, .slideOffline),
             (.machineAuditFailed, .machineAuditFailed),
             (.humanAuditFailed, .humanAuditFailed),
             (.announcementEditingIllegal, announcementEditingIllegal):
            return true
        case let (.custom(style1), .custom(style2)):
            return style1 == style2
        default:
            return false
        }
    }
}

public final class NetInterruptTipView: UDNotice, BannerItem {

    weak public var uiDelegate: BannerUIDelegate?
    weak public var actionDelegate: ActionDeleagete?
    public var itemType: SKBannerContainer.ItemType {
        return .warning
    }
    public var title: String?
    public var contentView: UIView {
        return self
    }
    private(set) var currentType: TipType = .listOffline {
        didSet {
            if currentType != oldValue {

            }
        }
    }

    public func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        uiDelegate?.shouldUpdateHeight(self, newHeight: self.sizeThatFits(CGSize(width: preferedWidth, height: 10)).height)
    }


    /// MLeaksFinder傻傻的，vc引用了这个view，即使其在deinit里销毁掉了，
    /// 这个库还是会因为BrowserView的重用机制报内存泄露(因为这个view宿主是browserView),所以骗它一下
    @objc
    func willDealloc() -> Bool {
        return false
    }

    // 注意此方法的计算与 UDNotice 实际的计算结果不符，建议直接使用 sizeThatFit 方法计算
    public class func calcLabelHeight(_ string: String, width: CGFloat, showClose: Bool = false) -> CGFloat {
        let closeBtnWidth = showClose ? TipViewLayout.closeBtnHeight + TipViewLayout.bodyLabelRightPadding : 0
        let width = width - TipViewLayout.bodyLabelLeftPadding - TipViewLayout.bodyLabelRightPadding - closeBtnWidth

        let frame = CGRect(x: 0, y: 0, width: width, height: 0)
        let label = UILabel(frame: frame)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.font = TipViewLayout.bodyLabelFont
        label.text = string
        label.sizeToFit()
        let dstResult = label.frame
        let contentGap = TipViewLayout.contentTopBottomGap
        return dstResult.size.height + contentGap * 2
    }

    public class func defaultView() -> NetInterruptTipView {
        // 临时修改,解决约束冲突问题
        var frame: CGRect = .zero
        frame.size.width = Navigator.shared.mainSceneWindow?.frame.width ?? 0
        let attributedText = NSAttributedString(string: BundleI18n.SKResource.Doc_Facade_SyncedNextOnline,
                                                attributes: [.font: UIFont.systemFont(ofSize: 30, weight: .medium),
                                                             .foregroundColor: UIColor.ud.textTitle])
        let config = UDNoticeUIConfig(type: .warning, attributedText: attributedText)
        let view = NetInterruptTipView(config: config)
        return view
    }

    private lazy var alertView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    
    private lazy var closeBtn: UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.SKResource.Common.Tips.icon_tips_close, for: .normal)
        button.addTarget(self, action: #selector(closeTips), for: .touchUpInside)
        return button
    }()

    public func setTitle(_ title: String, type: TipType = .custom(.levelStyleError), canClose: Bool = false) {
        currentType = type
        self.title = title
        let attributedText = NSAttributedString(string: title)
        var config = UDNoticeUIConfig(type: currentType.stylesDetail(), attributedText: attributedText)
        if canClose == true {
            config.trailingButtonIcon = BundleResources.SKResource.Common.Tips.icon_tips_close
        }
        self.updateConfigAndRefreshUI(config)
    }

    public func setLinkText(_ linkText: String, linkUrl: String, canClose: Bool = false, showUnderline: Bool = true) {
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.ud.textTitle,
                                                         .font: TipViewLayout.bodyLabelFont]
        guard let content = self.title, let linkedUrl = URL(string: linkUrl) else {
            return
        }
        let attributedString = NSMutableAttributedString(string: content, attributes: attributes)

        let contractRange = (content as NSString).range(of: linkText)
        if showUnderline {
            attributedString.addAttributes([NSAttributedString.Key.link: linkedUrl, .underlineColor: UIColor.ud.B400, .foregroundColor: UIColor.ud.B400, .underlineStyle: NSUnderlineStyle.single.rawValue],
                                           range: contractRange)
        } else {
            attributedString.addAttributes([NSAttributedString.Key.link: linkedUrl, .foregroundColor: UIColor.ud.B400],
                                           range: contractRange)
        }
        var config = UDNoticeUIConfig(type: currentType.stylesDetail(), attributedText: attributedString)
        if canClose == true {
            config.trailingButtonIcon = BundleResources.SKResource.Common.Tips.icon_tips_close
        }
        self.updateConfigAndRefreshUI(config)
    }

    public func addLinkText(_ linkText: String, linkUrl: String, showUnderline: Bool = true) {
        guard let content = self.title, let linkedUrl = URL(string: linkUrl) else {
            return
        }
        let attributedString = NSMutableAttributedString(attributedString: self.config.attributedText)
        let contractRange = (content as NSString).range(of: linkText, options: .backwards)
        if showUnderline {
            attributedString.addAttributes([NSAttributedString.Key.link: linkedUrl, .underlineColor: UIColor.ud.B400, .foregroundColor: UIColor.ud.B400, .underlineStyle: NSUnderlineStyle.single.rawValue],
                                           range: contractRange)
        } else {
            attributedString.addAttributes([NSAttributedString.Key.link: linkedUrl, .foregroundColor: UIColor.ud.B400],
                                           range: contractRange)
        }
        let config = UDNoticeUIConfig(type: currentType.stylesDetail(), attributedText: attributedString)
        self.updateConfigAndRefreshUI(config)
    }

    public func setLeadingButtonText(_ leadingButtonText: String) {
        var curConfig = self.config
        curConfig.leadingButtonText = leadingButtonText
        self.updateConfigAndRefreshUI(curConfig)
    }

    public func setTip(_ type: TipType) {
        currentType = type
        self.title = type.details()
        
        let attributedText = NSAttributedString(string: type.details(),
                                                attributes: [.font: UIFont.systemFont(ofSize: 30, weight: .medium),
                                                             .foregroundColor: UIColor.ud.textTitle])
        let config = UDNoticeUIConfig(type: .warning, attributedText: attributedText)
        self.updateConfigAndRefreshUI(config)
    }

    public override init(config: UDNoticeUIConfig) {
        super.init(config: config)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func closeTips() {
        actionDelegate?.didClose()
    }
}


extension NetInterruptTipView {
    struct TipViewLayout {
        static let contentTopBottomGap: CGFloat = 12
        static let fontSize: CGFloat = 14
        static let alertHeight: CGFloat = 16
        static let closeBtnHeight: CGFloat = 16
        static let alertViewAndBodyLabelGap: CGFloat = 10
        static let bodyLabelLeftPadding: CGFloat = 41
        static let bodyLabelRightPadding: CGFloat = 10
        static let bodyLabelMaxWidth: CGFloat = (Navigator.shared.mainSceneWindow?.frame.width ?? 0) - TipViewLayout.bodyLabelLeftPadding - TipViewLayout.bodyLabelRightPadding
        static let bodyLabelFont: UIFont = UIFont.systemFont(ofSize: TipViewLayout.fontSize, weight: .regular)
    }
}
