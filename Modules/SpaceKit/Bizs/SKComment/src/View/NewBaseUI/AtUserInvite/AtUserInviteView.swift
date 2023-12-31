//
//  AtUserInviteView.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/26.
// swiftlint:disable line_length

import SnapKit
import SKUIKit
import SKFoundation
import SKResource
import UniverseDesignNotice
import UniverseDesignIcon
import SpaceInterface
import SKCommon

public struct AtUserInviteViewConfig {
    var rightButtonText: String = ""
    var titleString: String = ""
    var docsInfo: DocsInfo?

    public static func congfigWithAt(_ at: AtInfo, docsInfo: DocsInfo?) -> AtUserInviteViewConfig {
        let userName = at.at
        let atInviteConfig = AtUserInviteViewConfig(rightButtonText: BundleI18n.SKResource.CreationMobile_mention_sharing_yes, titleString: BundleI18n.SKResource.CreationMobile_mention_sharing_message(userName), docsInfo: docsInfo)
        return atInviteConfig
    }
}

public protocol AtUserInviteViewDelegate: AnyObject {
    func clickConfirmButton(_ view: AtUserInviteView)
}


public final class AtUserInviteView: UIView {

    weak var popoverInVC: UIViewController?
    var atUserInfo: AtInfo?
    private var containerView: UIView = UIView()
    private var leftButton: UIButton = UIButton()
    private var rightButton: UIButton = UIButton()
    private var titleLabel: UILabel = UILabel()

    private var config: AtUserInviteViewConfig = AtUserInviteViewConfig()
    weak var delegate: AtUserInviteViewDelegate?
    private var isCornerStyle: Bool = false
    private var cornerMaskLayer: CAShapeLayer?
    private var lastLayoutViewSize: CGSize = .zero
    /// 竖屏下的约束
    var portraitScreenConstraints: [SnapKit.Constraint] = []
    /// 横屏下的约束
    var landscapeScreenConstraints: [SnapKit.Constraint] = []
    private lazy var permStatistics: PermissionStatistics? = {
        return PermissionStatistics.getReporterWith(docsInfo: config.docsInfo)
    }()

    public override func layoutSubviews() {
        super.layoutSubviews()
        let curSize = self.bounds.size
        if !curSize.equalTo(lastLayoutViewSize) {
            lastLayoutViewSize = curSize
            if isCornerStyle {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height / 2.0)).cgPath
                cornerMaskLayer?.frame = self.bounds
                let fieldPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
                cornerMaskLayer?.path = fieldPath.cgPath
                CATransaction.commit()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        setupSubviews()
    }

    func showWithConfig(_ config: AtUserInviteViewConfig, delegte: AtUserInviteViewDelegate?) {
        self.delegate = delegte
        self.config = config
        updateSubviewsContent()
        self.permStatistics?.reportPermissionShareAtPeopleView()
    }

    func addCornerStyle() {
        isCornerStyle = true
        self.layer.ud.setShadowColor(UIColor.ud.rgb(0x1F2329).withAlphaComponent(0.06))
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowRadius = 5

        let fieldPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.path = fieldPath.cgPath
        containerView.layer.mask = maskLayer
        containerView.layer.masksToBounds = true
        cornerMaskLayer = maskLayer
    }

    func setupSubviews() {
        containerView.backgroundColor = UIColor.ud.bgFloat
        addSubview(containerView)
        containerView.addSubview(leftButton)
        rightButton.addTarget(self, action: #selector(clickButton(_:)), for: .touchUpInside)
        containerView.addSubview(rightButton)
        containerView.addSubview(titleLabel)

        initLayout()
    }

    func updateSubviewsContent() {
        let image = UDIcon.infoColorful
        leftButton.setImage(image, for: .normal)

        rightButton.setTitle(config.rightButtonText, for: .normal)
        rightButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        rightButton.sizeToFit()

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = config.titleString
        titleLabel.numberOfLines = 3

        updateLayoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Layout
extension AtUserInviteView {
    private func initLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        leftButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(18)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        rightButton.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(38)
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftButton.snp.right).offset(10)
            make.right.equalTo(rightButton.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(17)
            make.bottom.equalToSuperview().offset(-17)
        }
    }

    private func updateLayoutIfNeeded() {
//        var leftOffsetOfTitle = 8
//        var rightOffsetOfTitle = leftOffsetOfTitle + 9
//
//        leftButton.snp.updateConstraints { (make) in
//            make.width.height.equalTo(18)
//        }
//        leftOffsetOfTitle += 18
//
//        rightOffsetOfTitle += 32 // 约定右边按钮只能是两个字的话
//
//        var frame = titleLabel.frame
//        frame.size.width = bounds.width - CGFloat(leftOffsetOfTitle + rightOffsetOfTitle)
//        titleLabel.frame = frame
//        titleLabel.sizeToFit()
    }
}

// MARK: 点击事件处理
extension AtUserInviteView {
    @objc
    func clickButton(_ sender: UIButton) {
        DocsLogger.info("AtUserInviteView, didClick")
        self.delegate?.clickConfirmButton(self)
        popoverInVC?.dismiss(animated: true, completion: nil)
        self.permStatistics?.reportPermissionShareAtPeopleClick(click: .confirm,
                                                                target: .noneTargetView,
                                                                isSendNotice: false)
    }
}

extension AtUserInviteView {    
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
        }
    }
}
