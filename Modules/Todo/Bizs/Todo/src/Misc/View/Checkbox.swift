//
//  Checkbox.swift
//  Todo
//
//  Created by 张威 on 2020/12/8.
//

import Lottie
import AudioToolbox
import UniverseDesignIcon
import UIKit

// MARK: Checkbox State

enum CheckboxState {
    /// 可点击
    ///
    /// - Parameter isChecked: 是否是 checked 状态
    case enabled(isChecked: Bool)

    /// 不可点击
    ///
    /// - Parameter isChecked: 是否 checked 状态
    /// - Parameter hasAction: 点击时是否有进一步的 action
    case disabled(isChecked: Bool, hasAction: Bool)

    var isChecked: Bool {
        switch self {
        case .enabled(let isChecked):
            return isChecked
        case .disabled(let isChecked, _):
            return isChecked
        }
    }
}

// MARK: Checkbox Action

typealias CheckboxDisabledAction = () -> Void

enum CheckboxEnabledAction {
    typealias Callback = () -> Void

    /// 直接 action
    /// - Parameter completion: 完成点击
    case immediate(completion: Callback)

    /// 需要 ask
    /// - Parameter ask: 询问确认；确认 ok，调用 `onYes`，否则调用 `onNo`
    /// - Parameter completion: 完成点击
    case needsAsk(ask: (_ onYes: @escaping Callback, _ onNo: @escaping Callback) -> Void, completion: Callback)
}

// MARK: Checkbox Delegate

protocol CheckboxDelegate: AnyObject {
    /// disable 状态下的 action
    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction
    /// enable 状态下的 action
    func enabledAction(for checkbox: Checkbox) -> CheckboxEnabledAction
}

extension CheckboxDelegate {
    func disabledAction(for checkbox: Checkbox) -> CheckboxDisabledAction {
        return {}
    }
}

// MARK: Checkbox

struct CheckBoxViewData {

    var identifier: String = UUID().uuidString

    var checkState: CheckboxState = .enabled(isChecked: false)

    var isRotated: Bool = false

}

final class Checkbox: UIControl {

    var viewData: CheckBoxViewData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            var isEnable = true
            switch viewData.checkState {
            case .disabled: isEnable = false
            case .enabled: isEnable = true
            }
            innerCheckbox.isHidden = false
            innerCheckbox.transform = viewData.isRotated ? CGAffineTransform(rotationAngle: CGFloat.pi / 4) : .identity
            innerCheckbox.isSelected = viewData.checkState.isChecked
            innerCheckbox.isEnabled = isEnable
            innerCheckbox.isRotated = viewData.isRotated

            animationView?.stop()
            animationView?.removeFromSuperview()
            animationView = nil
        }
    }

    weak var delegate: CheckboxDelegate?

    private let sizeProps = (
        button: CGSize(width: 20, height: 20),
        animationView: CGSize(width: 22, height: 22)
    )

    // 这里仅仅把 UDCheckBox 当自带样式的 UIView 来用了
    private lazy var innerCheckbox = CheckBoxView()

    private var animationView: LOTAnimationView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        addSubview(innerCheckbox)
        innerCheckbox.isUserInteractionEnabled = false
        innerCheckbox.contentMode = .center
        addTarget(self, action: #selector(handleClick), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let old = innerCheckbox.transform
        innerCheckbox.transform = .identity
        innerCheckbox.frame = bounds
        innerCheckbox.transform = old
        animationView?.frame.size = sizeProps.animationView
        animationView?.clipsToBounds = false
        animationView?.frame.center = bounds.center
    }

    @objc
    private func handleClick() {
        guard let viewData = viewData else { return }
        if animationView?.isAnimationPlaying == true { return }
        if case .disabled(_, let hasAction) = viewData.checkState, !hasAction {
            return
        }
        guard let delegate = delegate else { return }
        var newViewData = viewData
        switch viewData.checkState {
        case .disabled:
            delegate.disabledAction(for: self)()
        case let .enabled(isChecked):
            newViewData.checkState = .enabled(isChecked: !isChecked)
            switch delegate.enabledAction(for: self) {
            case .immediate(let completion):
                AudioServicesPlaySystemSound(1_520)
                updateContentAnimated(!isChecked, viewData.isRotated) { [weak self] in
                    self?.viewData = newViewData
                    completion()
                }
            case let .needsAsk(ask, completion):
                let tempId = viewData.identifier
                ask(
                    // onYes
                    { [weak self] in
                        guard let self = self, self.viewData?.identifier == tempId else {
                            completion()
                            return
                        }
                        self.updateContentAnimated(!isChecked, viewData.isRotated) { [weak self] in
                            self?.viewData = newViewData
                            completion()
                        }
                    },
                    // onNo
                    {
                        // do nothing
                    }
                )
            }
        }
    }

    private func updateContentAnimated(_ isOn: Bool, _ disable: Bool = false, completion: (() -> Void)? = nil) {
        guard !disable else {
            completion?()
            return
        }
        var resourceName = isOn ? "Lottie/checked" : "Lottie/unchecked"
        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            resourceName = isOn ? "Lottie/checked_dark" : "Lottie/unchecked_dark"
        }
        guard let path = BundleConfig.TodoBundle.path(forResource: resourceName, ofType: "json") else {
            completion?()
            return
        }
        self.animationView?.removeFromSuperview()

        let animationView = LOTAnimationView(filePath: path)
        animationView.frame.size = sizeProps.animationView
        animationView.frame.center = bounds.center
        animationView.backgroundColor = .clear
        animationView.contentMode = .center
        animationView.loopAnimation = false
        animationView.autoReverseAnimation = false
        addSubview(animationView)
        innerCheckbox.isHidden = true
        innerCheckbox.isSelected = isOn

        // play(completion: LOTAnimationCompletionBlock?) 的回调，在快速点击的时候会重复触发，这里规避一下
        var canTrigger = true
        animationView.play { [weak self, weak animationView] _ in
            guard canTrigger else { return }
            canTrigger = false
            DispatchQueue.main.async {
                self?.innerCheckbox.isHidden = false
                animationView?.removeFromSuperview()
                if self?.animationView == animationView {
                    self?.animationView = nil
                }
                completion?()
            }
        }
        self.animationView = animationView
    }
}

