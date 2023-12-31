//
//  V3FlatField.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/12/11.
//

import Foundation
import SnapKit
import LKCommonsLogging
import UniverseDesignIcon

extension V3FlatTextField {
    struct Layout {
        static let changableLabelWidth: CGFloat = 75
        static let unchangableLabelWidth: CGFloat = 50
        static let splitWidth: CGFloat = 1
        static let chanableSplitLeftSpace: CGFloat = 85
        static let unchanableSplitLeftSpace: CGFloat = 62
        static let roundedBorderRadius: CGFloat = Common.Layer.commonTextFieldRadius
        static let roundedBorderLineWidth: CGFloat = 1
        static let selectBtnRightSpace: CGFloat = 12
        static let selectBtnWidth: CGFloat = 16
        static let selectBtnHeight: CGFloat = 16
        static let plusLabelAndLabelSpace: CGFloat = 0
        static let labelAndSelectButtonSpace: CGFloat = 6
        static let labelAndSplitLineSpace: CGFloat = 12

    }
}

class V3FlatTextField: UIView {
    enum TypeEnum {
        case `default`, phoneNumber, email
    }

    lazy var textFiled: CustomTextField = {
        let actions = enableTextFieldPaste ? [] : [#selector(UITextField.paste(_:))]
        let textFiled = CustomTextField(disableActions: actions)
        textFiled.contentVerticalAlignment = .center
        textFiled.tintColor = UIColor.ud.primaryContentDefault
        textFiled.clearButtonMode = .whileEditing
        textFiled.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return textFiled
    }()

    lazy var label: UITextField = {
        let label = UITextField(frame: .zero)
        label.keyboardType = .phonePad
        label.contentVerticalAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    lazy var plusLabel: UITextField = {
        let label = UITextField(frame: .zero)
        label.keyboardType = .phonePad
        label.contentVerticalAlignment = .center
        label.textAlignment = .center
        label.text = "+"
        label.textColor = UIColor.ud.textTitle
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.isEnabled = false
        return label
    }()

    lazy var splitLineContainer: ShapeLayerContainerView = {
        return ShapeLayerContainerView()
    }()

    var splitLine: CAShapeLayer? {
        return splitLineContainer.shapeLayer
    }

    let borderContainer: V3BorderView

    var type: TypeEnum = .phoneNumber {
        didSet {
            if type != oldValue {
                initKeyboardType()
            }
        }
    }

    var format: [Int] = [] {
        willSet {
            if newValue != format {
                self.text = nil
            }
        }
    }

    var formatSplitChar: String = " "

    var labelFont: UIFont? {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }

    var labelTextColor: UIColor? {
        get {
            return label.textColor
        }
        set {
            label.textColor = newValue
        }
    }

    var enableTextFieldPaste: Bool = true

    var textFieldFont: UIFont? {
        get {
            return textFiled.font
        }
        set {
            self.textFiled.font = newValue
        }
    }

    var textFieldTextColor: UIColor? {
        get {
            return textFiled.textColor
        }
        set {
            textFiled.textColor = newValue
        }
    }

    var text: String? {
        get {
            return textFiled.text
        }
        set {
            textFiled.text = newValue
        }
    }

    var placeholderTextColor: UIColor? {
        get {
            return textFiled.value(forKeyPath: "placeholderLabel.textColor") as? UIColor
        }
        set {
            textFiled.setValue(newValue, forKeyPath: "placeholderLabel.textColor")
        }
    }

    /// 只有左右距离会生效
    var labelInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0) {
        didSet {
            setNeedsLayout()
        }
    }

    /// 只有左右距离会生效
    var textFiledInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 17, bottom: 0, right: 6) {
        didSet {
            setNeedsLayout()
        }
    }

    var splitLineColor: UIColor = UIColor.ud.lineBorderCard {
        didSet {
            drawLines()
        }
    }

    var inputHeight: CGFloat = 24 {
        didSet {
            label.frame.size.height = inputHeight
            textFiled.frame.size.height = inputHeight
            setNeedsLayout()
        }
    }

