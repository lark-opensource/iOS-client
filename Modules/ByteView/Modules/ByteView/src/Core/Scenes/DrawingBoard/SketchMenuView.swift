//
//  SketchMenuView.swift
//  ByteView
//
//  Created by Prontera on 2019/11/20.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import ByteViewCommon
import UniverseDesignIcon
import ByteViewUI

enum ActionType {
    case pen
    case highlighter
    case arrow
    case eraser
    case undo
    case exit
    case save
}

protocol ColorButtonDelegate: AnyObject {
    func didTapColorButton(color: UIColor)
}

class ColorButton: FixedTouchSizeButton {
    struct Layout {
        static let whiteCircleSize = CGSize(width: 24, height: 24)
        static let colorfulCircleSize = CGSize(width: 16, height: 16)
    }
    let color: UIColor
    weak var delegate: ColorButtonDelegate?

    init(color: UIColor) {
        self.color = color
        super.init(frame: .zero)
        self.touchSize = CGSize(width: 36, height: 36)
        snp.makeConstraints { (make) in
            make.size.equalTo(Layout.whiteCircleSize)
        }
        setBackgroundImage(UIImage.vc.fromColor(.ud.primaryOnPrimaryFill, size: Layout.whiteCircleSize, cornerRadius: Layout.whiteCircleSize.width / 2), for: .selected)
        self.contentEdgeInsets = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        setImage(UIImage.vc.fromColor(color, size: Layout.colorfulCircleSize, cornerRadius: Layout.colorfulCircleSize.width / 2), for: .normal)
        addInteraction(type: .lift)
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTap() {
        delegate?.didTapColorButton(color: color)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

protocol ActionViewDelegate: AnyObject {
    func didTapAction(action: ActionType)
}

class ActionView: UIView {

    struct Layout {
        static let ActionViewSize = CGSize(width: 54, height: 70)
        static let whiteCircleSize = CGSize(width: 40, height: 40)
        static let iconSize = CGSize(width: 24, height: 24)
    }

    var isEnabled: Bool = true {
        didSet {
            self.setEnableStatus(enable: isEnabled)
        }
    }

    fileprivate let type: ActionType
    weak var delegate: ActionViewDelegate?

    private let disposeBag = DisposeBag()
    lazy var actionButton: UIButton = {
        let button = FixedTouchSizeButton(type: UIButton.ButtonType.custom)
        button.touchSize = CGSize(width: 48, height: 48)
        button.setBackgroundImage(UIImage.vc.fromColor(.ud.primaryOnPrimaryFill, size: Layout.whiteCircleSize, cornerRadius: Layout.whiteCircleSize.width / 2), for: .selected)
        button.layer.ud.setShadowColor(UIColor.ud.vcTokenVCShadowSm)
        button.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        button.layer.shadowRadius = 2.0
        button.layer.shadowOpacity = 0.4
        button.addInteraction(type: .lift)
        button.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        return button
    }()

    var actionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail

        label.layer.ud.setShadowColor(UIColor.ud.vcTokenVCShadowSm)
        label.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 0.4
        return label
    }()

    static let normalAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 13.0
        paragraphStyle.minimumLineHeight = 13.0
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail
        return [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0),
            NSAttributedString.Key.foregroundColor: UIColor.ud.primaryOnPrimaryFill
        ]
    }()

    static let highlightAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 13.0
        paragraphStyle.minimumLineHeight = 13.0
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail
        return [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0),
            NSAttributedString.Key.foregroundColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4)
        ]
    }()

    fileprivate init(type: ActionType) {
        self.type = type
        super.init(frame: .zero)
        setUpUI()
    }

    private func setUpUI() {
        snp.makeConstraints { (make) in
            make.size.equalTo(Layout.ActionViewSize)
        }
        let icon: UDIconType
        let text: String
        switch type {
        case .pen:
            icon = .penOutlined
            text = I18n.View_VM_Pen
        case .highlighter:
            icon = .highlighterOutlined
            text = I18n.View_VM_Highlighter
        case .arrow:
            icon = .insertRightOutlined
            text = I18n.View_VM_Arrow
        case .eraser:
            icon = .eraserOutlined
            text = I18n.View_G_Button_AnnotationEraser
        case .undo:
            icon = .undoOutlined
            text = I18n.View_VM_Undo
        case .exit:
            icon = .logoutOutlined
            text = I18n.View_MV_QuitAnnotation_CanClick
        case .save:
            icon = .downloadOutlined
            text = I18n.View_G_SaveAnnoWhiteBoard_Button
        }
        actionLabel.attributedText = NSAttributedString(string: text,
                                                        attributes: Self.normalAttributes)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: UIColor.ud.primaryOnPrimaryFill, size: Layout.iconSize), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4), size: Layout.iconSize), for: .highlighted)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4), size: Layout.iconSize), for: .disabled)
        actionButton.setImage(UDIcon.getIconByKey(icon, iconColor: UIColor.ud.staticBlack, size: Layout.iconSize), for: .selected)
        addSubview(actionButton)
        actionButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(Layout.whiteCircleSize)
        }
        addSubview(actionLabel)
        actionLabel.snp.makeConstraints { make in
            make.top.equalTo(actionButton.snp.bottom).offset(4)
            make.width.equalTo(54)
            make.centerX.equalToSuperview()
        }
    }

    private func setEnableStatus(enable: Bool) {
        Util.runInMainThread {
            self.actionButton.isEnabled = enable
            self.actionLabel.textColor = enable ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4) & UIColor.ud.textDisabled
        }
    }

    @objc func didTap() {
        delegate?.didTapAction(action: type)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event) {
            let convertedPoint = actionButton.convert(point, from: self)
            let resultView = actionButton.hitTest(convertedPoint, with: event) ?? self
            return resultView
        }
        return nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