private final class CheckBoxView: UIControl {

    public override var isSelected: Bool {
        didSet {
            self.updateUI()
        }
    }

    public override var isEnabled: Bool {
        didSet {
            self.updateUI()
        }
    }

    var isRotated: Bool = false {
        didSet {
            self.updateUI()
        }
    }

    private lazy var enableIcon: UIImageView = {
        let imageView = UIImageView()
        // 初始化的时候直接读取图片会有些耗时
        DispatchQueue.main.async {
            imageView.image = UDIcon.getIconByKey(
                .checkOutlined,
                iconColor: UIColor.ud.primaryContentDefault,
                size: CGSize(width: 16, height: 16)
            )
        }
        return imageView
    }()

    private lazy var disableIcon: UIImageView = {
        let imageView = UIImageView()
        DispatchQueue.main.async {
            imageView.image = UDIcon.getIconByKey(
                .checkOutlined,
                iconColor: UIColor.ud.iconDisabled,
                size: CGSize(width: 16, height: 16)
            )
        }
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(enableIcon)
        enableIcon.isHidden = true
        addSubview(disableIcon)
        disableIcon.isHidden = true
        layer.cornerRadius = 4
        layer.borderWidth = 1
        layer.ud.setBorderColor(UIColor.ud.iconN2)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let enableOld = enableIcon.transform
        enableIcon.transform = .identity
        enableIcon.center = center
        enableIcon.frame.size = CGSize(width: 16, height: 16)
        enableIcon.transform = enableOld

        let disableOld = disableIcon.transform
        disableIcon.transform = .identity
        disableIcon.center = center
        disableIcon.frame.size = CGSize(width: 16, height: 16)
        disableIcon.transform = disableOld
    }

    private func updateUI() {
        if isSelected {
            if isEnabled {
                enableIcon.isHidden = false
                disableIcon.isHidden = true
            } else {
                enableIcon.isHidden = true
                disableIcon.isHidden = false
            }
        } else {
            enableIcon.isHidden = true
            disableIcon.isHidden = true
        }
        let transform = isRotated ? CGAffineTransform(rotationAngle: -CGFloat.pi / 4) : .identity
        enableIcon.transform = transform
        disableIcon.transform = transform
        backgroundColor = isEnabled ? UIColor.ud.udtokenComponentOutlinedBg : UIColor.ud.N200
        var borderColor = isEnabled ? UIColor.ud.iconN2 : UIColor.ud.N400
        if !isSelected, isRotated, isEnabled {
            borderColor = UIColor.ud.primaryContentDefault
        }
        layer.ud.setBorderColor(borderColor)
    }

}