    var labelText: String? {
        get {
            return "+\(label.text ?? "")"
        }
        set {
            label.text = newValue?.replacingOccurrences(of: "+", with: "")
        }
    }

    var labelAttributedText: NSAttributedString? {
        didSet {
            label.attributedText = labelAttributedText
        }
    }

    var placeHolder: String? {
        didSet {
            textFiled.placeholder = placeHolder
        }
    }

    var attributedPlaceholder: NSAttributedString? {
        didSet {
            textFiled.attributedPlaceholder = attributedPlaceholder
        }
    }

    var disableLabel: Bool = false {
        didSet {
            setupLabel()
            setupTextFeild()
        }
    }

    var currentText: String? {
        if label.text == nil, textFiled.text == nil {
            return nil
        }
        var labelText = ""
        if !disableLabel {
            labelText = self.labelText ?? ""
        }
        var contentText = ""
        switch type {
        case .phoneNumber:
            contentText = labelText + (textFiled.text?.replacingOccurrences(of: " ", with: "") ?? "")
        default:
            contentText = labelText + (textFiled.text ?? "")
        }
        if type == .default {
            contentText = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // phone or email shouldnt have space or newline
            contentText = contentText.filter({ !$0.isWhitespace && !$0.isNewline })
        }
        // replace pinyin space if has, usually happy when inputting email using pinyin
        return contentText.replacingOccurrences(of: pinyinSpace, with: "")
    }

    weak var delegate: V3FlatTextFieldDelegate?

    var proxy: V3FlatTextFieldDelegateProxy?

    private let labelChangable: Bool

