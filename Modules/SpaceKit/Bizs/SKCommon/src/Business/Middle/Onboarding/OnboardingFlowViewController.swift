//
// Created by duanxiaochen.7 on 2020/9/14.
// Affiliated with SKCommon.
//
// Description: 带按钮的气泡引导

import SKFoundation
import SKUIKit
import SKResource


class OnboardingFlowViewController: OnboardingBaseViewController, PenetrableViewDelegate {

    weak var flowDataSource: OnboardingFlowDataSources?

    init(id: OnboardingID, delegate: OnboardingDelegate?, dataSource: OnboardingFlowDataSources?) {
        flowDataSource = dataSource
        super.init(id: id, delegate: delegate, dataSource: dataSource)
    }

    private lazy var indexLabel = UILabel(frame: .zero).construct { it in
        it.backgroundColor = .clear
        it.font = OnboardingStyle.indexFont
        it.text = flowDataSource?.onboardingIndex(for: id)
        it.textColor = OnboardingStyle.indexColor
        it.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        it.textAlignment = .natural
    }

    private lazy var skipButton = UIButton().construct { it in
        it.backgroundColor = .clear
        it.setTitle(flowDataSource?.onboardingSkipText(for: id),
                    withFontSize: 14,
                    fontWeight: .medium,
                    singleColor: OnboardingStyle.skipTextColor,
                    forAllStates: [.normal, .highlighted, .selected, UIControl.State.selected.union(.highlighted)])
        it.titleLabel?.font = OnboardingStyle.skipTextFont
        it.hitTestEdgeInsets = OnboardingStyle.buttonHitTestInsets
        it.contentEdgeInsets = OnboardingStyle.flowButtonTextInsets
        it.addTarget(self, action: #selector(skipButtonAction), for: .touchUpInside)
        it.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        it.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
    }

    @objc
    func skipButtonAction() {
        if flowDataSource?.onboardingSkipText(for: id) != nil {
            disappearBehavior = .skip
            removeSelf()
        }
    }

    private lazy var ackButton = UIButton().construct { it in
        it.setTitle(flowDataSource?.onboardingAckText(for: id),
                    withFontSize: 14,
                    fontWeight: .medium,
                    singleColor: OnboardingStyle.bubbleColor,
                    forAllStates: [.normal, .highlighted, .selected, UIControl.State.selected.union(.highlighted)])
        it.titleLabel?.font = OnboardingStyle.flowAckTextFont
        it.hitTestEdgeInsets = OnboardingStyle.buttonHitTestInsets
        it.layer.cornerRadius = OnboardingStyle.buttonCornerRadius
        it.contentEdgeInsets = OnboardingStyle.flowButtonTextInsets
        it.backgroundColor = OnboardingStyle.ackButtonBackgroundColor
        it.addTarget(self, action: #selector(ackButtonAction), for: .touchUpInside)
        it.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        it.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
    }

    @objc
    func ackButtonAction() {
        disappearBehavior = .acknowledge
        removeSelf()
    }

    lazy var hollowConfiguration: (rect: CGRect, cornerRadius: CGFloat) =
        OnboardingPainter.generateHollow(withStyle: flowDataSource?.onboardingHollowStyle(for: id),
                                         rect: dataSource?.onboardingTargetRect(for: id),
                                         bleeding: flowDataSource?.onboardingBleeding(for: id))

    override func loadView() {
        if flowDataSource?.onboardingHasMask(for: id) == true {
            view = HollowedPenetrableMaskView(baseVC: self,
                                              maskColor: OnboardingStyle.maskColor,
                                              hollowRect: hollowConfiguration.rect,
                                              hollowCornerRadius: hollowConfiguration.cornerRadius)
        } else {
            view = PartiallyPenetrableView(baseVC: self,
                                           bubbleRectProvider: { [weak self] () -> CGRect in
                                            guard let self = self else { return .zero }
                                            return self.bubble.frame
                                           })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(bubble)
        view.addSubview(arrow)
        bubble.addSubview(ackButton)

        attachBubbleToTargetRect(hollowConfiguration.rect)

        var topAnchor = bubble.snp.top
        var graphView: UIView?
        if dataSource?.onboardingImage(for: id) != nil {
            graphView = imageView
        } else if let lottieView = lottieView {
            graphView = lottieView
        }
        if let graphView = graphView {
            bubble.addSubview(imageBackgroundView)
            bubble.addSubview(graphView)
            graphView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.trailing.equalToSuperview().offset(-OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.width.greaterThanOrEqualTo(OnboardingStyle.maxCompactBubbleWidth - 2 * OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.width.lessThanOrEqualTo(OnboardingStyle.maxRegularBubbleWidth - 2 * OnboardingStyle.bubblePaddingTopLeadingTrailing)
                let intrinsicSize = graphView.intrinsicContentSize
                DocsLogger.onboardingInfo("intrinsicSize: \(intrinsicSize)")
                var ratio: CGFloat = 0.5
                if intrinsicSize.height > 0.01,
                   intrinsicSize.width > 0.01 {
                   ratio = intrinsicSize.height / intrinsicSize.width
                }
                make.height.equalTo(graphView.snp.width).multipliedBy(ratio)
            }
            imageBackgroundView.snp.makeConstraints { make in
                make.edges.equalTo(graphView)
            }
            topAnchor = graphView.snp.bottom
        }

        bubble.addSubview(hintLabel)
        var hintTopPadding = OnboardingStyle.hintMarginTop
        var hintBottomPadding = OnboardingStyle.buttonPaddingTop1
        if dataSource?.onboardingTitle(for: id) != nil {
            bubble.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(topAnchor).offset(OnboardingStyle.titleMarginTop)
                make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.trailing.equalToSuperview().offset(-OnboardingStyle.bubblePaddingTopLeadingTrailing)
            }
            topAnchor = titleLabel.snp.bottom
            hintTopPadding = OnboardingStyle.titleHintSpacing
            hintBottomPadding = OnboardingStyle.buttonPaddingTop2
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(topAnchor).offset(hintTopPadding)
            make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.bubblePaddingTopLeadingTrailing)
            make.bottom.equalTo(ackButton.snp.top).offset(-hintBottomPadding)
        }

        ackButton.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(OnboardingStyle.buttonPaddingTop2)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.buttonPaddingTrailingBottom)
            make.bottom.equalToSuperview().offset(-OnboardingStyle.buttonPaddingTrailingBottom)
        }
        var indexTrailingAnchor = ackButton.snp.leading
        if flowDataSource?.onboardingSkipText(for: id) != nil {
            bubble.addSubview(skipButton)
            skipButton.snp.makeConstraints { make in
                make.trailing.equalTo(ackButton.snp.leading).offset(-OnboardingStyle.flowInterbuttonSpacing)
                make.centerY.equalTo(ackButton)
                make.height.equalTo(ackButton)
            }
            indexTrailingAnchor = skipButton.snp.leading
        }

        if flowDataSource?.onboardingIndex(for: id) != nil {
            bubble.addSubview(indexLabel)
            indexLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.centerY.equalTo(ackButton)
                make.trailing.equalTo(indexTrailingAnchor).offset(-OnboardingStyle.flowInterbuttonSpacing)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



private class HollowedPenetrableMaskView: UIView {

    weak var baseVC: PenetrableViewDelegate?

    let maskColor: UIColor

    let hollowRect: CGRect

    let hollowCornerRadius: CGFloat

    init(baseVC: PenetrableViewDelegate,
         maskColor: UIColor,
         hollowRect: CGRect,
         hollowCornerRadius: CGFloat) {
        self.baseVC = baseVC
        self.maskColor = maskColor
        self.hollowRect = hollowRect
        self.hollowCornerRadius = hollowCornerRadius
        super.init(frame: .zero)
        self.backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        guard UIGraphicsGetCurrentContext() != nil else { return }
        let boundPath = UIBezierPath(rect: self.bounds)
        let clipPath = UIBezierPath(roundedRect: hollowRect, cornerRadius: hollowCornerRadius)
        boundPath.append(clipPath.reversing())
        boundPath.usesEvenOddFillRule = false
        boundPath.addClip()
        maskColor.setFill()
        boundPath.fill()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.4, *) {
            if event?.type == .hover || event == nil {
                // iPad 外接键盘触控板上的接触、移动会导致频繁调用到这里，event?.type 是 hover 的类型。
                return super.hitTest(point, with: event)
            }
        }
        if hollowRect.contains(point) {
            let behavior = baseVC?.onTapTransparentArea() ?? .disappearAndPenetrate
            switch behavior {
            case .nothing:
                return super.hitTest(point, with: event)
            case .disappearAndPenetrate:
                baseVC?.removeSelf(shouldSetFinished: true)
                return nil
            case .disappearWithoutPenetration:
                baseVC?.removeSelf(shouldSetFinished: true)
                return super.hitTest(point, with: event)
            }
        } else {
            return super.hitTest(point, with: event)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private class PartiallyPenetrableView: UIView {

    weak var baseVC: PenetrableViewDelegate?

    let bubbleRectProvider: () -> CGRect

    init(baseVC: PenetrableViewDelegate,
         bubbleRectProvider: @escaping () -> CGRect) {
        self.baseVC = baseVC
        self.bubbleRectProvider = bubbleRectProvider
        super.init(frame: .zero)
        self.backgroundColor = .clear
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.4, *) {
            if event?.type == .hover || event == nil {
                // iPad 外接键盘触控板上的接触、移动会导致频繁调用到这里，event?.type 是 hover 的类型。
                return super.hitTest(point, with: event)
            }
        }
        if bubbleRectProvider().contains(point) {
            return super.hitTest(point, with: event)
        } else {
            let behavior = baseVC?.onTapTransparentArea() ?? .disappearAndPenetrate
            switch behavior {
            case .nothing:
                return super.hitTest(point, with: event)
            case .disappearAndPenetrate:
                baseVC?.removeSelf(shouldSetFinished: true)
                return nil
            case .disappearWithoutPenetration:
                baseVC?.removeSelf(shouldSetFinished: true)
                return super.hitTest(point, with: event)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
