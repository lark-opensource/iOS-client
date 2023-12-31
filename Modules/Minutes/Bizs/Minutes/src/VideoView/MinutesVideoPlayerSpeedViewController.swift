//
//  MinutesVideoPlayerSpeedViewController.swift
//  Minutes
//
//  Created by lvdaqian on 2021/1/17.
//

import Foundation
import UniverseDesignIcon

enum SpeedViewPresentStyle {
    case present
    case overlay
    case podcast
}

class SpeedValueView: UIView {

    let speedValue: Double
    let showValueByDefault: Bool
    let style: SpeedViewPresentStyle
    var defaultViewColor: UIColor = UIColor.ud.iconDisable
    var defaultLabelTextColor: UIColor = UIColor.ud.textTitle
    var isSelected: Bool = false {
        didSet {
            if style == .podcast {
                if isSelected {
                    view.backgroundColor = UIColor.ud.N00.nonDynamic
                    label.isHidden = false
                    label.textColor = UIColor.ud.N00.nonDynamic
                    feedbackGenerator()
                } else {
                    view.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.25).nonDynamic
                    label.isHidden = !showValueByDefault
                    label.textColor = UIColor.ud.N00.withAlphaComponent(0.3).nonDynamic
                }
            } else {
                if isSelected {
                    view.backgroundColor = UIColor.ud.primaryContentDefault
                    label.isHidden = false
                    label.textColor = UIColor.ud.primaryContentDefault
                    feedbackGenerator()
                } else {
                    view.backgroundColor = defaultViewColor
                    label.isHidden = !showValueByDefault
                    label.textColor = defaultLabelTextColor
                }
            }
        }
    }

    private let view = UIView()
    private let label = UILabel()

    init(speedValue: Double, showValueByDefault: Bool, style: SpeedViewPresentStyle) {
        self.speedValue = speedValue
        self.showValueByDefault = showValueByDefault
        self.style = style
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        switch style {
        case .present, .podcast:
            setupViewsForPresent()
        case .overlay:
            setupViewsForOverlay()
        }
    }

    func setupViewsForPresent() {
        if style == .podcast {
            view.backgroundColor = UIColor.ud.N00.withAlphaComponent(0.25).nonDynamic
        } else {
            view.backgroundColor = defaultViewColor
        }

        view.layer.cornerRadius = 1.5
        addSubview(view)

        let height = showValueByDefault ? 28 : 12
        view.snp.makeConstraints { maker in
            maker.width.equalTo(3)
            maker.height.equalTo(height)
            maker.top.equalToSuperview()
            maker.centerX.equalToSuperview()
        }

        label.text = String(format: "%gx", speedValue)
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        if style == .podcast {
            label.textColor = UIColor.ud.N00.withAlphaComponent(0.3).nonDynamic
        } else {
            label.textColor = defaultLabelTextColor
        }

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.bottom.centerX.equalToSuperview()
            maker.height.equalTo(21)
        }

        label.isHidden = !showValueByDefault
    }

    func setupViewsForOverlay() {
        defaultViewColor = UIColor.ud.N00.withAlphaComponent(0.35).nonDynamic
        defaultLabelTextColor = UIColor.ud.N00.nonDynamic
        view.backgroundColor = defaultViewColor
        view.layer.cornerRadius = 1.5
        addSubview(view)
        let width = showValueByDefault ? 28 : 12
        view.snp.makeConstraints {
            $0.width.equalTo(width)
            $0.height.equalTo(3)
            $0.left.equalTo(44.5)
            $0.centerY.equalToSuperview()
        }

        label.text = String(format: "%gX", speedValue)
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = defaultLabelTextColor

        addSubview(label)
        label.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(view).offset(40)
            $0.height.equalTo(21)
        }

        label.isHidden = !showValueByDefault

    }

    func feedbackGenerator() {
        let gen = UIImpactFeedbackGenerator.init(style: .light)
        gen.prepare()
        gen.impactOccurred()
    }
}

class MinutesVideoPlayerSpeedViewController: UIViewController {

    let style: SpeedViewPresentStyle

    var onSelecteValueChanged: ((Double) -> Void)?
    var onSkipSwitchValueChanged: ((Bool) -> Void)?

