//
//  SceneTopStatusBar.swift
//  ByteView
//
//  Created by liujianlong on 2022/9/4.
//

import UIKit
import UniverseDesignColor
import UniverseDesignFont
import SnapKit
import RxSwift

/// - Pad 宫格视图下返回共享内容 bar
/// - Webinar 彩排模式，正式开始 彩排  bar
class SceneTopStatusBar: UIView, TopExtendContainerSubcomponent {

    let disposeBag = DisposeBag()
    let sizeForCalcText = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    var hideInFullScreenMode: Bool = false
    var isStatusEmpty: Bool = true
    var isFloating: Bool {
        if self.isRegularMode {
            return self.regularAlignment == .floating
        } else {
            return self.compactAlignment == .floating
        }
    }
    weak var delegate: TopExtendContainerDelegate?

    let contentView = UIView()
    private let centerGuide = UILayoutGuide()
    private let label = UILabel()
    private let button = VisualButton(type: .custom)
    private var labelWidth: CGFloat = 0
    private var buttonWidth: CGFloat = 0
    private var barWidth: CGFloat = 0
    enum Alignment {
        case center
        case distribute
        case floating
    }

    var minSpacing: CGFloat = 16.0 {
        didSet {
            guard minSpacing != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }

    var centerContentInsets: UIEdgeInsets = UIEdgeInsets(top: 7.0, left: 16.0, bottom: 7.0, right: 16.0) {
        didSet {
            guard self.centerContentInsets != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }
    var distributeContentInsets: UIEdgeInsets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 6.0) {
        didSet {
            guard self.distributeContentInsets != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }

    var floatingContentInsets: UIEdgeInsets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 6.0) {
        didSet {
            guard self.floatingContentInsets != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }

    private var isRegularMode: Bool = false {
        didSet {
            guard self.isRegularMode != oldValue else {
                return
            }
            self.updateButtonText()
            self.updateLabelText()
            self.calContentViewWidth()
            self.updateLayout()
            self.updateStatusBarStyle()
            self.delegate?.notifyComponentChanged(self)
        }
    }


    var regularAlignment: Alignment = .center {
        didSet {
            guard self.regularAlignment != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }
    var compactAlignment: Alignment = .distribute {
        didSet {
            guard self.compactAlignment != oldValue else {
                return
            }
            setNeedsUpdateConstraints()
        }
    }

    var numberOfLines: Int {
        get { self.label.numberOfLines }
        set {
            self.label.numberOfLines = newValue
            if numberOfLines == 0 {
                self.label.snp.contentCompressionResistanceVerticalPriority = ConstraintPriority.required.value
            } else {
                self.label.snp.contentCompressionResistanceVerticalPriority = ConstraintPriority.high.value
            }
        }
    }

    var buttonAction: ((_ sender: UIControl) -> Void)?

    init(regularAlignment: Alignment, compactAlignment: Alignment) {
        self.regularAlignment = regularAlignment
        self.compactAlignment = compactAlignment
        super.init(frame: .zero)
        setupSubviews()
        self.isRegularMode = self.isMobileLandscapeOrPadRegularWidth
        if Display.phone {
            InMeetOrientationToolComponent.isLandscapeModeRelay
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else {
                        return
                    }
                    self.isRegularMode = self.isMobileLandscapeOrPadRegularWidth
                })
                .disposed(by: disposeBag)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.isRegularMode = isMobileLandscapeOrPadRegularWidth
    }

    override func updateConstraints() {
        self.calContentViewWidth()
        self.updateLayout()
        super.updateConstraints()
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let childPoint = self.convert(point, to: contentView)
        return contentView.point(inside: childPoint, with: event)
    }

    private func setupSubviews() {
        label.font = UDFont.systemFont(ofSize: 12.0, weight: .regular)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        label.textColor = UDColor.textTitle

        button.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)

        updateStatusBarStyle()
        button.addTarget(self, action: #selector(backButtonTapped(sender:)), for: .touchUpInside)

        self.addSubview(contentView)
        contentView.addSubview(label)
        contentView.addSubview(button)
        self.addLayoutGuide(centerGuide)

        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        centerGuide.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualTo(contentView).offset(centerContentInsets.left)
        }
        self.updateButtonText()
        self.updateLabelText()
        self.calContentViewWidth()
        self.updateLayout()
    }

    private var btnRegularText: String = ""
    private var btnCompactText: String = ""
    private var labelRegularText: String = ""
    private var labelCompactText: String = ""

    private var isMobileLandscapeOrPadRegularWidth: Bool {
        if Display.phone {
            return isPhoneLandscape
        } else {
            return self.traitCollection.horizontalSizeClass == .regular
        }
    }

    private func updateButtonText() {
        if isRegularMode {
            self.button.setTitle(btnRegularText, for: .normal)
        } else {
            self.button.setTitle(btnCompactText, for: .normal)
        }
    }

    private func updateLabelText() {
        if self.isRegularMode {
            self.label.text = labelRegularText
        } else {
            self.label.text = labelCompactText
        }
    }

    func updateStatusBarStyle() {
        self.backgroundColor = .clear
        let alignment = self.isRegularMode ? self.regularAlignment : self.compactAlignment
        if alignment == .center {
            self.contentView.layer.cornerRadius = 16
            self.contentView.clipsToBounds = true
            self.contentView.backgroundColor = UIColor.ud.bgBodyOverlay

            button.layer.cornerRadius = 0.0
            button.clipsToBounds = false

            button.contentEdgeInsets = .zero
            self.button.vc.setBackgroundColor(.clear, for: .normal)
            self.button.vc.setBackgroundColor(.clear, for: .highlighted)
            button.setTitleColor(UDColor.primaryContentDefault, for: .normal)
            button.setTitleColor(UDColor.primaryContentPressed, for: .highlighted)
        } else {
            self.contentView.layer.cornerRadius = 8.0
            self.contentView.backgroundColor = alignment == .floating ? UDColor.bgFloat.withAlphaComponent(0.94) : UDColor.N100
            self.contentView.clipsToBounds = true

            button.layer.cornerRadius = 6.0
            button.clipsToBounds = true

            button.contentEdgeInsets = UIEdgeInsets(top: 3.0, left: 8.0, bottom: 3.0, right: 8.0)
            button.vc.setBackgroundColor(UDColor.primaryFillDefault, for: .normal)
            button.vc.setBackgroundColor(UDColor.primaryFillPressed, for: .highlighted)

            button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        }

        if alignment == .floating {
            contentView.layer.vc.borderColor = .ud.lineBorderCard
            contentView.layer.borderWidth = 0.5
            contentView.layer.ud.setShadow(type: .s5Down)
            contentView.layer.masksToBounds = false
        } else {
            contentView.layer.vc.borderColor = nil
            contentView.layer.borderWidth = 0.0
            contentView.layer.shadowOffset = .zero
            contentView.layer.shadowColor = UIColor.clear.cgColor
            contentView.layer.shadowRadius = 0.0
            contentView.layer.shadowOpacity = 0.0
        }
    }

    private func updateLayout() {
        let alignment = self.isRegularMode ? self.regularAlignment : self.compactAlignment
        if alignment == .center {
            label.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(self.centerContentInsets.left)
                make.centerY.equalToSuperview()
                make.height.greaterThanOrEqualTo(18.0)

                make.top.greaterThanOrEqualToSuperview().offset(self.centerContentInsets.top)
                make.bottom.lessThanOrEqualToSuperview().offset(-self.centerContentInsets.bottom)
                make.top.equalToSuperview().offset(self.centerContentInsets.top).priority(.veryHigh)
                make.bottom.equalToSuperview().offset(-self.centerContentInsets.bottom).priority(.veryHigh)
            }

            button.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()

                make.left.equalTo(label.snp.right).offset(self.minSpacing)
                make.right.equalToSuperview().offset(-self.centerContentInsets.right)
                make.height.equalTo(18.0)
//                make.top.greaterThanOrEqualToSuperview().offset(self.centerContentInsets.top)
//                make.bottom.lessThanOrEqualToSuperview().offset(-self.centerContentInsets.bottom)
//                make.top.equalToSuperview().offset(self.centerContentInsets.top).priority(.veryHigh)
//                make.bottom.equalToSuperview().offset(-self.centerContentInsets.bottom).priority(.veryHigh)
            }

            contentView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview()
                make.left.greaterThanOrEqualToSuperview().offset(8.0)
                make.right.lessThanOrEqualToSuperview().offset(-8.0)
            }
        } else if alignment == .distribute {
            label.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(self.distributeContentInsets.left)

                make.centerY.equalToSuperview()
                make.height.greaterThanOrEqualTo(18.0)

                make.top.greaterThanOrEqualToSuperview().offset(self.distributeContentInsets.top)
                make.bottom.lessThanOrEqualToSuperview().offset(-self.distributeContentInsets.bottom)
                make.top.equalToSuperview().offset(self.distributeContentInsets.top).priority(.veryHigh)
                make.bottom.equalToSuperview().offset(-self.distributeContentInsets.bottom).priority(.veryHigh)
            }

            button.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()

                make.left.greaterThanOrEqualTo(label.snp.right).offset(self.minSpacing)
                make.right.equalToSuperview().offset(-self.distributeContentInsets.right)

                make.height.equalTo(24.0)
