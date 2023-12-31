//
//  SKAppealBanner.swift
//  SKUIKit
//
//  Created by peilongfei on 2023/9/27.
//  


import UIKit
import SnapKit
import SKFoundation
import SKUIKit
import UniverseDesignNotice

public class SKAppealBanner: UIView {

    public var clickCallback: ((URL) -> Void)?

    lazy var tipsView: NetInterruptTipView = {
        let view = NetInterruptTipView.defaultView()
        view.delegate = self
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setupUI() {
        addSubview(tipsView)
        tipsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func update(complaintState: ComplaintState, entityId: String, isFolder: Bool = false) {
        let text = isFolder ? complaintState.folderAppealV2 : complaintState.appealV2
        tipsView.setTitle(text, type: complaintState.appealTipsType, canClose: true)

        AppealLinkTool.appealLinkText(state: complaintState, entityId: entityId).forEach { linkText, link in
            tipsView.addLinkText(linkText, linkUrl: link, showUnderline: false)
        }
    }
}

extension SKAppealBanner: UDNoticeDelegate {

    public func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        clickCallback?(URL)
    }

    public func handleLeadingButtonEvent(_ button: UIButton) {}

    public func handleTrailingButtonEvent(_ button: UIButton) {}
}

extension SKAppealBanner: BannerItem {
    public var uiDelegate: SKUIKit.BannerUIDelegate? {
        get {
            return tipsView.uiDelegate
        }
        set(newValue) {
            tipsView.uiDelegate = newValue
        }
    }

    public var itemType: SKUIKit.SKBannerContainer.ItemType {
        return tipsView.itemType
    }

    public var contentView: UIView {
        return tipsView.contentView
    }

    public func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        tipsView.layoutHorizontalIfNeeded(preferedWidth: preferedWidth)
    }

}