protocol SketchMenuViewDelegate: AnyObject {
    func didChangeTool(newTool: ActionType, color: UIColor)
    func didChangeColor(currentTool: ActionType, newColor: UIColor)
    func didTapUndo()
    func didTapExit()
    func didTapSave()
}

class SketchMenuView: UIView {
    var currentTool: ActionType = .pen
    var currentColor: UIColor = UIColor.sketchRed
    weak var delegate: SketchMenuViewDelegate?
    private(set) var isVisible = true
    private var isSaveEnabled: Bool = false

    var backgroundView: UIView?

    private let colorButtons: [ColorButton] = [ColorButton(color: UIColor.sketchRed),
                                               ColorButton(color: UIColor.sketchYellow),
                                               ColorButton(color: UIColor.sketchGreen),
                                               ColorButton(color: UIColor.sketchBlue),
                                               ColorButton(color: UIColor.sketchPurple)]

    private lazy var actionViews: [ActionView] = {
        var actionViews = [
            ActionView(type: .pen),
            ActionView(type: .highlighter),
            ActionView(type: .arrow),
            ActionView(type: .eraser),
            self.undoButton
        ]
        if self.isSaveEnabled {
            actionViews.append(ActionView(type: .save))
        }
        actionViews.append(ActionView(type: .exit))

        return actionViews
    }()

    let undoButton: ActionView = ActionView(type: .undo)

    var currentShareScreenID: String?
    var actionTotalWidth: CGFloat {
        return CGFloat(actionViews.count) * 54.0 + CGFloat(actionViews.count - 1) * 2.0
    }

    var colorTotalWidth: CGFloat {
        return CGFloat(colorButtons.count) * 24.0 + CGFloat(colorButtons.count - 1) * 24.0
    }