    var selected: SpeedValueView? {
        didSet {
            guard oldValue != selected else { return }
            oldValue?.isSelected = false
            selected?.isSelected = true

            if let speed = selected?.speedValue {
                if let playbackSpeed = player?.playbackSpeed, playbackSpeed != CGFloat(speed) { // 首次进来不上报
                    if style == .podcast {
                        player?.tracker.tracker(name: .podcastClick, params: ["click": "speed_change", "speed_type": String(format: "%g", speed), "target": "none"])
                    } else {
                        player?.tracker.tracker(name: .detailClick, params: ["click": "speed_change", "speed_type": String(format: "%g", speed), "location": style == .overlay ? "player" : "controller", "target": "none"])
                    }
                }

                player?.playbackSpeed = CGFloat(speed)
                onSelecteValueChanged?(speed)

                if style == .podcast {
                    var trackParams = [AnyHashable: Any]()
                    trackParams.append(.speedChange)
                    trackParams["action_type"] = String(format: "%g", speed)
                    player?.tracker.tracker(name: .podcastPage, params: trackParams)
                } else {
                    var trackParams = [AnyHashable: Any]()
                    trackParams.append(.speedChange)
                    trackParams.append(.controller)
                    trackParams["action_type"] = String(format: "%g", speed)
                    player?.tracker.tracker(name: .clickButton, params: trackParams)
                }
            }
        }
    }

    lazy var options: [SpeedValueView] = [
        SpeedValueView(speedValue: 0.5, showValueByDefault: true, style: style),
        SpeedValueView(speedValue: 0.75, showValueByDefault: false, style: style),
        SpeedValueView(speedValue: 1.0, showValueByDefault: true, style: style),
        SpeedValueView(speedValue: 1.25, showValueByDefault: false, style: style),
        SpeedValueView(speedValue: 1.5, showValueByDefault: false, style: style),
        SpeedValueView(speedValue: 2.0, showValueByDefault: true, style: style),
        SpeedValueView(speedValue: 3.0, showValueByDefault: true, style: style)
    ]

    var selectedSpeed: Double {
        get {
            return selected?.speedValue ?? 1.0
        }
        set {
            if let option = options.first { $0.speedValue == newValue } {
                selected = option
            }
        }
    }

    var player: MinutesVideoPlayer? {
        didSet {
            guard let speed = player?.playbackSpeed else {
                return
            }

            selectedSpeed = Double(speed)
        }
    }

    let container = UIView()

