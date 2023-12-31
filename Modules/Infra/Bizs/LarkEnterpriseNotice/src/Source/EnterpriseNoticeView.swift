//
//  EnterpriseNoticeView.swift
//  LarkEnterpriseNotice
//
//  Created by ByteDance on 2023/4/19.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme
import SnapKit
import ByteWebImage
import LarkLocalizations

protocol EnterpriseNoticeViewDelegate: AnyObject {
    func didClickMainBtn(cardInfo: EnterpriseNoticeCard)
    func didClickCloseBtn(cardInfo: EnterpriseNoticeCard)
}


class EnterpriseNoticeView: UIView {

    enum Layout {
        // 卡片整体间距
        static let padding = 16.0
        // 图标尺寸
        static let iconSize = 24.0
        // icon to title
        static let iconToTitleMargin = 16.0
        // title to content
        static let titleToContentMargin = 8.0
        // content to button
        static let contentToButtonMargin = 16.0
        // 按钮最小内间距
        static let minButtonInset = 16.0
        // button height
        static let buttonHeight = 36.0
        // max height
        static let maxHeight = 288.0
    }
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Layout.iconSize / 2
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var iconNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 1
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    lazy var contentContainer: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: Layout.padding, bottom: 0, right: -Layout.padding)
        return scrollView
    }()

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        return label
    }()

    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        return stackView
    }()

    lazy var mainButton: UIButton = {
        let button = UIButton(type: .custom)
        let bgImage = UIImage.ud.fromPureColor(UIColor.ud.primaryContentDefault)
        button.setBackgroundImage(bgImage, for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()

    lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitle(BundleI18n.LarkEnterpriseNotice.Lark_IM_SurveyPopup_Close_Button, for: .normal)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()

    weak var delegate: EnterpriseNoticeViewDelegate?

    var cardInfo: EnterpriseNoticeCard

    init(card: EnterpriseNoticeCard) {
        self.cardInfo = card
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloatPush
        self.layer.cornerRadius = 16
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.layer.borderWidth = 1
        self.addSubview(iconImageView)
        self.addSubview(iconNameLabel)
        self.addSubview(titleLabel)
        self.addSubview(contentContainer)
        contentContainer.addSubview(contentLabel)
        self.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(closeButton)
        buttonStackView.addArrangedSubview(mainButton)
        mainButton.addTarget(self, action: #selector(mainBtnDidClick), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeBtnDidClick), for: .touchUpInside)

        // Layout
        iconImageView.snp.makeConstraints { make in
            make.height.width.equalTo(Layout.iconSize)
            make.top.leading.equalTo(Layout.padding)
        }
        iconNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualTo(-Layout.padding)
            make.centerY.equalTo(iconImageView)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(Layout.padding)
            make.trailing.equalTo(-Layout.padding)
            make.top.equalTo(iconImageView.snp.bottom).offset(Layout.iconToTitleMargin)
        }
        contentContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleToContentMargin)
            make.height.equalTo(0)
        }
        contentLabel.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-Layout.padding * 2)
            make.leading.top.equalToSuperview()
        }
        buttonStackView.snp.makeConstraints { make in
            make.leading.equalTo(Layout.padding)
            make.trailing.equalTo(-Layout.padding)
            make.height.equalTo(0)
            make.top.equalTo(contentContainer.snp.bottom).offset(Layout.contentToButtonMargin)
            make.bottom.equalToSuperview().offset(-Layout.padding)
        }
        self.updateContent(card: card)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 更新content内容
    func updateContent(card: EnterpriseNoticeCard) {
        iconImageView.bt.setLarkImage(with: .avatar(key: card.avatarImage.key, entityID: ""))
        iconNameLabel.text = getLocalName(dict: card.name)
        titleLabel.text = getLocalName(dict: card.title)
        contentLabel.text = getLocalName(dict: card.content)
        mainButton.setTitle(getLocalName(dict: card.buttonText), for: .normal)
        closeButton.isHidden = !card.closable
    }

    // 返回总高度
    func updateLayout(width: CGFloat) -> CGFloat {
        var totalHeight = 0.0
        let size = CGSize(width: width - Layout.iconSize * 2, height: CGFloat.greatestFiniteMagnitude)
        let titleHeight = titleLabel.textRect(forBounds: CGRect(origin: .zero, size: size), limitedToNumberOfLines: 0).size.height
        let contentHeight = contentLabel.textRect(forBounds: CGRect(origin: .zero, size: size), limitedToNumberOfLines: 0).size.height
        // 更新按钮布局
        buttonStackView.removeArrangedSubview(closeButton)
        buttonStackView.removeArrangedSubview(mainButton)
        let buttonHeight = calculateButtonHeight(width: width)
        buttonStackView.snp.updateConstraints { make in
            make.height.equalTo(buttonHeight)
        }
        if buttonHeight != Layout.buttonHeight {
            // 纵向布局
            buttonStackView.axis = .vertical
            buttonStackView.spacing = 8
            buttonStackView.distribution = .fillEqually
            buttonStackView.addArrangedSubview(mainButton)
            buttonStackView.addArrangedSubview(closeButton)
        } else {
            // 横向布局
            buttonStackView.axis = .horizontal
            buttonStackView.spacing = 16
            buttonStackView.distribution = .fillEqually
            buttonStackView.addArrangedSubview(closeButton)
            buttonStackView.addArrangedSubview(mainButton)
        }
        // 总高度
        // ------------
        //  Icon Name
        //    Title
        //   Content
        //   Buttons
        // ------------
        totalHeight += Layout.padding + Layout.iconSize + Layout.iconToTitleMargin + titleHeight + Layout.titleToContentMargin + contentHeight + Layout.contentToButtonMargin + buttonHeight + Layout.padding
        // 更新content布局,高度大于maxHeight则被压缩，且支持滚动
        contentContainer.isScrollEnabled = totalHeight > Layout.maxHeight
        let contentContainerHeight = totalHeight > Layout.maxHeight ? contentHeight - (totalHeight - Layout.maxHeight) : contentHeight
        contentContainer.snp.updateConstraints { make in
            make.height.equalTo(contentContainerHeight)
        }
        contentContainer.contentSize = CGSize(width: width, height: contentHeight)
        return min(totalHeight, Layout.maxHeight)
    }

    private func calculateButtonHeight(width: CGFloat) -> CGFloat {
        if closeButton.isHidden {
            return Layout.buttonHeight
        }
        // 两个按钮情况，根据内容宽度决定布局方向
        // button title最大宽度
        let maxWidth = (width - 16.0) / 2.0 - 16.0 - 2 * Layout.minButtonInset
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let closeBtnTitleWidth = closeButton.titleLabel?.textRect(forBounds: CGRect(origin: .zero, size: size), limitedToNumberOfLines: 1).size.width ?? 0
        let mainBtnTitleWidth = mainButton.titleLabel?.textRect(forBounds: CGRect(origin: .zero, size: size), limitedToNumberOfLines: 1).size.width ?? 0
        if closeBtnTitleWidth > maxWidth || mainBtnTitleWidth > maxWidth {
            return Layout.buttonHeight * 2 + 8
        } else {
            return Layout.buttonHeight
        }
    }

    func getLocalName(dict: [String: String]) -> String {
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        // 优先本地语言,否则用default兜底
        if let local = dict[lang], !local.isEmpty {
            return local
        }
        return dict["default"] ?? ""
    }
    
    @objc
    func mainBtnDidClick() {
        self.delegate?.didClickMainBtn(cardInfo: self.cardInfo)
    }

    @objc
    func closeBtnDidClick() {
        self.delegate?.didClickCloseBtn(cardInfo: self.cardInfo)
    }
}
