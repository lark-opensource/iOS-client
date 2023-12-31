//
//  WPCategoryPageVIewCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/22.
//

import UIKit
import LarkUIKit
import UniverseDesignTag
import UniverseDesignFont
import LKCommonsLogging

/// 工作台-分类页面的单个Cell
final class WPCategoryPageViewCell: UITableViewCell {
    static let logger = Logger.log(WPCategoryPageViewCell.self)

    /// 依赖的viewModel
    private var viewModel: WPCategoryItemViewModel?
    /// cell 配置
    enum CellConfig {
        static let cellHeight: CGFloat = 76.0
        static let cellID: String = "AppCategoryCell"
    }
    /// tag字体大小
    let tagFontSize: CGFloat = 11.0
    /// 按钮宽度
    let btnMaxWidth: CGFloat = 110.0
    let btnMinWidth: CGFloat = 60.0
    let btnHorizontalInset: CGFloat = 8.0

    private static let maxTagWidth: CGFloat = 74.0

    // MARK: 视图组件
    /// 分割线
    private lazy var splitLine: UIView = {
        let splitView = UIView()
        splitView.backgroundColor = UIColor.ud.lineDividerDefault
        return splitView
    }()
    /// Item的图标
    private lazy var logoView: WPMaskImageView = {
        let logoView = WPMaskImageView()
        logoView.clipsToBounds = true
        logoView.sqRadius = WPUIConst.AvatarRadius.large
        logoView.sqBorder = WPUIConst.BorderW.pt1
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17.0)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// Cell的描述
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textPlaceholder
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// 共享应用Cell的应用来源
    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textPlaceholder
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    /// Cell的操作按钮
    private lazy var operateButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6
        button.layer.borderWidth = 1
        return button
    }()
    /// Cell的操作按钮的loadingr
    private lazy var loadingView: LoadingView = LoadingView(frame: .zero)
    /// Cell的标签
    private lazy var tagView: UDTag = {
        UDTag(text: "", textConfig: UDTagConfig.TextConfig())
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraint()
        operateButton.addTarget(self, action: #selector(onOperateClickEvent), for: .touchUpInside)
        operateButton.addTarget(self, action: #selector(onOperatePressEvent), for: .touchDown)
        operateButton.addTarget(self, action: #selector(onOperateCancelEvent), for: .touchUpOutside)
        if #available(iOS 13.0, *) {
            let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovering))
            operateButton.addGestureRecognizer(hover)
        }
        self.selectionStyle = .none
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// 视图刷新
    /// - Parameters:
    ///   - model: viewModel
    ///   - isHideSplit: 是否隐藏分割线
    func refresh(model: WPCategoryItemViewModel, isHideSplit: Bool, keyword: String? = nil) {
        self.viewModel = model
        let itemInfo = model.item
        logoView.bt.setLarkImage(
            with: .avatar(
                key: itemInfo.iconKey,
                entityID: "",
                params: .init(sizeType: .size(avatarSideL))
            )
        )
        titleLabel.text = nil
        titleLabel.attributedText = nil
        if let searchText = keyword {
            titleLabel.attributedText = WorkplaceTool.attributedText(
                text: itemInfo.name,
                withHitTerms: [searchText],
                highlightColor: UIColor.ud.primaryContentDefault
            )
        } else {
            titleLabel.text = itemInfo.name
        }
        tagView.wp_updateType(model.getNeedDisplayTagType())
        updateDescription()
        updateOperateButton()
        setOnStateChange()
        updateTagConstraint()
    }

    private func isSharedApp() -> Bool {
        if let isShared = viewModel?.item.isSharedByOtherOrganization,
           isShared,
           viewModel?.item.sharedSourceTenantInfo != nil {
            return true
        } else {
            return false
        }
    }

    /// 设置按钮按压态
    @objc
    private func onOperatePressEvent() {
        guard let state = self.viewModel?.state else {
            Self.logger.error("item viewModel is empty, no state")
            return
        }
        switch state {
        case .add, .get:
            operateButton.backgroundColor = UIColor.ud.udtokenBtnSeBgPriPressed
        case .alreadyAdd:
            operateButton.backgroundColor = UIColor.ud.udtokenBtnSeBgNeutralPressed
        case .addLoading, .removeLoading:
            return
        }
    }
    /// 设置按钮点击事件
    @objc
    private func onOperateClickEvent() {
        operateButton.backgroundColor = .clear
        Self.logger.info("user tap operate button in cell(\(String(describing: viewModel?.item.name)))")
        guard let modelInfo = viewModel, let clickCallback = modelInfo.operateButtonClick else {
            Self.logger.error("cell's viewModel is empty, tap event exit")
            return
        }
        if modelInfo.state != .alreadyAdd {
            clickCallback(modelInfo)
        }
    }

    @objc
    private func onOperateCancelEvent() {
        operateButton.backgroundColor = .clear
    }

    /// hover事件
    @available(iOS 13.0, *)
    @objc
    func hovering(_ recognizer: UIHoverGestureRecognizer) {
        guard let state = self.viewModel?.state else {
            Self.logger.error("item viewModel is empty, no state")
            return
        }
        switch recognizer.state {
        case .began, .changed:
            switch state {
            case .add, .get:
                operateButton.backgroundColor = UIColor.ud.udtokenBtnSeBgPriHover
            case .alreadyAdd:
                operateButton.backgroundColor = UIColor.ud.udtokenBtnSeBgNeutralHover
            case .addLoading, .removeLoading:
                return
            }
        case .ended, .cancelled:
            operateButton.backgroundColor = .clear
        default:
            operateButton.backgroundColor = .clear
        }
    }
    /// 设置VM状态切换的响应事件
    func setOnStateChange() {
        guard let modelInfo = viewModel else {
            Self.logger.error("cell's viewModel is empty, bind state change event failed")
            return
        }
        modelInfo.stateChangeCallback = { [weak self] in
            guard let self = self else {
                Self.logger.warn("WPCategoryPageViewCell stateChangeCallback but self released")
                return
            }
            self.updateOperateButton()
        }
    }
}

