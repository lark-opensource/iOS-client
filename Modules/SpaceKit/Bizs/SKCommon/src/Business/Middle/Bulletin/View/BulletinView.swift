//
//  BulletinView.swift
//  AnimationDemo
//
//  Created by 边俊林 on 2019/3/15.
//  Copyright © 2019 边俊林. All rights reserved.
//

import UIKit
import SnapKit
import LarkLocalizations
import SKFoundation
import SKUIKit
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

public protocol BulletinViewDelegate: AnyObject {
    func shouldClose(_ bulletinView: BulletinView)
    func shouldOpenLink(_ bulletinView: BulletinView, url: URL)
}

/// 公告栏通用组件，支持后台下发纯文字/HTML文本解析
public final class BulletinView: UIView, BannerItem {
    public var itemType: SKBannerContainer.ItemType {
        return .bulletin
    }
    public var contentView: UIView {
        return self
    }
    public weak var delegate: BulletinViewDelegate?
    public weak var uiDelegate: BannerUIDelegate?

    public var info: BulletinInfo? {
        didSet { didUpdateInfo() }
    }
    // MARK: UI Widget
    lazy var iconImage: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.boardsColorful
        return iv
    }()
    lazy var closeButton: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.addTarget(self, action: #selector(shouldClose), for: .touchUpInside)
        return btn
    }()
    lazy var detailView: UITextView = {
        let tv = UITextView()
        tv.alwaysBounceVertical = false
        tv.alwaysBounceHorizontal = false
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.isEditable = false
        tv.isScrollEnabled = false
        tv.textDragInteraction?.isEnabled = false
        tv.backgroundColor = .clear
        tv.delegate = self
        return tv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func layoutHorizontalIfNeeded(preferedWidth: CGFloat) {
        let width = (uiDelegate?.preferedWidth(self) ?? frame.width) - Const.leadingPadding - Const.trailingPadding
        let height = AttributedStringUtil.heightOf(detailView.attributedText, byWidth: width) + 2 * Const.horPadding
        uiDelegate?.shouldUpdateHeight(self, newHeight: min(height, Const.maxHeihgtRate * (SKDisplay.windowBounds(self).height)))
    }

    private func commonInit() {
        setupView()
        configure()
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(themeDidChanged), name: UDThemeManager.didChangeNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(themeDidChanged), name: Notification.Name.DocsThemeChanged, object: nil)
        }
    }

    private func setupView() {
        addSubview(detailView)
        addSubview(iconImage)
        addSubview(closeButton)

        detailView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(Const.leadingPadding)
            make.trailing.equalToSuperview().inset(Const.trailingPadding)
            make.top.equalToSuperview().inset(Const.horPadding)
        }
        iconImage.snp.makeConstraints { (make) in
            make.height.width.equalTo(16)
            make.top.equalToSuperview().inset(Const.horPadding)
            make.leading.equalToSuperview().inset(16)
        }
        closeButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(18)
            make.top.equalToSuperview().inset(Const.horPadding)
            make.trailing.equalToSuperview().inset(8)
        }
    }

    private func configure() {
        backgroundColor = UIColor.ud.B100
        detailView.textContainerInset = .zero
        detailView.textContainer.lineFragmentPadding = 0
    }

    @objc
    private func shouldClose() {
        delegate?.shouldClose(self)
    }

     @objc
    private func themeDidChanged() {
        didUpdateInfo()
    }

    private func didUpdateInfo() {
        let attributedString: NSAttributedString
        if let info = info {
//            DocsLogger.info("bulletin info is \(info.description)")
            attributedString = Self.generateAttributedString(for: info) ?? NSAttributedString(string: "")
        } else {
            DocsLogger.error("bulletin info is nil")
            attributedString = NSAttributedString(string: "")
        }
        let containerWidth = uiDelegate?.preferedWidth(self) ?? frame.width
        let height = Self.calculateEstimateHeight(for: attributedString, containerWidth: containerWidth)
        uiDelegate?.shouldUpdateHeight(self, newHeight: min(height, Const.maxHeihgtRate * SKDisplay.windowBounds(self).height))
        detailView.attributedText = attributedString
    }

    public class func calculateEstimateHeight(for attributedString: NSAttributedString, containerWidth: CGFloat) -> CGFloat {
        let width = containerWidth - Const.leadingPadding - Const.trailingPadding
        let height = AttributedStringUtil.heightOf(attributedString, byWidth: width) + 2 * Const.horPadding
        return height
    }

    public class func generateAttributedString(for info: BulletinInfo) -> NSAttributedString? {
        let rawText = info.content[DocsSDK.convertedLanguage] ?? info.content[DocsSDK.convertedDefaultLanguageEn] ?? ""
        let fontColorHex = UDColor.N1000.hex6 ?? "#000000"
        let htmlStr = "<font style=\"font-size:14;color:\(fontColorHex);font-family:'-apple-system'\">" + rawText + "</font>"
        guard let detailData = htmlStr.data(using: .unicode) else {
            DocsLogger.error("failed to parse bulletin html data")
            return nil
        }
        do {
            let attributedString = try NSAttributedString(data: detailData,
                                                          options: [.documentType: NSAttributedString.DocumentType.html],
                                                          documentAttributes: nil)
            return attributedString
        } catch {
            DocsLogger.error("bulletin attrStr is nil, error: \(error)")
            return nil
        }
    }
}

extension BulletinView: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            delegate?.shouldOpenLink(self, url: URL)
        }
        return false
    }
}

extension BulletinView {
    struct Const {
        static let horPadding: CGFloat = 10
        static let leadingPadding: CGFloat = 42
        static let trailingPadding: CGFloat = 38
        static let maxHeihgtRate: CGFloat = 0.4
    }
}
