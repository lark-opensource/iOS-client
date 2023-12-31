//
//  ByteViewDialog.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/14.
//

import Foundation
import UniverseDesignDialog
import RichLabel
import ByteViewCommon

final public class ByteViewDialog: UDDialog {

    private enum Padding {
        static let x: CGFloat = 20
        static let y: CGFloat = 24
        static let top: CGFloat = 12
    }

    static let margin: CGFloat = 36

    typealias ButtonListElement = (UIButton, (() -> Void)?)

    var showConfig: ByteViewDialogConfig.ShowConfig {
        configuration.showConfig
    }
    var alertWindow: UIWindow?

    private var checkboxView: CheckboxView?
    public var isChecked: Bool {
        checkboxView?.isChecked ?? false
    }

    private var countDownTimer: DispatchSourceTimer?

    private var buttonList: [ButtonListElement] = []

    private var updateTask: (() -> Void)?

    private weak var contentView: UIView?

    private var configuration: ByteViewDialogConfig
    private var colors: ByteViewDialogConfig.AlertColors

    public init(configuration: ByteViewDialogConfig) {
        self.configuration = configuration
        self.colors = configuration.colorTheme.colors
        super.init(config: configuration.udConfig)
        self.isAutorotatable = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addButton(title: String, isSpecial: Bool = false, handler: (() -> Void)? = nil) {
        let color: UIColor = isSpecial ? colors.buttonSpecialTitle : colors.buttonTitle
        let button = addButton(
            text: title,
            color: color,
            numberOfLines: 0,
            dismissCheck: {
                handler?()
                return false
            }
        )
        button.setTitleColor(color, for: .highlighted)
        button.setTitleColor(color.withAlphaComponent(0.4), for: .disabled)
        button.backgroundColor = colors.buttonBackground
        buttonList.append((button, handler))
    }

    func setContent(content: ByteViewDialogConfig.Content, additionalContent: ByteViewDialogConfig.AdditionalContent) {
        switch (content, additionalContent) {
        case (.message(let text), .none):
            if let text = text {
                setContent(text: text)
            }
        default:
            if case .none = content, case .none = additionalContent {
                // 没有内容则不调用 setContent
                // 否则会有title布局不居中问题
                return
            }
            let wrapperView = UIView()
            let contentView = content.view
            self.contentView = contentView
            if case .none = content {
                contentView.isHidden = true
            } else {
                contentView.isHidden = false
            }
            wrapperView.addSubview(contentView)
            let size = getCalculatedContentSize(contentView: contentView)
            contentView.snp.makeConstraints {
                $0.top.equalToSuperview().offset(Padding.top)
                $0.left.right.equalToSuperview().inset(Padding.x)
                $0.width.equalTo(size.width)
                if size.height > 0 {
                    $0.height.equalTo(size.height)
                }
            }
            fixLKLabelIfNeeded(label: contentView)
            switch additionalContent {
            case .checkbox(let checkboxConfig):
                let checkboxView = CheckboxView(
                    content: checkboxConfig.content,
                    isChecked: checkboxConfig.isChecked,
                    textColor: colors.content,
                    itemSize: checkboxConfig.itemImageSize
                )
                self.checkboxView = checkboxView
                checkboxView.addListener(self)
                wrapperView.addSubview(checkboxView)
                checkboxView.snp.makeConstraints {
                    $0.top.greaterThanOrEqualToSuperview().priority(.low)
                    $0.top.equalTo(contentView.snp.bottom)
                    $0.left.right.equalToSuperview().inset(Padding.x)
                    $0.bottom.equalToSuperview().offset(-Padding.y)
                }
            case .choice(let choiceConfig):
                let choiceView = ChoiceView(
                    items: choiceConfig.items,
                    interitemSpacing: 18.0,
                    itemImageSize: choiceConfig.itemImageSize,
                    textColor: colors.content
                )
                wrapperView.addSubview(choiceView)
                choiceView.snp.makeConstraints {
                    $0.top.greaterThanOrEqualToSuperview().priority(.low)
                    $0.top.equalTo(contentView.snp.bottom).offset(choiceConfig.topPadding)
                    $0.left.right.equalToSuperview().inset(Padding.x)
                    $0.bottom.equalToSuperview().offset(-Padding.y)
                }
            default:
                contentView.snp.makeConstraints {
                    $0.bottom.equalToSuperview().offset(-Padding.y)
                }
            }
            setContent(view: wrapperView)
        }
    }

    private func getCalculatedContentSize(contentView: UIView) -> CGSize {
        if contentView is UIButton {
            // Button 横竖屏均保持固定宽度
            return .init(width: 263, height: 40)
        } else if let textView = contentView as? UITextView {
            // contentView 为 UITextView 时，有最大高度限制
            let width = Self.calculatedContentWidth(adaptsLandscapeLayout: configuration.adaptsLandscapeLayout)
            let safeAreaInsets = VCScene.safeAreaInsets
            let mainBounds = VCScene.bounds
            let tempTextView = UITextView(frame: CGRect(x: 0, y: 0, width: textView.bounds.width, height: 0))
            tempTextView.text = textView.text
            tempTextView.font = textView.font
            tempTextView.textContainerInset = .zero
            let msgHeight = tempTextView.sizeThatFits(CGSize(width: width, height: CGFloat(MAXFLOAT))).height
            let maxHeight = mainBounds.height - safeAreaInsets.top - safeAreaInsets.bottom - 136 - 58 - 74
            var height = msgHeight + textView.textContainerInset.top + textView.textContainerInset.bottom
            if height > maxHeight {
                height = maxHeight
            } else {
                textView.isScrollEnabled = false
            }
            return .init(width: width, height: height)
        } else {
            let width = Self.calculatedContentWidth(adaptsLandscapeLayout: configuration.adaptsLandscapeLayout)
            let height: CGFloat = configuration.contentHeight ?? -1
            return .init(width: width, height: height)
        }
    }

    // disable-lint: magic number
    public static func calculatedContentWidth(adaptsLandscapeLayout: Bool = false) -> CGFloat {
        if Display.pad {
            return 263
        } else {
            if adaptsLandscapeLayout, VCScene.isLandscape {
                return 303
            } else {
                let bounds = VCScene.bounds
                return min(bounds.width, bounds.height) - 2 * Padding.x - 2 * Self.margin
            }
        }
    }

    private func fixLKLabelIfNeeded(label: UIView) {
        if let label = label as? LKLabel {
            updateTask = { [weak label] in
                label?.preferredMaxLayoutWidth = 263
                label?.attributedText = { label?.attributedText }()
            }
            // 此处需要提前刷新，确保高度正确
            updateTask?()
            label.superview?.setNeedsLayout()
            label.superview?.layoutIfNeeded()
        }
    }
    // enable-lint: magic number

    private func updateColorsIfNeeded() {
        if let label = contentView as? LKLabel {
            if let attributedText = label.attributedText {
                let mutable = NSMutableAttributedString(attributedString: attributedText)
                mutable.addAttribute(.foregroundColor, value: colors.content, range: NSRange(location: 0, length: attributedText.length))
                label.attributedText = mutable
            } else {
                label.textColor = colors.content
            }
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTask?()
        updateColorsIfNeeded()
    }

    private var rightButton: ButtonListElement? {
        if buttonList.count <= 1 {
            return buttonList.first
        } else {
            return buttonList[1]
        }
    }

    func setupRightButtonCountDown(originTitle: String, time: TimeInterval) {
        guard let (button, _) = rightButton else { return }

        button.setTitle(originTitle + "（\(Int(time))s）", for: .normal)

        setButtonsUserInteraction(enabled: false)
        var currentTime = time
        startCountDownTimer { [weak self] in
            guard let self = self else { return }
            if currentTime <= 1 {
                self.setButtonsUserInteraction(enabled: true)
                button.setTitle(originTitle, for: .normal)
                self.destoryCountDownTimer()
            } else {
                button.setTitle(originTitle + "（\(Int(currentTime))s）", for: .normal)
                currentTime -= 1
            }
        }
    }

    func setupRightButtonCountDown(duration: UInt, updator: ByteViewDialogConfig.CountDownUpdator?) {
        guard let (button, action) = rightButton else { return }

        var currentTime = duration
        startCountDownTimer { [weak self] in
            guard let self = self else { return }
            if currentTime <= 1 {
                action?()
                self.destoryCountDownTimer()
            } else {
                currentTime -= 1
                if let title = updator?(currentTime) ?? button.titleLabel?.text {
                    let config: VCFontConfig = .h4
                    let attributedTitle = NSMutableAttributedString(attributedString: .init(string: title, config: config, alignment: .center, textColor: self.colors.buttonSpecialTitle))
                    let regex = try? NSRegularExpression(pattern: "\(currentTime)", options: .caseInsensitive)
                    if let range = regex?.rangeOfFirstMatch(in: title,
                                                            options: .reportProgress,
                                                            range: NSRange(location: 0, length: title.count)) {
                        attributedTitle.addAttributes([.font: UIFont.monospacedDigitSystemFont(ofSize: config.fontSize, weight: config.fontWeight)], range: range)
                    }
                    button.setAttributedTitle(attributedTitle, for: .normal)
                }
            }
        }
    }

    func setupRightButtonEnable(updator: ByteViewDialogConfig.EnableUpdator) {
        guard let (button, _) = rightButton else {
            return
        }
        updator { isEnabled in
            Util.runInMainThread {
                button.isEnabled = isEnabled
            }
        }
    }

    private func startCountDownTimer(handler: DispatchSourceProtocol.DispatchSourceHandler?) {
        destoryCountDownTimer()
        countDownTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        countDownTimer?.schedule(wallDeadline: .now(), repeating: .seconds(1))
        countDownTimer?.setEventHandler(handler: handler)
        countDownTimer?.resume()
    }

    private func destoryCountDownTimer() {
        if countDownTimer != nil {
            countDownTimer?.cancel()
            countDownTimer = nil
        }
    }

    private func setButtonsUserInteraction(enabled: Bool) {
        buttonList.forEach {
            $0.0.isUserInteractionEnabled = enabled
        }
    }
}

extension ByteViewDialog: CheckboxViewListener {
    func didChangeCheckbox(isChecked: Bool) {
        guard let checkboxConfig = configuration.checkboxConfig, checkboxConfig.affectLastButtonEnabled else {
            return
        }
        buttonList.forEach {
            $0.0.isEnabled = true
        }
        buttonList.last?.0.isEnabled = isChecked
    }
}