    private lazy var selectBtn: UIButton = {
        let btn = UIButton(type: .custom)
        let selectImage = BundleResources.UDIconResources.downBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        btn.setBackgroundImage(selectImage, for: .normal)
        btn.isUserInteractionEnabled = false
        btn.setContentHuggingPriority(.required, for: .horizontal)
        return btn
    }()
    let labelTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)
    private lazy var tapView: UIView = {
        /// iOS 10 上 textField 禁用交互，还能输入所以换用mask
        let v = UIView()
        v.addGestureRecognizer(labelTapGesture)
        v.isUserInteractionEnabled = true
        return v
    }()

    fileprivate func setupLabel() {
        if !disableLabel {
            labelTextColor = labelChangable ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder
            plusLabel.textColor = labelChangable ? UIColor.ud.textTitle : UIColor.ud.textPlaceholder
            labelTapGesture.isEnabled = labelChangable
            if plusLabel.superview == nil {
                addSubview(plusLabel)
            }
            if label.superview == nil {
                addSubview(label)
            }
            if splitLineContainer.superview == nil {
                addSubview(splitLineContainer)
            }
            if tapView.superview == nil {
                addSubview(tapView)
            }
            if labelChangable, selectBtn.superview == nil {
                addSubview(selectBtn)
                bringSubviewToFront(tapView)
                selectBtn.snp.remakeConstraints({ (make) in
                    make.right.equalTo(splitLineContainer.snp.left).offset(-Layout.selectBtnRightSpace)
                    make.size.equalTo(CGSize(width: Layout.selectBtnWidth, height: Layout.selectBtnHeight))
                    make.centerY.equalTo(label)
                })
            } else {
                selectBtn.removeFromSuperview()
            }
            tapView.snp.remakeConstraints({ (make) in
                make.top.bottom.equalTo(label)
                make.left.equalTo(plusLabel)
                make.right.equalTo(splitLineContainer.snp.left)
            })
            plusLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(labelInsets.left)
                make.centerY.equalToSuperview().offset(-1)
            }
            label.snp.remakeConstraints { (make) in
                make.left.equalTo(plusLabel.snp.right).offset(Layout.plusLabelAndLabelSpace)
                make.centerY.equalToSuperview()
                if labelChangable {
                    make.right.equalTo(selectBtn.snp.left).offset(-Layout.labelAndSelectButtonSpace)
                } else {
                    make.right.equalTo(splitLineContainer.snp.left).offset(-Layout.labelAndSplitLineSpace)
                }
            }
            splitLineContainer.snp.remakeConstraints { (make) in
                make.width.equalTo(Layout.splitWidth)
                make.centerY.equalToSuperview()
                make.height.equalTo(inputHeight + 2)
            }
        } else {
            label.removeFromSuperview()
            plusLabel.removeFromSuperview()
            selectBtn.removeFromSuperview()
            tapView.removeFromSuperview()
            splitLineContainer.removeFromSuperview()
        }
    }

    fileprivate func setupTextFeild() {
        textFiled.snp.remakeConstraints { (make) in
            if !disableLabel {
                make.left.equalTo(splitLineContainer.snp.right).offset(textFiledInsets.left)
            } else {
                make.left.equalToSuperview().offset(textFiledInsets.left)
            }
            make.right.equalToSuperview().inset(textFiledInsets.right)
            make.height.equalTo(inputHeight)
            make.centerY.equalToSuperview()
        }
        proxy = V3FlatTextFieldDelegateProxy(target: self)
        textFiled.delegate = proxy
    }

    var hasError: Bool {
        set {
            borderContainer.state = newValue ? .error : .normal
        }

        get {
            borderContainer.state == .error
        }
    }

    private func setupBorderView() {
        borderContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    init(borderStyle: V3BorderView.BorderStyle = .roundedBorder, type: TypeEnum = .default, enableTextPaste: Bool = true, labelChangable: Bool = true) {
        self.borderContainer = V3BorderView(borderStyle: borderStyle)
        self.type = type
        self.enableTextFieldPaste = enableTextPaste
        self.labelChangable = labelChangable
        super.init(frame: .zero)
        addSubview(borderContainer)
        addSubview(textFiled)
        setupBorderView()
        setupLabel()
        setupTextFeild()
        initKeyboardType()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func endEditing(_ force: Bool) -> Bool {
        return textFiled.endEditing(force)
    }

    func formatMaxLength() -> Int {
        // 在日本区号的条件下，如果首位为0，长度从10位变成11位
        let maxLength = format.reduce(0, { $0 + $1 }) + (format.count - 1) * formatSplitChar.count
        if self.labelText == "+81" && text?.first == "0"{
            return maxLength + 1
        }
        return maxLength
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textFiled.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textFiled.resignFirstResponder()
    }
}

extension V3FlatTextField {
    func setTextWithFormat(_ input: String) {
        text = formatInputText(input)
    }
}

extension V3FlatTextField {

    override func layoutSubviews() {
        super.layoutSubviews()
        drawLines()
    }

    func drawSplitLine() {
        guard let splitLine = splitLine else { return }
        let rect = splitLineContainer.bounds
        if rect.isEmpty {
            return
        }
        splitLine.ud.setFillColor(splitLineColor)
        splitLine.ud.setStrokeColor(splitLineColor)
        splitLine.lineWidth = ONE_PIXEL
        if disableLabel {
            splitLine.backgroundColor = UIColor.clear.cgColor
        } else {
            splitLine.backgroundColor = splitLineColor.cgColor
        }
    }

    func drawLines() {
        drawSplitLine()
    }

    func initKeyboardType() {
        switch type {
        case .default:
            textFiled.keyboardType = .default
        case .email:
            textFiled.keyboardType = .emailAddress
            textFiled.autocorrectionType = .no
            textFiled.autocapitalizationType = .none
            textFiled.spellCheckingType = .no
        case .phoneNumber:
            textFiled.keyboardType = .phonePad
        }
    }

    func formatInputText(_ text: String) -> String {
        guard !format.isEmpty else {
            return text
        }
        //日本区号情况下特殊处理，0开头可以输入多一位
        var formatHandled = format
        if self.labelText == "+81" && text.first == "0"{
            formatHandled[0] += 1
        }
        var start = 0
        let subtexts = formatHandled.map { (i) -> NSRange in
            defer {
                start += i
            }
            return NSRange(location: start, length: i)
        }.compactMap { (range) -> String? in
            text.substring(in: range)
        }
        return subtexts.joined(separator: formatSplitChar)
    }
}

class V3FlatTextFieldDelegateProxy: NSObject, UITextFieldDelegate {
    weak var target: V3FlatTextField?

    init(target: V3FlatTextField) {
        self.target = target
        super.init()
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard let target = target else {
            return true
        }
        return target.delegate?.textFieldShouldBeginEditing(target) ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let target = target else {
            return
        }
        target.borderContainer.state = target.hasError ? .error : .hilighted
        target.delegate?.textFieldDidBeginEditing(target)
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        guard let target = target else {
            return true
        }
        return target.delegate?.textFieldShouldEndEditing(target) ?? true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let target = target else {
            return
        }
        target.borderContainer.state = .normal
        target.delegate?.textFieldDidEndEditing(target)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var range = range
        guard let target = target else {
            return false
        }
        var string = string
        if target.type == .phoneNumber && string.count > 1 && range.location == 0 && range.length == 0 {
            string = self.filterContactsPhoneNumber(number: string)
            string = target.formatInputText(string) // 解决 iPad 支持粘贴手机号，粘贴后下一步不能点击问题
        } else if target.type == .email {
            // Remove emojis in case of freeze
            if string.contains(where: { $0.isEmoji }) {
                return false
            }
        }
        let res = target.delegate?.textField(target, shouldChangeCharactersIn: range, replacementString: string) ?? true
        var textString = ""
        if target.type == .phoneNumber, let currentText = textField.text {
            guard !target.format.isEmpty else {
                return true
            }
            if currentText.substring(in: range) == " " {
                range = NSRange(location: range.location - 1, length: range.length)
            }
            textString = currentText
            if let lowerBoundIndex = currentText.index(currentText.startIndex, offsetBy: range.lowerBound, limitedBy: currentText.endIndex),
               let upperBoundIndex = currentText.index(currentText.startIndex, offsetBy: range.upperBound, limitedBy: currentText.endIndex) {
                let indexRange = lowerBoundIndex..<upperBoundIndex

                textString.replaceSubrange(
                    indexRange,
                    with: string
                )

                textString = self.filterContactsPhoneNumber(number: textString)
                textField.text = target.formatInputText(textString)

                if let rangeStart = textField.position(from: textField.endOfDocument, in: UITextLayoutDirection.left, offset: currentText.count - (range.location + range.length)) {
                    textField.selectedTextRange = textField.textRange(from: rangeStart, to: rangeStart)
                }
            }

            return false
        }
        return res
    }

    func filterContactsPhoneNumber(number: String) -> String {
        let result = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return result
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        guard let target = target else {
            return true
        }
        return target.delegate?.textFieldShouldClear(target) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let target = target else {
            return true
        }
        return target.delegate?.textFieldShouldReturn(target) ?? true
    }
}

protocol V3FlatTextFieldDelegate: AnyObject {
    func textFieldShouldBeginEditing(_ textField: V3FlatTextField) -> Bool
    func textFieldDidBeginEditing(_ textField: V3FlatTextField)
    func textFieldShouldEndEditing(_ textField: V3FlatTextField) -> Bool
    func textFieldDidEndEditing(_ textField: V3FlatTextField)
    func textField(_ textField: V3FlatTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    func textFieldShouldClear(_ textField: V3FlatTextField) -> Bool
    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool
}

extension V3FlatTextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: V3FlatTextField) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: V3FlatTextField) { }

    func textFieldShouldEndEditing(_ textField: V3FlatTextField) -> Bool {
        return true
    }

    func textFieldDidEndEditing(_ textField: V3FlatTextField) { }

    func textField(_ textField: V3FlatTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }

    func textFieldShouldClear(_ textField: V3FlatTextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        return true
    }
}

/// 1. custom clear btn; 2. custom action
class CustomTextField: UITextField {

    private let disableActions: [Selector]

    init(disableActions: [Selector] = []) {
        self.disableActions = disableActions
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if disableActions.contains(action) {
            return false
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }
}

let pinyinSpace = "\u{2006}"
let ONE_PIXEL = 1 / UIScreen.main.scale
