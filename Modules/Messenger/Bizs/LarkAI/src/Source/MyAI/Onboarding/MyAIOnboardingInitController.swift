//
//  MyAIOnboardingInitController.swift
//  LarkAI
//
//  Created by ByteDance on 2023/4/26.
//

import Lottie
import RxSwift
import RxCocoa
import Homeric
import FigmaKit
import LarkUIKit
import EENavigator
import LKCommonsTracker
import UniverseDesignInput

var shadowColors: [UIColor] = [
    UIColor.ud.N300,
    UIColor.ud.N300.withAlphaComponent(0)
]

class MyAIOnboardingInitController: BaseUIViewController {
    struct Config {
        static let leftRightMargin: CGFloat = 16
        static let bottomMargin: CGFloat = 30
        static let confimButtonHeight: CGFloat = 48
        static let avatarPickerCenterYOffsetWhenKeyboardFold: CGFloat = 131

        static let avatarSmallSize: CGFloat = 72 //头像未选中时的size
        static let avatarMiddleSize: CGFloat = 120 //头像选中放大状态的size
        static let avatarLargeSize: CGFloat = 200 //头像选中并点击continue后，放缩动画播放完后的size

        static let shadowViewInitialWidth: CGFloat = 160
        static let shadowViewInitialHeight: CGFloat = 16
        static let shadowViewFinalWidth: CGFloat = 200
        static let shadowViewFinalHeight: CGFloat = 20
        static let spacingBetweenAvatarAndShadowView: CGFloat = 24

        static let namePickerButtonSpacing: CGFloat = 14
    }

    let viewModel: MyAIOnboardingViewModel

    var keyboardHeightChangeDriver: Driver<KeyboardInfo?> { keyboardHeightChangePublish.asDriver(onErrorJustReturn: (nil)) }
    private var keyboardHeightChangePublish = PublishSubject<KeyboardInfo?>()

    let disposeBag = DisposeBag()

    lazy var avatarPicker: AIAvatarPickerView = {
        let view = AIAvatarPickerView(presetAvatars: viewModel.presetAvatars)
        return view
    }()

    lazy var namePicker: AINamePickerView = {
        let view = AINamePickerView(presetNames: viewModel.presetNames)
        view.clipsToBounds = false
        return view
    }()

    lazy var continueButton: UIButton = {
        let button = AIUtils.makeAIButton()
        button.setTitle(BundleI18n.LarkAI.MyAI_IM_Onboarding_SetupContinue_Button, for: .normal)
        button.addTarget(self, action: #selector(onContinueButtonClicked), for: .touchUpInside)
        return button
    }()

    override var navigationBarStyle: NavigationBarStyle {
        if #available(iOS 16, *) {
            return .custom(UIColor.clear)
        } else {
            return .custom(UIColor.ud.bgBody)
        }
    }

    override func loadView() {
        view = AIUtils.makeAuroraBackgroundView()
    }

    init(viewModel: MyAIOnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        observeKeyboardFrameChange()
        observeData()
        playInitAnimation()
        viewModel.reportOnboardingSetupViewShown()
        closeCallback = { [weak self] in
            self?.viewModel.reportOnboardingSetupCloseClicked()
            self?.viewModel.cancelCallback?()
        }
    }

    func playInitAnimation() {
        DispatchQueue.main.async {
            self.continueButton.isUserInteractionEnabled = false
            self.avatarPicker.playInitAnimation { [weak self] _ in
                self?.continueButton.isUserInteractionEnabled = true
            }
        }
    }

