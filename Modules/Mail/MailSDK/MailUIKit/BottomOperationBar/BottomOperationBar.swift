//
//  BottomOperationBar.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/11/19.
//

import Foundation
import SnapKit
import LarkInteraction
import LarkGuideUI
import UniverseDesignIcon

protocol BottomOperationBarProtocol {
    init(actionItems: [MailActionItem], showHeaderLine: Bool, guideService: GuideServiceProxy?, isFeed: Bool)
    func updateActionItems(_ newActionItems: [MailActionItem])
    func updateActionItems(_ newActionItems: [MailActionItem], newProgress: CGFloat)
    func toggleSearchMode(_ show: Bool)

    var searchRightButton: UIButton? { get }
    var searchLeftButton: UIButton? { get }

    var actionItemsCount: Int { get }
    var isInSearchMode: Bool { get }
}

class BottomOperationBar: UIView, BottomOperationBarProtocol {
    private var actionItems: [MailActionItem] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let delta = self.actionItems.count - self.itemViews.count
                if delta < 0 && self.itemViews.count >= abs(delta) {
                    let dropViews = self.itemViews.suffix(abs(delta))
                    dropViews.forEach({ $0.removeFromSuperview() })
                    self.itemViews.removeLast(abs(delta))
                }
                // update current and insert
                for (i, item) in self.actionItems.enumerated() {
                    if i < self.itemViews.count {
                        self.itemViews[i].actionItem = item
                    } else {
                        if !self.isFeed {
                            let newItem = BottomOperationItemView(actionItem: item, guideService: self.guideService)
                            self.itemViews.append(newItem)
                        }
                    }
                }
                self.setupViews()
            }
        }
    }
    private var isFeed: Bool
    private var itemViews: [BottomOperationItemView] = []
    private let showHeaderLine: Bool
    private var headerLine: UIView?
    private let containerView = UIView()
    private lazy var operationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    private(set) var searchRightButton: UIButton?
    private(set) var searchLeftButton: UIButton?
    private lazy var searchOperationView: UIView = {
        // containerView
        let searchView = UIView()
        let topShadowView = UIView()
        let containerView = UIView()
        searchView.addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        containerView.layer.masksToBounds = false
        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.layer.ud.setShadow(type: .s3Up)
        
        // left & right button
        let rightButton = UIButton()
        let leftButton = UIButton()
        containerView.addSubview(rightButton)
        containerView.addSubview(leftButton)
        rightButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.width.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
        leftButton.snp.makeConstraints { (make) in
            make.right.equalTo(rightButton.snp.left).offset(-20)
            make.width.height.equalTo(36)
            make.centerY.equalToSuperview()
        }
        let rightIcon = UDIcon.rightOutlined
        rightButton.setImage(rightIcon.withRenderingMode(.alwaysTemplate).ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        rightButton.setImage(rightIcon.withRenderingMode(.alwaysTemplate).ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)

        let leftIcon = UDIcon.leftOutlined
        leftButton.setImage(leftIcon.withRenderingMode(.alwaysTemplate).ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        leftButton.setImage(leftIcon.withRenderingMode(.alwaysTemplate).ud.withTintColor(UIColor.ud.iconDisabled), for: .disabled)

        leftButton.isEnabled = false
        rightButton.isEnabled = false
        searchRightButton = rightButton
        searchLeftButton = leftButton
        return searchView
    }()

    var actionItemsCount: Int {
        return actionItems.count
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    private var guideService: GuideServiceProxy?
    
    required init(actionItems: [MailActionItem], showHeaderLine: Bool, guideService: GuideServiceProxy?, isFeed: Bool = false) {
        self.isFeed = isFeed
        self.actionItems = actionItems
        self.guideService = guideService
        self.itemViews = actionItems.map({ BottomOperationItemView(actionItem: $0, guideService: guideService) })
        self.showHeaderLine = showHeaderLine
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        setupViews()
    }

    private func setupViews() {
        if containerView.superview == nil {
            addSubview(containerView)
            containerView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            containerView.addSubview(operationStackView)
            operationStackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guard itemViews.count > 0 else { return }

        for itemView in itemViews {
            if !operationStackView.subviews.contains(itemView) {
                operationStackView.addArrangedSubview(itemView)
                itemView.snp.makeConstraints { make in
                    make.top.bottom.equalToSuperview()
                }
            }
        }

        if showHeaderLine {
            if let headerLine = headerLine, containerView.subviews.contains(headerLine) {
                // not need to add
                bringSubviewToFront(headerLine)
            } else {
                let line = UIView()
                line.backgroundColor = UIColor.ud.lineDividerDefault
                containerView.addSubview(line)
                line.snp.makeConstraints { (make) in
                    make.left.top.right.equalToSuperview()
                    make.height.equalTo(0.5)
                }
                headerLine = line
            }
        } else {
            headerLine?.removeFromSuperview()
            headerLine = nil
        }
    }

    func updateActionItems(_ newActionItems: [MailActionItem]) {
        actionItems = newActionItems
    }

    func updateActionItems(_ newActionItems: [MailActionItem], newProgress: CGFloat) {
        updateActionItems(newActionItems)
    }

    private(set) var isInSearchMode: Bool = false

    func toggleSearchMode(_ show: Bool) {
        isInSearchMode = show
        if searchOperationView.superview == nil {
            addSubview(searchOperationView)
        }
        searchOperationView.isHidden = false
        if show {
            searchOperationView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        } else {
            UIView.animate(withDuration: timeIntvl.short) {
                self.searchOperationView.snp.remakeConstraints { (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.height.equalTo(0)
                }
                self.searchOperationView.superview?.layoutIfNeeded()
            } completion: { (_) in
                self.searchOperationView.isHidden = true
            }

        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BottomOperationItemView: UIButton {
    var actionItem: MailActionItem {
        didSet {
            iconView.image = actionItem.icon
            textLabel.text = actionItem.title
        }
    }
    private let iconView = UIImageView()
    private let textLabel = UILabel()
    private let containerView = UIView()

    private static let rightIconSize = CGSize(width: 20, height: 20)
    private static let belowIconSize = CGSize(width: 20, height: 20)
    private static let rightFont = UIFont.systemFont(ofSize: 16)
    private static let belowFont = UIFont.systemFont(ofSize: 10)
    private static let spacing: CGFloat = 4
    private var titleFont: UIFont {
        return BottomOperationItemView.belowFont
    }
    private var iconSize: CGSize {
        return BottomOperationItemView.belowIconSize
    }

    private var guideService: GuideServiceProxy?

    init(actionItem: MailActionItem, guideService: GuideServiceProxy?) {
        self.actionItem = actionItem
        self.guideService = guideService
        super.init(frame: .zero)
        setupViews()
        addTarget(self, action: #selector(self.handleTap), for: .touchUpInside)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                        return (CGSize(width: min(self.frame.width - 8, 150), height: self.frame.height - 8), 8)
                    })
                )
            )
            self.addLKInteraction(pointer)
        }
        if actionItem.title == BundleI18n.MailSDK.Mail_SharetoChat_MenuItem {
            let delayTime: Double = 0.2
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                self.showOnboardingViewIfNeed()
            }
        }
    }

    func showOnboardingViewIfNeed() {
        let guideKey = "all_email_feedread"
        // 预加载会使得有多个 shareToChat，但只能出现一个 onboard，用当前是否有 onboard 正在展示来限制下
        guard guideService?.guideService?.checkIsCurrentGuideShowing() == false else { return }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(self))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_Share_ShareMailGudingTitle, detail: BundleI18n.MailSDK.Mail_Share_ShareEmailOnboardingMobileDesc())
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)
        let bubbleConfig = SingleBubbleConfig(bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor, textConfig: textConfig), maskConfig: maskConfig)
        guideService?.guideService?.showBubbleGuideIfNeeded(
            guideKey: guideKey,
            bubbleType: .single(bubbleConfig),
            dismissHandler: nil,
            didAppearHandler: nil,
            willAppearHandler: nil)
    }

    @objc
    private func handleTap() {
        actionItem.actionCallBack(self)
    }

    private func setupViews() {
        containerView.addSubview(iconView)
        containerView.addSubview(textLabel)
        addSubview(containerView)

        iconView.image = actionItem.icon
        iconView.tintColor = isEnabled ? UIColor.ud.iconN1 : UIColor.ud.iconDisabled
        textLabel.font = titleFont
        textLabel.text = actionItem.title
        textLabel.textColor = UIColor.ud.textTitle
        textLabel.lineBreakMode = .byTruncatingTail

        containerView.isUserInteractionEnabled = false
        containerView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview().offset(BottomOperationItemView.spacing)
            make.center.equalToSuperview()
        }

        textLabel.font = titleFont
        if !containerView.subviews.contains(textLabel) {
            containerView.addSubview(textLabel)
        }

        textLabel.textAlignment = .center
        iconView.snp.remakeConstraints { (make) in
            make.size.equalTo(iconSize)
            make.centerX.top.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }
        textLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(4)
            make.centerX.bottom.equalToSuperview()
            make.height.equalTo(13)
            make.left.greaterThanOrEqualToSuperview().offset(4)
            make.width.lessThanOrEqualTo(142)
        }
    }

    override var isEnabled: Bool {
        didSet {
            iconView.tintColor = isEnabled ? UIColor.ud.iconN1 : UIColor.ud.iconDisabled
            layoutIfNeeded()
            setNeedsLayout()
        }
    }

//    override var isHighlighted: Bool {
//        didSet {
//            self.textLabel.textColor = isHighlighted ? UIColor.ud.udtokenBtnTextBgNeutralHover : UIColor.ud.bgBody
//        }
//    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
