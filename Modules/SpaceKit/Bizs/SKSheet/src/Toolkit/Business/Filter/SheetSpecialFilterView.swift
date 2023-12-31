//
//  SpecialFilterView.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/27.
//

import Foundation
import SKCommon
import SKBrowser
import SKResource
import RxSwift
import UniverseDesignCheckBox
import UniverseDesignInput
import SKUIKit

protocol SheetSpecialFilterViewDelegate: AnyObject {
    func wantedExpand(hasLayout: Bool, view: SheetSpecialFilterView)
    func willBeginTextInput(textField: UITextField, view: SheetSpecialFilterView)
    func willEndTextInput(textField: UITextField, view: SheetSpecialFilterView)
    func requestUpdateColor(value: String, view: SheetSpecialFilterView)
    func requestUpdateSingleText(txt: String, view: SheetSpecialFilterView)
    func requestUpdateTextRange(beginTxt: String, endTxt: String, view: SheetSpecialFilterView)
}

protocol SheetSpecialFilterDriver {
    var identifier: String { get }
    var title: String { get }
    var hitValue: String? { get }
    var expandType: SheetSpecialFilterView.ExpandType { get }
    var isExpand: Bool { get set }
    var valueList: [String] { get }
    var normalHeight: CGFloat { get }
    var expandHeight: CGFloat { get }
}

class SheetSpecialFilterView: UIView, SKColorWellDelegate {

    static let sectionPadding: CGFloat = 16
    static let colorItemWidth: CGFloat = 28 // 选中态的还需要 + 2 * 边框宽度3
    static let colorItemRadius: CGFloat = 6
    static let numberOfColorItemsPerLineForPhone: Int = 7
    static let colorItemSpacingForPad: CGFloat = 18 // 设计稿间距24 - 2 * 边框宽度3

    enum ExpandType {
        case colors, text, textRange, nothing
    }

    let reuseIdentifier = "com.bytedance.ee.docs.sheetfilter.color"

    weak var delegate: SheetSpecialFilterViewDelegate?

    var dataDriver: SheetSpecialFilterDriver

    //资源展开的类型
    var selectButton: UDCheckBox?

    var titleLabel: UILabel?

    //text
    var beginTextField: UDTextField?

    //textRange
    var endTextField: UDTextField?

    private lazy var topView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var colorWell = SKColorWell(delegate: self)

    var appearance: SKColorWell.Appearance {
        (length: Self.colorItemWidth, radius: Self.colorItemRadius)
    }

    var layout: SKColorWell.Layout {
        SKDisplay.pad ? .fixedSpacing(itemSpacing: Self.colorItemSpacingForPad) : .fixedNumber(itemsPerLine: Self.numberOfColorItemsPerLineForPhone)
    }

    private var disposeBag = DisposeBag()

    init(_ driver: SheetSpecialFilterDriver) {
        dataDriver = driver
        super.init(frame: .zero)
        docs.addHover(with: UIColor.ud.N900.withAlphaComponent(0.1), disposeBag: disposeBag)
        clipsToBounds = true
        addSubview(bottomView)
        addSubview(topView)
        addSubview(lineView)

        let topHeight = dataDriver.normalHeight
        let bottomHeight = dataDriver.expandHeight - topHeight

        topView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(topHeight)
            make.left.top.equalToSuperview()
        }

