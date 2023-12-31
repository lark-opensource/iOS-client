//
//  TabAlertViewController.swift
//  LarkNavigation
//
//  Created by KT on 2020/2/18.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkAlertController
import LarkGuide
import UniverseDesignColor

// MARK: - 主导航变更弹窗
final class TabAlertViewController: UIViewController, BubbleActionDelegate, UIViewControllerTransitioningDelegate {
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
        self.guideService.setGuideIsShowing(isShow: false)
        self.dismissCallback?()
    }

    private let bubble: BubbleActionView
    private let offset: CGFloat
    private let guideService: GuideService
    private let maskColor: UIColor
    private let dismissCallback: (() -> Void)?

    init(title: String = BundleI18n.LarkNavigation.Lark_Legacy_NavigationUpdateTitle,
         text: String,
         offset: CGFloat,
         guideService: GuideService,
         maskColor: UIColor = BubbleActionView.Style.maskColor,
         dismissCallback: (() -> Void)? = nil) {
        self.offset = offset
        self.guideService = guideService
        self.maskColor = maskColor
        self.dismissCallback = dismissCallback
        self.bubble = BubbleActionView(title: title, text: text)

        super.init(nibName: nil, bundle: nil)
        self.setupViews()
        setupConstrains()
        self.guideService.setGuideIsShowing(isShow: true)
    }

    private func setupViews() {
        self.modalPresentationStyle = .custom
        transitioningDelegate = self
        self.view.backgroundColor = UIColor.clear
        self.view.addSubview(bubble)
        self.bubble.delegate = self
    }

    private func setupConstrains() {
        self.bubble.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.topMargin)
            make.bottom.equalToSuperview().offset(-offset
                - BubbleActionView.Layout.arrowSize.height
                                                    - BubbleActionView.Layout.arrowBottom).priority(.low)
        }
    }

    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.willTransition(to: newCollection, with: coordinator)
        self.dismiss()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented,
                                      presenting: presenting,
                                      offset: self.offset,
                                      maskColor: maskColor)
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return Animator(isPresenting: true)
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(isPresenting: false)
    }
}

// MARK: - 自定义Present
final class PresentationController: UIPresentationController {
    private let dimmingView = UIView()
    private let offset: CGFloat
    init(presentedViewController: UIViewController,
         presenting presentingViewController: UIViewController?,
         offset: CGFloat,
         maskColor: UIColor) {
        self.offset = offset
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = maskColor
    }

    // UI要求，这个弹窗的蒙层，下面的Tab要露出来
    private func setupConstrains() {
        self.dimmingView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-self.offset)
        }
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        self.setupConstrains()
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 })
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }
}

// MARK: - Present 动画
final class Animator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let key = isPresenting ? UITransitionContextViewControllerKey.to : UITransitionContextViewControllerKey.from
        let controller = transitionContext.viewController(forKey: key)!

        if isPresenting {
            transitionContext.containerView.addSubview(controller.view)
            controller.view.frame = transitionContext.finalFrame(for: controller)
        }

        controller.view.transform = isPresenting ? CGAffineTransform(scaleX: 0.3, y: 0.75) : CGAffineTransform.identity

        controller.view.alpha = isPresenting ? 0 : 1
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            controller.view.transform = self.isPresenting ? CGAffineTransform.identity :
                CGAffineTransform(scaleX: 0.3, y: 0.75)
            controller.view.alpha = self.isPresenting ? 1 : 0
        }, completion: { transitionContext.completeTransition($0) })
    }
}

// MARK: - 气泡Style
extension BubbleActionView {
    enum Layout {
        static let defaultWidth: CGFloat = 280.0
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 16.0, left: 20.0, bottom: 20.0, right: 20.0)

        static let detailTop: CGFloat = 8.0
        static let detailLineHeight: CGFloat = 21.0
        static let titleLineHeight: CGFloat = 24.0
        static let detailBottom: CGFloat = 13.0
        static let actionSize: CGSize = CGSize(width: 72.0, height: 32.0)

        static let actionButtonRadius: CGFloat = 6.0
        static let contentCornerRadius: CGFloat = 8.0
        static let arrowSize: CGSize = CGSize(width: 24.0, height: 12.0)
        static let arrowBottom: CGFloat = 12.0
    }
    enum Style {
        static let contenColor: UIColor = UIColor.ud.primaryFillHover

        static let textColor: UIColor = UIColor.ud.primaryOnPrimaryFill
        static let textLightColor: UIColor = UIColor.ud.colorfulBlue
        static let actionLightBackground: UIColor = UIColor.ud.primaryOnPrimaryFill

        static let titleFont: UIFont = .systemFont(ofSize: 16.0, weight: .medium)
        static let detailFont: UIFont = .systemFont(ofSize: 14.0, weight: .regular)
        static let actionFont: UIFont = .systemFont(ofSize: 14.0, weight: .medium)

        static let maskColor: UIColor = UIColor.ud.N1000.withAlphaComponent(0.3)
        static let shadowColor: UIColor = UIColor.ud.shadowPriLg.withAlphaComponent(0.3)
        static let shadowOffset: CGSize = CGSize(width: 0.0, height: 12.0)
        static let shadowBlur: CGFloat = 24.0
    }
}