    init(_ style: SpeedViewPresentStyle = .present) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch style {
        case .present, .podcast:
            return .portrait
        case .overlay:
            return .landscape
        }
    }

    func setupViews() {
        switch style {
        case .present, .podcast:
            setupViewsForPresent()
        case .overlay:
            setupViewsForOverlay()
        }
    }

    func setupViewsForPresent() {
        let effectView = UIVisualEffectView()
        container.addSubview(effectView)
        if style == .podcast {
            effectView.effect = UIBlurEffect(style: .dark)
            container.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.45).alwaysDark
        } else {
            container.backgroundColor = UIColor.ud.bgBody
        }
        effectView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        view.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview().offset(6)
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-190)
        }

        let picker = UIStackView(arrangedSubviews: options)
        picker.distribution = .fillEqually
        picker.axis = .horizontal
        container.addSubview(picker)
        picker.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(14)
            maker.top.equalToSuperview().offset(40)
            maker.height.equalTo(59)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(onGesture))
        let tap = UITapGestureRecognizer(target: self, action: #selector(onGesture))
        picker.addGestureRecognizer(pan)
        picker.addGestureRecognizer(tap)

        let line = UIView()
        container.addSubview(line)
        if style == .podcast {
            line.backgroundColor = UIColor.ud.lineDividerDefault.alwaysDark
        } else {
            line.backgroundColor = UIColor.ud.lineDividerDefault
        }
        line.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(20)
            maker.top.equalToSuperview().offset(125)
            maker.height.equalTo(0.5)
        }

        let guideImageView = UIImageView()
        container.addSubview(guideImageView)
        if style == .podcast {
            guideImageView.image = UIImage.dynamicIcon(.iconEllipsis, dimension: 24, color: UIColor.ud.N00.nonDynamic)
        } else {
            guideImageView.image = UIImage.dynamicIcon(.iconEllipsis, dimension: 24, color: UIColor.ud.N800)
        }
        guideImageView.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(20)
            maker.top.equalTo(line.snp.bottom).offset(25)
        }

        let skipLabel = UILabel()
        container.addSubview(skipLabel)
        skipLabel.font = UIFont.systemFont(ofSize: 16)
        skipLabel.text = BundleI18n.Minutes.MMWeb_G_SkipSilentParts
        if style == .podcast {
            skipLabel.textColor = UIColor.ud.N00.nonDynamic
        } else {
            skipLabel.textColor = UIColor.ud.textTitle
        }
        skipLabel.snp.makeConstraints { maker in
            maker.left.equalTo(guideImageView.snp.right).offset(15)
            maker.centerY.equalTo(guideImageView.snp.centerY)
        }

        let switchButton = UISwitch()
        container.addSubview(switchButton)
        switchButton.isOn = player?.shouldSkipSilence ?? false
        switchButton.layer.cornerRadius = 15.5
        switchButton.layer.masksToBounds = true
        switchButton.onTintColor = UIColor.ud.colorfulBlue
        switchButton.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.4)
        switchButton.addTarget(self, action: #selector(switchButtonClicked(_:)), for: .valueChanged)
        switchButton.snp.makeConstraints { maker in
            maker.right.equalToSuperview().offset(-20)
            maker.centerY.equalTo(guideImageView.snp.centerY)
            maker.height.equalTo(31)
        }

        let confirm = UIView()
        view.addSubview(confirm)
        confirm.backgroundColor = .clear
        confirm.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(container.snp.top)
        }
        let confirmAction = UITapGestureRecognizer(target: self, action: #selector(onConfirm))
        confirm.addGestureRecognizer(confirmAction)
    }

    func setupViewsForOverlay() {

        container.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.75).nonDynamic
        view.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.top.bottom.right.equalToSuperview()
            maker.width.equalTo(208)
        }

        let picker = UIStackView(arrangedSubviews: options.reversed())
        picker.distribution = .fillEqually
        picker.axis = .vertical
        container.addSubview(picker)
        picker.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview().offset(33)
            maker.bottom.equalToSuperview().inset(36)
        }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(onGesture))
        let tap = UITapGestureRecognizer(target: self, action: #selector(onGesture))
        picker.addGestureRecognizer(pan)
        picker.addGestureRecognizer(tap)

        let confirm = UIView()
        view.addSubview(confirm)
        confirm.backgroundColor = .clear
        confirm.snp.makeConstraints { maker in
            maker.top.left.bottom.equalToSuperview()
            maker.right.equalTo(container.snp.left)
        }
        let confirmAction = UITapGestureRecognizer(target: self, action: #selector(onConfirm))
        confirm.addGestureRecognizer(confirmAction)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    @objc func onConfirm(_ gesture: UIGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func onGesture(_ gesture: UIGestureRecognizer) {
        for option in options {
            let point = gesture.location(in: option.superview)
            if option.frame.contains(point) {
                selected = option
                break
            }
        }
    }

    @objc func switchButtonClicked(_ sender: UISwitch) {
        if style == .podcast {
            player?.tracker.tracker(name: .podcastPage, params: ["action_name": "skip_blank", "action_enable": sender.isOn ? "1" : "0"])
            player?.tracker.tracker(name: .podcastSettingClick, params: ["click": "skip_blank", "is_open": sender.isOn, "target": "none"])
        } else {
            player?.tracker.tracker(name: .clickButton, params: ["action_name": "skip_blank", "action_enable": sender.isOn ? "1" : "0"])
            player?.tracker.tracker(name: .detailSettingClick, params: ["click": "skip_blank", "is_open": sender.isOn, "target": "none"])
        }

        onSkipSwitchValueChanged?(sender.isOn)
    }
}

extension MinutesVideoPlayerSpeedViewController: UIViewControllerTransitioningDelegate {

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        switch style {
        case .present, .podcast:
            return MinutesVideoPlayerSpeedPresentationController(presentedViewController: presented, presenting: presenting)
        default:
            return nil
        }
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch style {
        case .overlay:
            return MinutesRightSideAnimator(isPresenting: true)
        default:
            return nil
        }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch style {
        case .overlay:
            return MinutesRightSideAnimator(isPresenting: false)
        default:
            return nil
        }
    }
}

class MinutesVideoPlayerSpeedPresentationController: UIPresentationController {

    private let dimmingView = UIView()

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = UIColor.ud.bgMask
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        self.containerView?.addSubview(self.dimmingView)
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}
