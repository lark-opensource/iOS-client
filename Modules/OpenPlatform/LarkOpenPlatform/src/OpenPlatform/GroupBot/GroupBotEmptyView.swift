//
//  GroupBotEmptyView.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/26.
//

import LarkUIKit
import EENavigator
import Swinject
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignEmpty
import LarkFeatureGating
import LarkContainer

/// 群机器人业务场景
enum GroupBotBizScene: String {
    /// 群机器人列表
    case groupBotList
    /// 添加机器人
    case addBot
}

/// 群机器人相关空态页
class GroupBotEmptyView: UIView, UITextViewDelegate {
    @FeatureGating("suite_help_service_message") var showBots: Bool
    private let bizScene: GroupBotBizScene
    /// 是否外部群
    private let isCrossTenant: Bool
    private let resolver: UserResolver

    private lazy var configProvider = GroupBotConfigProvider(resolver: resolver)

    /// 布局占位视图
    let placeholdEmtpyView = UIView()
    /// 无机器人icon
    let img: UIImageView = {
        let img = UIImageView()
        img.image = UDEmptyType.platformAddRobot1.defaultImage()
        return img
    }()
    /// tips
    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.textAlignment = .center
        let tip: String
        switch bizScene {
        case .addBot:
            tip = BundleI18n.GroupBot.Lark_GroupBot_NoBot
        case .groupBotList:
            if isCrossTenant {
                tip = BundleI18n.GroupBot.Lark_GroupBot_ExtnlGroupNoBotMsg
            } else {
                tip = BundleI18n.GroupBot.Lark_GroupBot_MobileDescription
            }
        }
        label.text = tip
        return label
    }()
    /// helper
    lazy var helpButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.setTitle(BundleI18n.GroupBot.Lark_GroupBot_MobileUsage, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.addTarget(self, action: #selector(onButtonClicked), for: .touchUpInside)
        return btn
    }()
    var helpURL: URL?
    weak var fromVC: UIViewController?

    init(frame: CGRect, bizScene: GroupBotBizScene, isCrossTenant: Bool, resolver: UserResolver, fromVC: UIViewController?) {
        self.resolver = resolver
        self.bizScene = bizScene
        self.isCrossTenant = isCrossTenant
        self.fromVC = fromVC
        super.init(frame: frame)
        setupViews()
        setupConstraint()
        if showBots {
            configProvider.fetchGroupBotHelpURL { [weak self] helpURL in
                self?.updateViews(helpURL: helpURL)
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(placeholdEmtpyView)
        addSubview(img)
        addSubview(tipLabel)
        addSubview(helpButton)
        // 帮助按钮初始状态设置为隐藏，待判断有帮助文档URL时显示
        helpButton.isHidden = true
    }

    private func setupConstraint() {
        placeholdEmtpyView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.3)
        }
        img.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalTo(placeholdEmtpyView.snp.bottom)
        }
        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(img.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(58)
            make.right.equalToSuperview().offset(-58)
        }
        helpButton.snp.makeConstraints { make in
            make.top.equalTo(tipLabel.snp.bottom).offset(6)
            make.centerX.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(58)
            make.right.equalToSuperview().offset(-58)
        }
    }

    @objc
    private func onButtonClicked() {
        guard let helpURL = helpURL, let fromVC = fromVC else {
            return
        }
        self.resolver.navigator.push(helpURL, from: fromVC)
    }

    func updateViews(helpURL: URL?) {
        helpButton.isHidden = (helpURL == nil)
        self.helpURL = helpURL
    }
}

/// 机器人导索页-加载页面
class GroupBotLoadingView: UIView {
    /// 要显示的cell数量
    private var loadingCellNum: Int
    init(frame: CGRect, cellNum: Int) {
        self.loadingCellNum = cellNum
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        var cellMargin: CGFloat = 0.0
        for _ in 0..<loadingCellNum {
            let cell = GroupBotLoadingCellView()
            addSubview(cell)
            cell.snp.makeConstraints { (make) in
                make.height.equalTo(GroupBotLoadingCellView.height)
                make.top.equalToSuperview().offset(cellMargin)
                make.centerX.width.equalToSuperview()
            }
            cellMargin += GroupBotLoadingCellView.height
        }
    }
}

class GroupBotLoadingCellView: UIView {
    /// cell高度
    static let height: CGFloat = 76.0
    /// 相关颜色
    private let startColor = UIColor.ud.N200.withAlphaComponent(0.6) & UIColor.ud.rgb(0xF0F0F0).withAlphaComponent(0.05)
    private let endColor = UIColor.ud.N200 & UIColor.ud.rgb(0xF0F0F0).withAlphaComponent(0.08)
    /// Item的图标
    private lazy var logoView: GradientBackgroudView = {
        let logoView = GradientBackgroudView(gradientStartColor: startColor, gradientEndColor: endColor)
        logoView.setCornerRedius(redius: 8.0)
        return logoView
    }()
    /// Cell的标题
    private lazy var titleLabel: GradientBackgroudView = {
        let label = GradientBackgroudView(gradientStartColor: startColor, gradientEndColor: endColor)
        label.setCornerRedius(redius: 2)
        return label
    }()
    /// Cell的描述
    private lazy var descLabel: GradientBackgroudView = {
        let label = GradientBackgroudView(gradientStartColor: startColor, gradientEndColor: endColor)
        label.setCornerRedius(redius: 2)
        return label
    }()
    /// 分割线
    private lazy var deviderLine: UIView = {
        let deviderLine = UIView()
        deviderLine.backgroundColor = UIColor.ud.lineDividerDefault
        return deviderLine
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraint()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// view composition
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(logoView)
        addSubview(titleLabel)
        addSubview(descLabel)
        addSubview(deviderLine)
    }

    /// layout constraint
    private func setupConstraint() {
        logoView.snp.makeConstraints { (make) in
            make.size.equalTo(GroupBotListPageCell.logoSize)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(logoView.snp.top).offset(4)
            make.left.equalTo(logoView.snp.right).offset(12)
            make.width.equalTo(80)
            make.height.equalTo(16)
        }
        descLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.height.equalTo(14)
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
            make.right.equalToSuperview().offset(-16)
        }
        deviderLine.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.bottom.right.equalToSuperview()
            make.left.equalTo(descLabel.snp.left)
        }
    }
}