    lazy private var topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 24
        return stackView
    }()

    lazy private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isUserInteractionEnabled = true
        scrollView.isScrollEnabled = false
        return scrollView
    }()

    lazy private var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()
    let gradientLayer = CAGradientLayer()

    var usePortraitStyle: Bool {
        return (Display.phone && isPhonePortrait) || (Display.pad && traitCollection.horizontalSizeClass == .compact)
    }

    init(frame: CGRect, isSaveEnabled: Bool) {
        self.isSaveEnabled = isSaveEnabled
        super.init(frame: .zero)
        setUpUI()
        bindDelegate()
    }

    func fadeOut() {
        guard isVisible else {
            return
        }
        isVisible = false
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        })
    }

    func fadeIn() {
        guard !isVisible else {
            return
        }
        isVisible = true
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 1
        })
    }

    func setDefaultConfiguration(color: UIColor, shareScreenID: String, tool: ActionType = .pen) {
        currentTool = tool
        currentColor = color
        setUpActionSelections(type: tool)
        setUpColorSelections(color: color)
        currentShareScreenID = shareScreenID
        delegate?.didChangeTool(newTool: currentTool, color: currentColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.setUpLayout()
    }

    private func bindDelegate() {
        colorButtons.forEach {
            $0.delegate = self
        }
        actionViews.forEach {
            $0.delegate = self
        }
    }

    private func setUpColorSelections(color: UIColor) {
        Util.runInMainThread {
            for button in self.colorButtons {
                button.isSelected = button.color == color
            }
        }
    }

    private func setUpActionSelections(type: ActionType) {
        Util.runInMainThread {
            for view in self.actionViews {
                view.actionButton.isSelected = view.type == type
                if view.actionButton.isSelected {
                    view.actionButton.layer.shadowOpacity = 0.0
                } else {
                    view.actionButton.layer.shadowOpacity = 0.4
                }
            }
        }
    }

    private var lastSize: CGSize = .zero

    private func setUpUI() {
        backgroundColor = .clear
        self.backgroundView = UIView()
        self.backgroundView?.frame = self.frame
        self.backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundView?.isUserInteractionEnabled = false
        setupGradientLayer()
        addSubview(self.backgroundView!)
        addSubview(topStackView)
        addSubview(scrollView)
        scrollView.addSubview(bottomStackView)

        bottomStackView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.height.equalTo(70)
        }

        for button in colorButtons {
            button.removeFromSuperview()
            topStackView.addArrangedSubview(button)
        }
        setUpLayout()
    }

    private func setupGradientLayer() {
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(gradientLayer)
        gradientLayer.ud.setColors([UIColor.ud.N900.withAlphaComponent(0.0) & UIColor.ud.staticBlack.withAlphaComponent(0.0),
                                    UIColor.ud.N900.withAlphaComponent(0.24) & UIColor.ud.staticBlack.withAlphaComponent(0.24)])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let offset: CGFloat = usePortraitStyle ? -54 : -25
        let backgroundLayerHeight: CGFloat = usePortraitStyle ? 200.0 : 160.0
        gradientLayer.frame = CGRect(x: 0.0,
                                     y: offset,
                                     width: self.layer.bounds.width,
                                     height: backgroundLayerHeight)
        if self.lastSize != self.bounds.size {
            setUpUI()
        }
        lastSize = self.bounds.size
    }

    let landscapeColorsWrapper = UIView()

    private func isNeedScroll() -> Bool {
        if usePortraitStyle {
            return VCScene.bounds.width < (actionTotalWidth + 12.0)
        } else {
            let totalWidth = actionTotalWidth + colorTotalWidth + 24.0 + 12.0
            return VCScene.bounds.width < totalWidth
        }
    }

    private func setUpLayout() {
        landscapeColorsWrapper.removeFromSuperview()
        let shouldScroll = isNeedScroll()
        scrollView.isScrollEnabled = shouldScroll
        for view in actionViews {
            view.actionLabel.numberOfLines = usePortraitStyle ? 2 : 1
        }
        if usePortraitStyle {
            for view in actionViews {
                view.removeFromSuperview()
                bottomStackView.addArrangedSubview(view)
            }
            self.addSubview(topStackView)
            topStackView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        } else {
            topStackView.removeFromSuperview()
            landscapeColorsWrapper.addSubview(topStackView)
            landscapeColorsWrapper.snp.remakeConstraints { make in
                make.height.equalTo(70)
            }
            topStackView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.left.right.equalToSuperview().inset(11)
            }
            for view in actionViews {
                view.removeFromSuperview()
                if view.type == .undo {
                    bottomStackView.addArrangedSubview(landscapeColorsWrapper)
                }
                bottomStackView.addArrangedSubview(view)
            }
        }

        let totalContentWidth = actionTotalWidth + colorTotalWidth + 24
        scrollView.snp.remakeConstraints { make in
            if usePortraitStyle {
                make.top.equalTo(topStackView.snp.bottom).offset(14)
            } else {
                make.top.equalToSuperview()
            }
            if shouldScroll {
                make.left.right.equalToSuperview().inset(6)
            } else {
                make.centerX.equalToSuperview()
                make.width.equalTo(usePortraitStyle ? actionTotalWidth : totalContentWidth)
            }
            make.height.equalTo(70)
            make.bottom.equalToSuperview().offset(-4.0)
        }
        if usePortraitStyle {
            scrollView.contentSize = CGSize(width: actionTotalWidth, height: 70)
        } else {
            let totalContentWidth = actionTotalWidth + colorTotalWidth + 24
            scrollView.contentSize = CGSize(width: totalContentWidth, height: 70)
        }
    }
}

extension SketchMenuView: ActionViewDelegate, ColorButtonDelegate {
    func didTapColorButton(color: UIColor) {
        currentColor = color
        delegate?.didChangeColor(currentTool: currentTool, newColor: color)
        setUpColorSelections(color: color)
    }

    func didTapAction(action: ActionType) {
        if [.pen, .highlighter, .arrow, .eraser].contains(action) {
            currentTool = action
            delegate?.didChangeTool(newTool: action, color: currentColor)
            setUpActionSelections(type: action)
        } else if action == .undo {
            delegate?.didTapUndo()
        } else if action == .exit {
            delegate?.didTapExit()
        } else if action == .save {
            delegate?.didTapSave()
        }
    }
}

extension UIColor {

    class var sketchRed: UIColor { return UIColor(hex: "#F54A45") }
    class var sketchYellow: UIColor { return UIColor(hex: "#FFC60A") }
    class var sketchGreen: UIColor { return UIColor(hex: "#35BD4B") }
    class var sketchBlue: UIColor { return UIColor(hex: "#336DF4") }
    class var sketchPurple: UIColor { return UIColor(hex: "#8D55ED") }
    var sketchName: String {
        switch self {
        case UIColor.sketchRed:
            return "red"
        case UIColor.sketchBlue:
            return "blue"
        case UIColor.sketchGreen:
            return "green"
        case UIColor.sketchYellow:
            return "yellow"
        case UIColor.sketchPurple:
            return "purple"
        default:
            return ""
        }
    }

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexValue = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexValue.hasPrefix("#") {
            hexValue.remove(at: hexValue.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