//                make.top.greaterThanOrEqualToSuperview().offset(self.distributeContentInsets.top)
//                make.top.equalToSuperview().offset(self.distributeContentInsets.top).priority(.veryHigh)
//                make.bottom.lessThanOrEqualToSuperview().offset(-self.distributeContentInsets.bottom)
//                make.bottom.equalToSuperview().offset(-self.distributeContentInsets.bottom).priority(.veryHigh)
            }
            contentView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            assert(alignment == .floating)
            label.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(self.floatingContentInsets.left)

                make.centerY.equalToSuperview()
                if Display.phone {
                    make.width.equalTo(labelWidth)
                } else {
                    make.height.greaterThanOrEqualTo(18.0)
                }

                make.top.greaterThanOrEqualToSuperview().offset(self.floatingContentInsets.top)
                make.bottom.lessThanOrEqualToSuperview().offset(-self.floatingContentInsets.bottom)
                make.top.equalToSuperview().offset(self.floatingContentInsets.top).priority(.veryHigh)
                make.bottom.equalToSuperview().offset(-self.floatingContentInsets.bottom).priority(.veryHigh)
            }

            button.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()

                make.left.equalTo(label.snp.right).offset(self.minSpacing)
                make.right.equalToSuperview().offset(-self.floatingContentInsets.right)
                if Display.phone {
                    make.width.equalTo(buttonWidth)
                }
                make.height.equalTo(24.0)
