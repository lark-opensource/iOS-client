//
//  MoreAppOnboardingViewController.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/7.
//

import RichLabel
import UIKit
import LarkUIKit
import EENavigator
import RxSwift
import LKCommonsLogging
import Swinject
import RoundedHUD
import LarkOPInterface
import UniverseDesignEmpty

/// Message Action和加号菜单导索页Boarding引导
/// 上下左右安全距离都是36，内容部分高度自适应，如果显示不全，中间部分可滚动
/// 文字显示不固定行数，高度自适应
class MoreAppOnboardingModalController: UIViewController {
    private static let containerVerticalInset: CGFloat = 36.0
    private let backgroundView: UIView = UIView()
    private lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        label.text = isMessageActionScene ? BundleI18n.MessageAction.Lark_OpenPlatform_ScOnboardingMsgTtl : BundleI18n.MessageAction.Lark_OpenPlatform_InputScOnboardingMsgTtl
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var middleScrollView: UIScrollView = {
        return UIScrollView()
    }()
    private lazy var middleContentView: UIView = {
        return UIView()
    }()
    private lazy var firstImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private lazy var firstTitleLabel: UILabel = {
        let label = Self.createTitleLabel()
        label.text = isMessageActionScene ? BundleI18n.MessageAction.Lark_OpenPlatform_ScOnboardingMsgDesc1 : BundleI18n.MessageAction.Lark_OpenPlatform_InputScOnboardingMsg1
        return label
    }()
    private lazy var firstDescriptionLabel: UILabel = {
        let text = isMessageActionScene ? BundleI18n.MessageAction.Lark_OpenPlatform_ScOnboardingMsg2 : BundleI18n.MessageAction.Lark_OpenPlatform_InputScOnboardingMsg2
        let label = Self.createDescriptionLabel(text: text)
        return label
    }()
    private lazy var secondImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDEmptyType.platformPlusMenu.defaultImage()
        return imageView
    }()
    private lazy var secondTitleLabel: UILabel = {
        let label = Self.createTitleLabel()
        label.text = isMessageActionScene ? BundleI18n.MessageAction.Lark_OpenPlatform_ScOnboardingMsgDesc3 : BundleI18n.MessageAction.Lark_OpenPlatform_InputScOnboardingMsg3
        return label
    }()
    private lazy var secondDescriptionLabel: UILabel = {
        let text = isMessageActionScene ? BundleI18n.MessageAction.Lark_OpenPlatform_ScMblOnboardingMsgDesc4 : BundleI18n.MessageAction.Lark_OpenPlatform_InputScOnboardingMsg4
        let label = Self.createDescriptionLabel(text: text)
        return label
    }()
    private var isMessageActionScene: Bool {
        return bizScene == .msgAction
    }
    private static func createTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 0
        return label
    }
    private static func createDescriptionLabel(text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = createDescriptionLabelAttributedString(text: text)
        return label
    }
    private static func createDescriptionLabelAttributedString(text: String) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 22
        style.maximumLineHeight = 22
        style.lineBreakMode = .byTruncatingTail
        style.alignment = .left
        let contentAttributeStr = NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: UIColor.ud.textCaption,
                .font: UIFont.systemFont(ofSize: 14.0),
                .paragraphStyle: style
            ]
        )
        return contentAttributeStr
    }
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()
    private lazy var dismissBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.MessageAction.Lark_OpenPlatform_InputScContinueBttn, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        button.setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.fillPressed), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return button
    }()

    private let transition: DimmingTransition

    private let bizScene: BizScene
    private let dismissCompletion: (() -> Void)?

    public init(bizScene: BizScene, dismissCompletion: (() -> Void)? = nil) {
        self.bizScene = bizScene
        self.transition = DimmingTransition()
        self.dismissCompletion = dismissCompletion
        super.init(nibName: nil, bundle: nil)
        transitioningDelegate = transition
        modalPresentationStyle = .custom
        switch bizScene {
        case .addMenu:
            firstImageView.image = UDEmptyType.platformMessageAction2.defaultImage()
        case .msgAction:
            firstImageView.image = UDEmptyType.platformMessageAction1.defaultImage()
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    func setupViews() {
        view.backgroundColor = .clear
        view.addSubview(container)

        let containerWidth = 303
        let middleScrollViewHorizontalInset = 20
        let horizontalInset = 20
        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(containerWidth)
        }

        container.addSubview(titleLabel)
        container.addSubview(middleScrollView)
        container.addSubview(lineView)
        container.addSubview(dismissBtn)

        let titelLabelFitHeight = titleLabel.sizeThatFits(CGSize(width: containerWidth - 2 * middleScrollViewHorizontalInset, height: Int.max)).height
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(horizontalInset)
            make.top.equalToSuperview().offset(24)
            make.height.equalTo(titelLabelFitHeight)
        }

        dismissBtn.addTarget(self, action: #selector(hide), for: .touchUpInside)
        dismissBtn.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        lineView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalTo(dismissBtn.snp.top)
        }

        middleScrollView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(middleScrollViewHorizontalInset)
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.bottom.equalTo(lineView.snp.top).offset(-24)
        }
        middleScrollView.addSubview(middleContentView)
        middleContentView.addSubview(firstImageView)
        let firstTitleView = UIView()
        middleContentView.addSubview(firstTitleView)
        firstTitleView.addSubview(firstTitleLabel)
        firstTitleView.addSubview(firstDescriptionLabel)
        middleContentView.addSubview(secondImageView)
        let secondTitleView = UIView()
        middleContentView.addSubview(secondTitleView)
        secondTitleView.addSubview(secondTitleLabel)
        secondTitleView.addSubview(secondDescriptionLabel)

        let middleContentViewWidth = containerWidth - 2 * middleScrollViewHorizontalInset

        firstImageView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.left.equalToSuperview()
            make.centerY.equalTo(firstTitleView)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        firstTitleView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualToSuperview()
            make.right.equalToSuperview()
            make.left.equalTo(firstImageView.snp.right).offset(12)
        }
        firstTitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        firstDescriptionLabel.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(firstTitleLabel.snp.bottom).offset(4)
        }

        secondImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalTo(secondTitleView)
            make.size.equalTo(CGSize(width: 80, height: 80))
            make.bottom.lessThanOrEqualToSuperview()
        }
        secondTitleView.snp.makeConstraints { make in
            make.top.equalTo(firstTitleView.snp.bottom).offset(28)
            make.left.right.equalTo(firstTitleView)
            make.bottom.lessThanOrEqualToSuperview()
        }
        secondTitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        secondDescriptionLabel.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(secondTitleLabel.snp.bottom).offset(4)
        }

        // 限制scroll view最大height
        middleContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(middleContentViewWidth)
        }
        middleContentView.layoutIfNeeded()
        let middleContentViewFitHeight = middleContentView.sizeThatFits(CGSize(width: middleContentViewWidth, height: Int.max)).height

        guard let mainWindow = Navigator.shared.mainSceneWindow else {
            assertionFailure()
            return
        }
        let containerFitHeight = min(24 + titelLabelFitHeight + 24 + middleContentViewFitHeight + 74, mainWindow.op_height - Self.containerVerticalInset * 2)
        container.snp.makeConstraints { make in
            // 限制scroll view最大height
             make.height.equalTo(containerFitHeight)
        }
    }

    @objc
    func hide() {
        self.dismiss(animated: true, completion: nil)
        dismissCompletion?()
    }
}