    private func setupSubviews() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(avatarPicker)
        view.addSubview(namePicker)
        view.addSubview(continueButton)
        avatarPicker.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().priority(.low)
            make.bottom.equalTo(namePicker.snp.top)
        }
        namePicker.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top).offset(-Config.namePickerButtonSpacing)
        }
        continueButton.snp.makeConstraints { (make) in
            make.left.equalTo(MyAIOnboardingInitController.Config.leftRightMargin)
            make.right.equalTo(-MyAIOnboardingInitController.Config.leftRightMargin)
            make.height.equalTo(MyAIOnboardingInitController.Config.confimButtonHeight)
            //下面两项bottom约束看起来有点重复，这么写的原因是：为了实现动画。具体如下：
            //当键盘弹起时，continueButton一定要和view的底部而非view.safeAreaLayoutGuide的底部约束
            //所以为了在做动画时updateConstraints，这里也不许和view的底部写约束
            //所以为了在做动画时updateConstraints，这里也不许和view的底部写约束
            //另一方面键盘收起时continueButton一定要和view.safeAreaLayoutGuide的底部约束，所以加了一个lessThanOrEqualTo。
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MyAIOnboardingInitController.Config.bottomMargin)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-MyAIOnboardingInitController.Config.bottomMargin)
        }
        continueButton.isEnabled = !(namePicker.text ?? "").isEmpty
        namePicker.onTextChange = { [weak self] text in
            let currentText = text ?? ""
            self?.continueButton.isEnabled = !currentText.isEmpty
        }
    }

    private func observeData() {
        self.viewModel.presetNamesUpdateDriver
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.namePicker.presetNames = self.viewModel.presetNames
            }).disposed(by: self.disposeBag)

        self.viewModel.presetAvatarsUpdateDriver
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                self.avatarPicker.reloadData()
            }).disposed(by: self.disposeBag)

        self.keyboardHeightChangeDriver
            .drive(onNext: { [weak self] info in
                guard let self = self, let info = info else { return }
                self.avatarPicker.layoutIfNeeded()
                UIView.animate(
                    withDuration: info.duration,
                    delay: 0,
                    options: [.beginFromCurrentState],
                    animations: {
                        self.avatarPicker.layoutIfNeeded()
                        if let curve = info.curve {
                            UIView.setAnimationCurve(curve)
                        }
                        if info.isKeyboardAppear {
                            self.continueButton.snp.updateConstraints { (make) in
                                make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-8 - info.systemKeyboardHeight(forView: self.view) + self.view.safeAreaInsets.bottom)
                            }
                        } else {
                            self.continueButton.snp.updateConstraints { (make) in
                                make.bottom.equalTo(self.view.safeAreaLayoutGuide).offset(-MyAIOnboardingInitController.Config.bottomMargin)
                            }
                        }
                        self.view.layoutIfNeeded()
                    })
            }).disposed(by: self.disposeBag)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        namePicker.resignFirstResponder()
    }

    @objc
    private func onContinueButtonClicked() {
        namePicker.resignFirstResponder()
        guard let naviVC = self.navigationController,
              let text = namePicker.text else { return }
        self.viewModel.currentName = text
        let avatarIndex = avatarPicker.currentSelectedIndex
        viewModel.currentAvatar = viewModel.presetAvatars[avatarIndex]
        viewModel.currentAvatarPlaceholderImage = avatarPicker.currentAvatarImage

        let nextStepVC = MyAIOnboardingConfirmController(viewModel: self.viewModel)
        naviVC.pushViewController(nextStepVC, animated: true)
        viewModel.reportOnboardingSetupContinueClicked()
    }

    // MARK: Keyboard Frame Change

    private func observeKeyboardFrameChange() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc
    fileprivate func keyboardFrameChange(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            return
        }

        let duration: TimeInterval = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0

        guard let curveValue = userinfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: curveValue) else {
                return
        }

        var isKeyboardAppear: Bool = false
        let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        let fromFrame = userinfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect
        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let toFrame = toFrame else {
                return
            }
            // iPadOS 15 beta 外接键盘拖动候选词条时，会触发 begin & end frame 均为 .zero 的 willShow 通知，暂时过滤掉。
            if toFrame == .zero,
               let fromFrame = userinfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
               fromFrame == .zero {
                return
            }
            isKeyboardAppear = true
        }

        self.keyboardHeightChangePublish.onNext(KeyboardInfo(toFrame: toFrame ?? .zero,
                                                             fromFrame: fromFrame ?? .zero,
                                                             isKeyboardAppear: isKeyboardAppear,
                                                             duration: duration,
                                                             curve: curve))
    }
}

extension MyAIOnboardingInitController {

    struct KeyboardInfo {
        var toFrame: CGRect
        var fromFrame: CGRect
        var isKeyboardAppear: Bool
        var duration: TimeInterval
        var curve: UIView.AnimationCurve?

        /// 计算键盘遮挡了view的部分的高度
        /// 因为输入框可能不贴紧底部，所以需要计算相对键盘高度
        /// 如果此时 view不在视图层级上则返回完整键盘高度
        func systemKeyboardHeight(forView: UIView) -> CGFloat {
            if let window = forView.window {
                let convertRect = forView.convert(forView.bounds, to: window)
                var windowOffSetY: CGFloat = 0
                /// 如果高都小于屏幕高度，这个时候键盘的计算的高度会有问题 需要调整一下
                /// 补充的高度 = 键盘window相对整个屏幕的高度偏移
                if window.frame.height < UIScreen.main.bounds.height,
                   Display.pad {
                    let point = window.convert(CGPoint.zero, to: UIScreen.main.coordinateSpace)
                    windowOffSetY = point.y
                }

                let bottomY = windowOffSetY + window.frame.minY + convertRect.minY + convertRect.height
                /// 兼容视图最大 Y 超出键盘底部的场景
                return max(0, min(toFrame.maxY, bottomY) - toFrame.minY)
            } else {
                return toFrame.height
            }
        }
    }
}

extension MyAIOnboardingInitController {

    enum Cons {

        static var bottomAreaHeight: CGFloat {
            Config.bottomMargin
            + Config.confimButtonHeight
            + Config.namePickerButtonSpacing
            + AINamePickerView.Cons.totalHeight
        }
    }
}