// MARK: - Action
protocol BubbleActionDelegate: AnyObject {
    func dismiss()
}

// MARK: - 气泡View
final class BubbleActionView: UIView {
    private let arrowView = BubbleArrow()

    private let contentBackground = UIView(frame: .zero)
    private let contentView = UIView(frame: .zero)

    private let titleLabel = UILabel(frame: .zero)
    private let detailLabel = UILabel(frame: .zero)
    private let actionButton = UIButton(type: .custom)
    private let title: String
    private let detailText: String
    weak var delegate: BubbleActionDelegate?

    var intrinsicContentSizeExpectArrow: CGSize {
        var height: CGFloat = 0.0
        let textPrepareSize =
            CGSize(width: Layout.defaultWidth - Layout.contentInset.left - Layout.contentInset.right,
                   height: CGFloat.greatestFiniteMagnitude)
        height += Layout.contentInset.top
        height += titleLabel.sizeThatFits(textPrepareSize).height
        height += Layout.detailTop
        height += detailLabel.sizeThatFits(textPrepareSize).height
        height += Layout.detailBottom
        height += Layout.actionSize.height
        height += Layout.contentInset.bottom
        return CGSize(width: Layout.defaultWidth, height: height)
    }

    init(title: String, text: String) {
        self.title = title
        self.detailText = text
        super.init(frame: .zero)
        setupViews()
        setupLayouts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BubbleActionView {
    private func setupViews() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = Layout.detailLineHeight
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Style.detailFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: Style.textColor
        ]
        detailLabel.attributedText = NSAttributedString(string: self.detailText, attributes: attributes)
        detailLabel.numberOfLines = 0

        layer.ud.setShadowColor(Style.shadowColor)
        layer.shadowOffset = Style.shadowOffset
        layer.shadowRadius = Style.shadowBlur
        layer.shadowOpacity = 1

        addSubview(contentBackground)
        contentBackground.backgroundColor = Style.contenColor
        contentBackground.layer.cornerRadius = Layout.contentCornerRadius
        contentBackground.addSubview(contentView)

        contentView.addSubview(titleLabel)
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.minimumLineHeight = Layout.titleLineHeight
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: Style.titleFont,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: Style.textColor
        ]
        titleLabel.attributedText = NSAttributedString(string: title, attributes: titleAttributes)
        titleLabel.numberOfLines = 0

        contentView.addSubview(detailLabel)
        contentView.addSubview(actionButton)
        actionButton.setTitle(BundleI18n.LarkNavigation.Lark_Legacy_tabOK, for: .normal)
        actionButton.titleLabel?.font = Style.actionFont
        actionButton.setTitleColor(Style.textLightColor, for: .normal)
        actionButton.backgroundColor = Style.actionLightBackground
        actionButton.layer.cornerRadius = Layout.actionButtonRadius
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        addSubview(arrowView)
    }

    @objc
    private func actionButtonTapped() {
        self.delegate?.dismiss()
    }

    private func setupLayouts() {
        self.snp.makeConstraints { (make) in
            make.size.equalTo(self.intrinsicContentSizeExpectArrow)
        }
        contentBackground.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(Layout.contentInset)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
        }
        detailLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.detailTop)
        }
        actionButton.snp.makeConstraints { (make) in
            make.size.equalTo(Layout.actionSize)
            make.top.equalTo(self.detailLabel.snp.bottom).offset(Layout.detailBottom)
            make.right.equalToSuperview()
        }
        arrowView.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.arrowSize)
            make.centerX.equalToSuperview()
            make.top.equalTo(self.contentBackground.snp.bottom)
        }
    }
}

// MARK: - 箭头
final class BubbleArrow: UIView {
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    private var shapeLayer: CAShapeLayer {
        // swiftlint:disable:next force_cast
        return layer as! CAShapeLayer
    }

    private let path = UIBezierPath()
    override var intrinsicContentSize: CGSize {
        return BubbleActionView.Layout.arrowSize
    }

    init() {
        super.init(frame: .zero)
        shapeLayer.ud.setFillColor(BubbleActionView.Style.contenColor)
        updateCurrentDirection()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCurrentDirection()
    }

    private func updateCurrentDirection() {
        path.removeAllPoints()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(to: CGPoint(x: 6.5, y: 3), controlPoint: CGPoint(x: 4, y: 0))
        path.addLine(to: CGPoint(x: 10.2, y: 8))
        path.addQuadCurve(to: CGPoint(x: 13.8, y: 8), controlPoint: CGPoint(x: 12, y: 10))
        path.addLine(to: CGPoint(x: 17.5, y: 3))
        path.addQuadCurve(to: CGPoint(x: 24, y: 0), controlPoint: CGPoint(x: 20, y: 0))
        path.close()
        shapeLayer.path = path.cgPath
    }
}