// MARK: 视图展示相关
extension WPCategoryPageViewCell {
    /// view composition
    private func setupViews() {
        // 不要分割线了，现在
        splitLine.isHidden = true
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(splitLine)
        contentView.addSubview(logoView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(sourceLabel)
        contentView.addSubview(tagView)
        contentView.addSubview(operateButton)
        operateButton.addSubview(loadingView)
    }

    /// layout constraint
    private func setupConstraint() {
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(WPUIConst.AvatarSize.middle)
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(logoView.snp.top)
            make.leading.equalTo(logoView.snp.trailing).offset(12)
            make.height.equalTo(24)
        }
        descLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.leading)
            make.top.equalTo(titleLabel.snp.bottom).offset(3)
            make.trailing.equalTo(operateButton.snp.leading).offset(-15)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        tagView.snp.makeConstraints { (make) in
            make.centerY.equalTo(titleLabel)
            make.height.equalTo(18)
            make.width.lessThanOrEqualTo(Self.maxTagWidth)
            make.trailing.lessThanOrEqualTo(operateButton.snp.leading).offset(-15)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
        splitLine.snp.makeConstraints { (make) in
            make.bottom.trailing.equalToSuperview()
            make.height.equalTo(0.5)
            make.leading.equalTo(titleLabel.snp.leading)
        }
        operateButton.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.width.equalTo(btnMinWidth)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        loadingView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16.0, height: 16.0))
            make.center.equalToSuperview()
        }
    }

    /// 刷新按钮样式
    private func updateOperateButton() {
        guard let state = self.viewModel?.state else {
            Self.logger.error("item viewModel is empty, update button state failed")
            return
        }
        switch state {
        case .add, .get:
            loadingView.isHidden = true
            operateButton.setTitle(state.getText(), for: .normal)
            operateButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            // font 使用 ud token 初始化
            // swiftlint:disable init_font_with_token
            operateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
            // swiftlint:enable init_font_with_token
            operateButton.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        case .alreadyAdd:
            loadingView.isHidden = true
            operateButton.setTitle(state.getText(), for: .normal)
            operateButton.setTitleColor(UIColor.ud.textDisabled, for: .normal)
            operateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14.0)
            operateButton.layer.ud.setBorderColor(.clear)
        case .addLoading, .removeLoading:
            operateButton.setTitle(nil, for: .normal)
            loadingView.isHidden = false
            loadingView.animationView.play()
            operateButton.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        }
        operateButton.snp.updateConstraints { (make) in
            make.width.equalTo(max(operateButton.intrinsicContentSize.width + btnHorizontalInset * 2, btnMinWidth))
        }
    }

    /// 设置Cell视图Tag约束（满足tag动态要求）
    private func updateTagConstraint() {
        if tagView.isHidden {
            tagView.snp.remakeConstraints { (make) in
                make.centerY.equalTo(titleLabel)
                make.height.equalTo(18)
                make.width.lessThanOrEqualTo(Self.maxTagWidth)
                make.leading.lessThanOrEqualTo(operateButton.snp.leading)
                make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            }
        } else {
            tagView.snp.remakeConstraints { (make) in
                make.centerY.equalTo(titleLabel)
                make.height.equalTo(18)
                make.width.lessThanOrEqualTo(Self.maxTagWidth)
                make.trailing.lessThanOrEqualTo(operateButton.snp.leading).offset(-12)
                make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            }
        }
    }

    /// 设置描述区域视图
    private func updateDescription() {
        if let itemInfo = viewModel?.item {
            if let desText = itemInfo.desc {
                descLabel.text = desText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if isSharedApp() {
                descLabel.numberOfLines = 1
                sourceLabel.isHidden = false
                sourceLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppShare_AppSource
                + (itemInfo.sharedSourceTenantInfo?.name ?? "")
                descLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(titleLabel.snp.leading)
                    make.top.equalTo(titleLabel.snp.bottom).offset(3)
                    make.trailing.equalTo(operateButton.snp.leading).offset(-15)
                    make.height.lessThanOrEqualTo(20)
                }
                sourceLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(titleLabel.snp.leading)
                    make.top.equalTo(descLabel.snp.bottom).offset(4)
                    make.trailing.equalTo(operateButton.snp.leading).offset(-15)
                    make.height.equalTo(20)
                    make.bottom.lessThanOrEqualToSuperview().offset(-12)
                }
            } else {
                descLabel.numberOfLines = 2
                sourceLabel.isHidden = true
                descLabel.snp.remakeConstraints { (make) in
                    make.leading.equalTo(titleLabel.snp.leading)
                    make.top.equalTo(titleLabel.snp.bottom).offset(3)
                    make.trailing.equalTo(operateButton.snp.leading).offset(-15)
                    make.height.lessThanOrEqualTo(39)
                    make.bottom.lessThanOrEqualToSuperview().offset(-12)
                }
                sourceLabel.snp.removeConstraints()
            }
        }
    }
}
