//
//  DocsRestoreFailedPanel.swift
//  SKCommon
//
//  Created by majie.7 on 2022/10/31.
//

import Foundation
import SKUIKit
import UniverseDesignColor
import SKResource
import SKFoundation
import EENavigator

public struct DocsDeleteOperator {
    let id: String
    let cnName: String
    let enName: String
}

public struct DocsRestoreFailedInfo {
    static let attributedStringTapKey = NSAttributedString.Key(rawValue: "tap")
    let deleteOperator: DocsDeleteOperator
    let spaceName: String?
    let spaceID: String?
    
    var isWiki: Bool {
        return spaceID != nil && spaceName != nil
    }
    
    var displayName: String {
        if DocsSDK.currentLanguage == .en_US {
            return deleteOperator.enName.isEmpty ? deleteOperator.cnName : deleteOperator.enName
        } else {
            return deleteOperator.cnName
        }
    }
}

class DocsRestoreFailePanel: SKPanelController, UITextViewDelegate {
    enum TapLabelType {
        case at(id: String)        // 个人主页
        case toWiki(url: URL)     // 跳wiki库
    }
    let links = ("resotre://at", "resotre://to_wiki")
    var clickCompeletion: ((TapLabelType) -> Void)?
    private lazy var headerView: SKPanelHeaderView = {
        let view = SKPanelHeaderView()
        view.setTitle(BundleI18n.SKResource.LarkCCM_Workspace_Deleted_RestoreFailed_Title)
        view.setCloseButtonAction(#selector(didClickMask), target: self)
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Confirm, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.backgroundColor = UDColor.primaryContentDefault
        button.addTarget(self, action: #selector(didClickMask), for: .touchUpInside)
        return button
    }()
    
    private lazy var descriptionLabel: UITextView = {
        let label = UITextView()
        label.attributedText = descriptionText()
        label.isScrollEnabled = false
        label.isEditable = false
        label.isOpaque = true
        label.backgroundColor = .clear
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.textColor = UDColor.textTitle
        label.sizeToFit()
        label.delegate = self
        return label
    }()
    
    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()
    
    private var defaultAttr: [NSAttributedString.Key: Any] {
        var attr = [NSAttributedString.Key: Any]()
        attr[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 16)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineSpacing = 2
        paragraphStyle.lineBreakMode = .byWordWrapping
        attr[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        return attr
    }
    
    private var failedInfo: DocsRestoreFailedInfo
    
    public init(info: DocsRestoreFailedInfo) {
        self.failedInfo = info
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = [.systemSizeClassChanged]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(bottomLine)
        containerView.addSubview(confirmButton)
        
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(48)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        bottomLine.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(descriptionLabel.snp.bottom).offset(16)
            make.height.equalTo(0.5)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(bottomLine.snp.bottom).offset(16)
            make.left.lessThanOrEqualToSuperview().offset(16)
            make.right.greaterThanOrEqualToSuperview().offset(-16)
            make.bottom.equalTo(containerView.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.height.equalTo(36)
        }
    }
    
    private func descriptionText() -> NSAttributedString {
        if failedInfo.isWiki, let spaceName = failedInfo.spaceName {
            let text = BundleI18n.SKResource.LarkCCM_Workspace_Deleted_RestoreFailed_Description(" @\(failedInfo.displayName) ", " \(spaceName) ")
            let attributeText = NSMutableAttributedString(string: text, attributes: defaultAttr)
            let atInfoRange = attributeText.mutableString.range(of: " @\(failedInfo.displayName) ")
            let wikiNameRange = attributeText.mutableString.range(of: " \(spaceName) ")
            attributeText.addAttributes([.link: links.0,
                                         .foregroundColor: UDColor.colorfulBlue,
                                         .underlineColor: UIColor.clear],
                                        range: atInfoRange)
            attributeText.addAttributes([.link: links.1,
                                         .foregroundColor: UDColor.colorfulBlue,
                                         .underlineColor: UIColor.clear],
                                        range: wikiNameRange)
            return attributeText
        } else {
            let text = BundleI18n.SKResource.LarkCCM_Workspace_Deleted_Restore2SpaceFailed_Description(" @\(failedInfo.displayName) ")
            let attributeText = NSMutableAttributedString(string: text, attributes: defaultAttr)
            let atInfoRange = attributeText.mutableString.range(of: " @\(failedInfo.displayName) ")
            attributeText.addAttributes([.link: links.0,
                                         .foregroundColor: UDColor.colorfulBlue,
                                         .underlineColor: UIColor.clear],
                                        range: atInfoRange)
            return attributeText
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString == links.0 {
            // 个人主页
            clickCompeletion?(.at(id: failedInfo.deleteOperator.id))
            return false
        } else if URL.absoluteString == links.1 {
            guard let spaceID = failedInfo.spaceID, let url = DocsUrlUtil.wikiSpaceURL(spaceID: spaceID) else {
                return true
            }
            // 跳库
            clickCompeletion?(.toWiki(url: url))
            return false
        }
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        false
    }
}