        bottomView.snp.makeConstraints { (make) in
            make.top.equalTo(topView.snp.bottom)
            make.height.equalTo(bottomHeight)
            make.left.right.equalToSuperview()
        }

        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.sectionPadding)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.width.equalToSuperview()
        }

        makeTopViewDetails()
        makeBottomViewDetails()
        updateText(by: dataDriver)
    }

     func updateText(by driver: SheetSpecialFilterDriver) {
        guard driver.identifier == dataDriver.identifier else { return }
        dataDriver = driver
        updateButtonIcon(expand: dataDriver.isExpand)
        switch dataDriver.expandType {
        case .colors:
            colorWell.updateColors(dataDriver.valueList, currentSelectedColor: dataDriver.hitValue)
        case .text:
            beginTextField?.text = dataDriver.valueList.first
        case .textRange:
            beginTextField?.text = dataDriver.valueList.first
            endTextField?.text = dataDriver.valueList.safe(index: 1)
        default:
            ()
        }
    }

    private func makeTopViewDetails() {
        //select button
        let button = UDCheckBox(boxType: .single, config: .init(style: .circle)) { (_) in }
        button.isUserInteractionEnabled = false
        selectButton = button
        topView.addSubview(button)
        button.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(Self.sectionPadding)
            make.centerY.equalToSuperview()
        }
        updateButtonIcon(expand: dataDriver.isExpand)

        //title label
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.text = dataDriver.title
        topView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.equalTo(button.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        titleLabel = label

        //add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapToEdit))
        topView.addGestureRecognizer(tapGesture)
    }

    private func makeBottomViewDetails() {
        switch dataDriver.expandType {
        case .colors:
            decorateColorList()
        case .text:
            decorateSingleText()
        case .textRange:
            decorateTextRange()
        default:
            ()
        }
    }

    func show(isExpand: Bool, layoutNow: Bool) {
        guard dataDriver.isExpand != isExpand else { return }
        dataDriver.isExpand = isExpand
        bottomView.clipsToBounds = !isExpand
        updateButtonIcon(expand: isExpand)
        if isExpand {
            expand(layoutNow: layoutNow)
        } else {
            narrow(layoutNow: layoutNow)
        }
    }

    @objc
    private func tapToEdit() {
        beginTextField?.becomeFirstResponder()
        bottomView.clipsToBounds = false
        delegate?.wantedExpand(hasLayout: false, view: self)
    }

    func updateButtonIcon(expand: Bool) {
        selectButton?.isSelected = expand
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func expand(layoutNow: Bool) {
        guard superview != nil else { return }
        self.snp.updateConstraints { (make) in
            make.height.equalTo(dataDriver.expandHeight)
        }
        if layoutNow {
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }
    }

    private func narrow(layoutNow: Bool) {
        guard superview != nil else { return }
        self.snp.updateConstraints { (make) in
            make.height.equalTo(dataDriver.normalHeight)
        }
        if layoutNow {
            self.layoutIfNeeded()
            self.superview?.layoutIfNeeded()
        }
    }

    func didSelectColor(string: String, index: Int) {
        delegate?.requestUpdateColor(value: string, view: self)
    }

}

extension SheetSpecialFilterView: UDTextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.willBeginTextInput(textField: textField, view: self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.willEndTextInput(textField: textField, view: self)
        reportFinishEdit()
        return true
    }

    func reportFinishEdit() {
        if let beginText = beginTextField?.text, let endText = endTextField?.text {
            delegate?.requestUpdateTextRange(beginTxt: beginText, endTxt: endText, view: self)
        } else if let beginText = beginTextField?.text {
            delegate?.requestUpdateSingleText(txt: beginText, view: self)
        }
    }
}

extension SheetSpecialFilterView {

    private func decorateSingleText() {
        beginTextField = makeTextField()
        if let view = beginTextField { bottomView.addSubview(view) }
        beginTextField?.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview().inset(Self.sectionPadding)
            make.top.equalToSuperview()
            make.height.equalTo(40)
        }
    }

    private func decorateTextRange() {
        let rangeTitleLabel = UILabel()
        rangeTitleLabel.text = BundleI18n.SKResource.Doc_Sheet_And
        rangeTitleLabel.numberOfLines = 1
        bottomView.addSubview(rangeTitleLabel)
        rangeTitleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(20)
        }

        beginTextField = makeTextField()
        endTextField = makeTextField()
        if let view = beginTextField { bottomView.addSubview(view) }
        if let view = endTextField { bottomView.addSubview(view) }

        beginTextField?.snp.makeConstraints { (make) in
            make.left.bottom.equalToSuperview().inset(Self.sectionPadding)
            make.top.equalToSuperview()
            make.height.equalTo(40)
            make.right.equalTo(rangeTitleLabel.snp.left).offset(-8)
        }

        endTextField?.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview().inset(Self.sectionPadding)
            make.top.equalToSuperview()
            make.height.equalTo(40)
            make.left.equalTo(rangeTitleLabel.snp.right).offset(8)
        }
    }

    private func decorateColorList() {
        bottomView.addSubview(colorWell)
        colorWell.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview().inset(Self.sectionPadding)
        }
        colorWell.updateColors(dataDriver.valueList, currentSelectedColor: dataDriver.hitValue)
    }

    private func makeTextField() -> UDTextField {
        let textField = SKUDBaseTextField()
        var config = UDTextFieldUIConfig()
        config.isShowBorder = true
        config.textColor = UIColor.ud.textTitle
        config.font = UIFont.systemFont(ofSize: 14)
        config.textMargins = UIEdgeInsets(edges: 10)
        textField.config = config
        textField.placeholder = BundleI18n.SKResource.Doc_Sheet_InputContent
        textField.delegate = self
        textField.input.returnKeyType = .done
        return textField
    }
}