//                make.top.greaterThanOrEqualToSuperview().offset(self.floatingContentInsets.top)
//                make.bottom.lessThanOrEqualToSuperview().offset(-self.floatingContentInsets.bottom)
//                make.top.equalToSuperview().offset(self.floatingContentInsets.top).priority(.veryHigh)
//                make.bottom.equalToSuperview().offset(-self.floatingContentInsets.bottom).priority(.veryHigh)
            }

            contentView.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview()
                if Display.phone {
                    make.width.equalTo(barWidth > 338 ? 338 : barWidth)
                } else {
                    make.left.greaterThanOrEqualToSuperview().offset(60.0)
                    make.right.lessThanOrEqualToSuperview().offset(-60.0)
                    make.width.lessThanOrEqualTo(600).priority(.veryHigh)
                }
            }
        }
    }

    func setButtonText(_ text: String) {
        setButtonText(regular: text, compact: text)
    }
    func setButtonText(regular: String, compact: String) {
        guard btnRegularText != regular || btnCompactText != compact else {
            return
        }
        btnRegularText = regular
        btnCompactText = compact
        updateButtonText()
    }

    func setLabelText(_ text: String) {
        setLabelText(regular: text, compact: text)
    }

    func updateWebinarBar() {
        self.updateButtonText()
        self.updateLabelText()
        self.calContentViewWidth()
        self.updateLayout()
        self.delegate?.notifyComponentChanged(self)
    }

    func setLabelText(regular: String, compact: String) {
        guard labelRegularText != regular || labelCompactText != compact else {
            return
        }
        labelRegularText = regular
        labelCompactText = compact
        updateLabelText()
    }

    //labelWidth: Label每一行长度, callabelWidth = Label全部长度
    private func calContentViewWidth() {
        let callabelWidth = label.sizeThatFits(sizeForCalcText).width
        buttonWidth = button.sizeThatFits(sizeForCalcText).width
        let insets: UIEdgeInsets
        let alignment = self.isRegularMode ? self.regularAlignment : self.compactAlignment
        switch alignment {
        case .center:
            labelWidth = callabelWidth
            insets = centerContentInsets
        case .distribute:
            labelWidth = callabelWidth
            insets = distributeContentInsets
        case .floating:
            labelWidth = callabelWidth > 240 ? 240 : callabelWidth
            insets = floatingContentInsets
        }
        barWidth = labelWidth + buttonWidth + minSpacing + insets.left + insets.right
    }

    @objc
    func backButtonTapped(sender: UIControl) {
        self.buttonAction?(sender)
    }

}
