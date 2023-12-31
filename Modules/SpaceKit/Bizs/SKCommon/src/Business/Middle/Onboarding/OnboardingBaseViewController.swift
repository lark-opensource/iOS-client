//
// Created by duanxiaochen.7 on 2020/9/14.
// Affiliated with SKCommon.
//
// Description: 引导 view controller 公用逻辑

import SKFoundation
import SKUIKit
import SKResource
import LarkUIKit
import UniverseDesignColor
import UniverseDesignShadow

protocol PenetrableViewDelegate: AnyObject {

    func onTapTransparentArea() -> OnboardingStyle.TapBubbleOutsideBehavior

    func removeSelf(shouldSetFinished: Bool)
}

class OnboardingBaseViewController: UIViewController {

    // MARK: Configs

    let id: OnboardingID

    var disappearBehavior: OnboardingStyle.DisappearBehavior = .acknowledge

    var disappearStyle: OnboardingStyle.DisappearStyle

    weak var delegate: OnboardingDelegate?

    weak var dataSource: OnboardingDataSource?

    lazy var hostViewIsRegular: Bool = {
        dataSource?.onboardingHostViewController(for: id).isMyWindowRegularSize() ?? false
    }()

    lazy var maxBubbleWidth = hostViewIsRegular ? OnboardingStyle.maxRegularBubbleWidth : OnboardingStyle.maxCompactBubbleWidth

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return dataSource?.onboardingSupportedInterfaceOrientations(for: id) ?? [.portrait]
    }

    // MARK: Views

    lazy var bubble = UIView(frame: .zero).construct { it in
        it.backgroundColor = OnboardingStyle.bubbleColor
        it.layer.cornerRadius = OnboardingStyle.bubbleCornerRadius
        it.layer.ud.setShadow(type: .s4DownPri)
    }

    lazy var arrow = UIImageView(image: BundleResources.SKResource.Common.Onboarding.triangle_up.ud.withTintColor(OnboardingStyle.bubbleColor))

    lazy var imageBackgroundView = UIView().construct { it in
        it.backgroundColor = OnboardingStyle.cardImageBackgroundColor
    }

    lazy var imageView = UIImageView(image: dataSource?.onboardingImage(for: id)).construct { it in
        it.contentMode = .scaleAspectFit
    }

    lazy var lottieView = dataSource?.onboardingLottieView(for: id)?.construct { it in
        it.contentMode = .scaleAspectFit
        it.backgroundColor = .clear
    }

    lazy var titleLabel = UILabel(frame: .zero).construct { it in
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.attributedText = OnboardingPainter.generateTitleAttrString(titled: dataSource?.onboardingTitle(for: id)!,
                                                                      maxWidth: maxBubbleWidth - 2 * OnboardingStyle.bubblePaddingTopLeadingTrailing)
        it.textAlignment = .natural
    }

    lazy var hintLabel = UILabel(frame: .zero).construct { it in
        it.numberOfLines = 0
        it.lineBreakMode = .byWordWrapping
        it.attributedText = OnboardingPainter.generateHintAttrString(titled: dataSource?.onboardingHint(for: id),
                                                                     maxWidth: maxBubbleWidth - 2 * OnboardingStyle.bubblePaddingTopLeadingTrailing)
        it.textAlignment = .natural
    }

    init(id: OnboardingID, delegate: OnboardingDelegate?, dataSource: OnboardingDataSource?) {
        self.id = id
        self.disappearStyle = dataSource?.onboardingDisappearStyle(of: id) ?? .immediatelyAfterUserInteraction
        self.delegate = delegate
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        naviPopGestureRecognizerEnabled = true
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(pop))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        disappearBehavior = delegate?.onboardingWindowSizeWillChange(for: id) ?? .acknowledge
        disappearStyle = .immediatelyAfterUserInteraction
        super.viewWillTransition(to: size, with: coordinator)
        removeSelf()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent != nil {
            view.layer.zPosition = .greatestFiniteMagnitude
            for subview in view.subviews {
                subview.layer.zPosition = .greatestFiniteMagnitude
            }
            lottieView?.play()
        }
    }

    func attachBubbleToTargetRect(_ targetRect: CGRect?) {
        let hostViewBounds = dataSource?.onboardingHostViewController(for: id).view.bounds
        let designatedArrowDirection = dataSource?.onboardingArrowDirection(for: id)
        let (targetPoint, arrowDirection) = OnboardingPainter.determineTargetPoint(targetRect: targetRect,
                                                                                   hostViewBounds: hostViewBounds,
                                                                                   designatedPointingDirection: designatedArrowDirection)
        DocsLogger.onboardingDebug("\(id) 箭头 \(arrowDirection), 指向 \(targetPoint)")
        let arrowRotationMultiplier: Float = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight ? 1.0 : -1.0
        arrow.snp.removeConstraints()
        bubble.snp.removeConstraints()
        switch arrowDirection {
        case .targetBottomEdge:
            arrow.snp.makeConstraints { (make) in
                make.top.equalTo(targetPoint.y + OnboardingStyle.arrowTipOffsetFromTargetPoint)
                make.centerX.equalTo(view.snp.leading).offset(targetPoint.x)
                make.width.equalTo(OnboardingStyle.arrowSize.width)
                make.height.equalTo(OnboardingStyle.arrowSize.height)
            }
            bubble.snp.makeConstraints { (make) in
                make.top.equalTo(arrow.snp.bottom)
                make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.leading).offset(OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.trailing).offset(-OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.centerX.equalTo(arrow).priority(.medium)
                make.width.lessThanOrEqualTo(maxBubbleWidth).priority(.required)
            }
        case .targetTopEdge:
            arrow.image = arrow.image?.sk.rotate(radians: Float.pi)
            arrow.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.snp.top).offset(targetPoint.y - OnboardingStyle.arrowTipOffsetFromTargetPoint)
                make.centerX.equalTo(view.snp.leading).offset(targetPoint.x)
                make.width.equalTo(OnboardingStyle.arrowSize.width)
                make.height.equalTo(OnboardingStyle.arrowSize.height)
            }
            bubble.snp.makeConstraints { (make) in
                make.bottom.equalTo(arrow.snp.top)
                make.leading.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.leading).offset(OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.trailing).offset(-OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.centerX.equalTo(arrow).priority(.medium)
                make.width.lessThanOrEqualTo(maxBubbleWidth).priority(.required)
            }
        case .targetTrailingEdge:
            arrow.image = arrow.image?.sk.rotate(radians: Float.pi * -0.5 * arrowRotationMultiplier)
            arrow.snp.makeConstraints { (make) in
                make.leading.equalTo(targetPoint.x + OnboardingStyle.arrowTipOffsetFromTargetPoint)
                make.centerY.equalTo(view.snp.top).offset(targetPoint.y)
                make.width.equalTo(OnboardingStyle.arrowSize.height)
                make.height.equalTo(OnboardingStyle.arrowSize.width)
            }
            bubble.snp.makeConstraints { (make) in
                make.leading.equalTo(arrow.snp.trailing)
                make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.centerY.equalTo(arrow).priority(.medium)
                make.width.lessThanOrEqualTo(maxBubbleWidth).priority(.required)
            }
        case .targetLeadingEdge:
            arrow.image = arrow.image?.sk.rotate(radians: Float.pi * 0.5 * arrowRotationMultiplier)
            arrow.snp.makeConstraints { (make) in
                make.trailing.equalTo(view.snp.leading).offset(targetPoint.x - OnboardingStyle.arrowTipOffsetFromTargetPoint)
                make.centerY.equalTo(view.snp.top).offset(targetPoint.y)
                make.width.equalTo(OnboardingStyle.arrowSize.height)
                make.height.equalTo(OnboardingStyle.arrowSize.width)
            }
            bubble.snp.makeConstraints { (make) in
                make.trailing.equalTo(arrow.snp.leading)
                make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-OnboardingStyle.bubbleLayoutMargin).priority(.required)
                make.centerY.equalTo(arrow).priority(.medium)
                make.width.lessThanOrEqualTo(maxBubbleWidth).priority(.required)
            }
        }
    }

    @objc
    private func pop() {
        disappearStyle = .immediatelyAfterUserInteraction
        removeSelf(shouldSetFinished: false)
    }

    func onTapTransparentArea() -> OnboardingStyle.TapBubbleOutsideBehavior {
        disappearBehavior = delegate?.onboardingDidTapBubbleOutside(for: id) ?? .acknowledge
        return dataSource?.onboardingTapBubbleOutsideBehavior(of: id) ?? .disappearAndPenetrate
    }

    @objc
    func removeSelf(shouldSetFinished: Bool = true) {
        var disappearBehavior = self.disappearBehavior
        if shouldSetFinished {
            OnboardingSynchronizer.shared.setFinished(id)
        } else {
            disappearBehavior = .proceed
        }
        let id = self.id
        weak var delegate = self.delegate
        let nextID = dataSource?.onboardingNextID(for: id)
        OnboardingManager.shared.removeCurrentOnboardingView(disappearStyle: disappearStyle) {
            switch disappearBehavior {
            case .proceed:
                // 这里的时序和其他两个 case 不一样，代理方法 didTapBubbleOutside(for:) 在 hitTest 那一层调用，在该方法前已经执行完成
                OnboardingManager.shared.continueExecuting(expectedNext: nextID)
            case .acknowledge:
                delegate?.onboardingAcknowledge(id)
                OnboardingManager.shared.continueExecuting(expectedNext: nextID)
            case .skip:
                delegate?.onboardingSkip(id)
                OnboardingManager.shared.stopExecuting()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
