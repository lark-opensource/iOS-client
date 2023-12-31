//
//  AddBotPageCell.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/9.
//

import UIKit
import LarkUIKit
import EENavigator
import LarkExtensions
import LarkSDKInterface
import SnapKit
import LKCommonsLogging
import UniverseDesignTheme
/// 「添加机器人」页面的单个Cell
/// 支持「添加」或「获取」功能
class AddBotPageCell: UITableViewCell {
    static let logger = Logger.oplog(AddBotPageCell.self, category: GroupBotDefines.groupBotLogCategory)
    /// 依赖的viewModel
    private var viewModel: AddBotPageCellViewModel?
    /// cell 配置
    struct CellConfig {
        static let cellHeight: CGFloat = 68.0
        static let cellID: String = "AddBotPageCell"
    }
    /// 应用图标size
    static let logoEdge: CGFloat = 48.0
    static let logoSize = CGSize(width: logoEdge, height: logoEdge)
    /// 操作按钮的宽度
    static let buttonWidth: CGFloat = 60
    static let buttonInset: CGFloat = 8.0
    var onButtonTap: ((AddBotPageCellViewModel) -> Void)?
    // MARK: 视图组件
    /// 分割线
    private lazy var splitLine: UIView = {
        let splitView = UIView()
        splitView.backgroundColor = UIColor.ud.lineDividerDefault
        return splitView
    }()
    var splitLeftEqualToSuperviewConstraint: Constraint?
    var splitLeftEqualToTitleLabelConstraint: Constraint?

    static let titleNormalColor = UIColor.ud.textTitle
    static let viewHighlightColor = UIColor.ud.primaryContentDefault
    static let descriptionNormalColor = UIColor.ud.textPlaceholder

    /// Item的图标
    private lazy var logoView: UIImageView = {
        let logoView = UIImageView()
        logoView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        logoView.layer.cornerRadius = 8.0
        logoView.clipsToBounds = true
        logoView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.10).cgColor
        logoView.layer.borderWidth = 0.8
        logoView.ud.setMaskView()
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = Self.titleNormalColor
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// Cell的描述
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14.0)
        label.textColor = Self.descriptionNormalColor
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// Cell的操作按钮
    private lazy var operateButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1
        button.layer.borderColor = Self.viewHighlightColor.cgColor
        button.setTitleColor(Self.viewHighlightColor, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.font = .systemFont(ofSize: 14.0)
        button.addTarget(self, action: #selector(onBtnTouched(sender:)), for: .touchDown)
        button.addTarget(self, action: #selector(onBtnCancelled(sender:)), for: .touchCancel)
        button.addTarget(self, action: #selector(onBtnCancelled(sender:)), for: .touchDragExit)
        button.addTarget(self, action: #selector(onBtnClicked(sender:)), for: .touchUpInside)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraint()
        selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 视图刷新
    /// - Parameters:
    ///   - bizScene: 业务场景
    ///   - model: viewModel
    func refresh(
        viewModel: AddBotPageCellViewModel,
        isLastCellInSection: Bool,
        searchText: String,
        buttonEvent: ((AddBotPageCellViewModel) -> Void)?
    ) {
        self.viewModel = viewModel
        self.onButtonTap = buttonEvent
        logoView.bt.setLarkImage(with: .avatar(key:  viewModel.data.avatar?.key ?? "", entityID: viewModel.botImageEntityID ?? "", params: .init(sizeType: .size(Self.logoEdge))))
        /// 高亮搜索词
        let title = viewModel.getTitleText()
        if !searchText.isEmpty {
            titleLabel.attributedText = title.lu.stringWithHighlight(
                highlightText: searchText,
                highlightColor: Self.viewHighlightColor,
                normalColor: Self.titleNormalColor)
        } else {
            titleLabel.text = title
        }
        let description = viewModel.getDescText()
        if !searchText.isEmpty {
            descriptionLabel.attributedText = description.lu.stringWithHighlight(
                highlightText: searchText,
                highlightColor: Self.viewHighlightColor,
                normalColor: Self.descriptionNormalColor)
        } else {
            descriptionLabel.text = title
        }

        let text = viewModel.getButtonTitle()
        operateButton.setTitle(text, for: .normal)
        // 针对「已添加」状态，禁用按钮
        let disabled = viewModel.isAdded
        operateButton.isEnabled = !disabled
        let buttonColor = disabled ? UIColor.ud.textDisable : Self.viewHighlightColor
        operateButton.layer.borderColor = buttonColor.cgColor
        operateButton.setTitleColor(buttonColor, for: .normal)
        updateViewConstraints(isLastCellInSection: isLastCellInSection)
    }

    @objc
    private func onBtnTouched(sender: UIButton) {
        sender.backgroundColor = UIColor.ud.udtokenBtnSeBgPriPressed
    }

    @objc
    private func onBtnCancelled(sender: UIButton) {
        sender.backgroundColor = UIColor.ud.bgBody
    }

    @objc
    private func onBtnClicked(sender: UIButton) {
        sender.backgroundColor = UIColor.ud.bgBody
        guard let model = viewModel else {
            Self.logger.error("on button tapped, but viewModel is empty")
            return
        }
        onButtonTap?(model)
    }
}

// MARK: 视图展示相关
extension AddBotPageCell {
    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        selectedBackgroundView = BaseCellSelectView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillPressed
        contentView.addSubview(logoView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(operateButton)
        contentView.addSubview(splitLine)
    }

    /// layout constraint
    private func setupConstraint() {
        logoView.snp.makeConstraints { make in
            make.size.equalTo(Self.logoSize)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoView.snp.top).offset(3)
            make.left.equalTo(logoView.snp.right).offset(12)
            make.right.equalTo(operateButton.snp.left).offset(-12)
        }
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.right.equalTo(operateButton.snp.left).offset(-12)
        }
        splitLine.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            splitLeftEqualToSuperviewConstraint = make.left.equalToSuperview().constraint
            splitLeftEqualToSuperviewConstraint?.isActive = false
            splitLeftEqualToTitleLabelConstraint = make.left.equalTo(titleLabel.snp.left).constraint
        }
        operateButton.snp.makeConstraints { make in
            make.height.equalTo(28)
            make.width.equalTo(Self.buttonWidth)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
        }
    }

    private func updateViewConstraints(isLastCellInSection: Bool) {
        operateButton.isHidden = false
        operateButton.snp.updateConstraints { make in
            make.width.equalTo(max(operateButton.intrinsicContentSize.width + Self.buttonInset * 2, Self.buttonWidth))
        }
        if isLastCellInSection {
            splitLeftEqualToSuperviewConstraint?.isActive = true
            splitLeftEqualToTitleLabelConstraint?.isActive = false
        } else {
            splitLeftEqualToSuperviewConstraint?.isActive = false
            splitLeftEqualToTitleLabelConstraint?.isActive = true
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setChoosed(highlighted)
    }

    private func setChoosed(_ choosed: Bool) {
        if choosed {
            self.backgroundColor = UIColor.ud.fillPressed
            self.selectedBackgroundView = UIImageView(image: UIImage.imageWithColor(UIColor.ud.fillPressed))
        } else {
            self.backgroundColor = UIColor.ud.bgBody
            self.selectedBackgroundView = UIImageView(image: UIImage.imageWithColor(UIColor.ud.bgBody))
        }
    }
}
