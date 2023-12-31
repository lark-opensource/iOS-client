//
// Created by duanxiaochen.7 on 2020/9/14.
// Affiliated with SKCommon.
//
// Description: 无按钮的气泡引导

import SKFoundation
import SKUIKit
import SKResource

class OnboardingTextViewController: OnboardingBaseViewController, PenetrableViewDelegate {

    override init(id: OnboardingID, delegate: OnboardingDelegate?, dataSource: OnboardingDataSource?) {
        super.init(id: id, delegate: delegate, dataSource: dataSource)
    }

    override func loadView() {
        view = PenetrableView(baseVC: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bubble.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        bubble.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        setupLayout()
        setupCustomizeGestureIfNeed()
    }

    private func setupLayout() {
        view.addSubview(bubble)
        view.addSubview(arrow)

        attachBubbleToTargetRect(dataSource?.onboardingTargetRect(for: id))

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
                make.height.lessThanOrEqualTo(graphView.snp.width).multipliedBy(0.75)
            }
            imageBackgroundView.snp.makeConstraints { make in
                make.edges.equalTo(graphView)
            }
            topAnchor = graphView.snp.bottom
        }

        bubble.addSubview(hintLabel)
        var hintTopPadding = OnboardingStyle.hintMarginTop
        var hintBottomPadding = OnboardingStyle.bubblePaddingBottom1
        if dataSource?.onboardingTitle(for: id) != nil {
            bubble.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalTo(topAnchor).offset(OnboardingStyle.titleMarginTop)
                make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
                make.trailing.equalToSuperview().offset(-OnboardingStyle.bubblePaddingTopLeadingTrailing)
            }
            topAnchor = titleLabel.snp.bottom
            hintTopPadding = OnboardingStyle.titleHintSpacing
            hintBottomPadding = OnboardingStyle.bubblePaddingBottom2
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(topAnchor).offset(hintTopPadding)
            make.leading.equalToSuperview().offset(OnboardingStyle.bubblePaddingTopLeadingTrailing)
            make.trailing.equalToSuperview().offset(-OnboardingStyle.bubblePaddingTopLeadingTrailing)
            make.bottom.equalToSuperview().offset(-hintBottomPadding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCustomizeGestureIfNeed() {
        guard let tapCount = dataSource?.onboardingSwipeGestureTapCount(for: id) else {
            return
        }
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onboardingSwipeHandler))
        gestureRecognizer.minimumNumberOfTouches = tapCount
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc
    func onboardingSwipeHandler(sender: UIPanGestureRecognizer) {
        delegate?.onboardingSwipeDisappearCallBack(id, sender: sender)
    }
}



private class PenetrableView: UIView {

    weak var baseVC: PenetrableViewDelegate?
    private var enableTwoFingerMove = false

    init(baseVC: PenetrableViewDelegate) {
        self.baseVC = baseVC
        super.init(frame: .zero)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if #available(iOS 13.4, *) {
            if event?.type == .hover || event == nil {
                // iPad 外接键盘触控板上的接触、移动会导致频繁调用到这里，event?.type 是 hover 的类型。
                return super.hitTest(point, with: event)
            }
        }
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
