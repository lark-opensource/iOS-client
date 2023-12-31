//
//  AINamePickerView.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/26.
//

import UIKit
import RxSwift
import RxCocoa
import FigmaKit
import UniverseDesignColor
import UniverseDesignInput

class AINamePickerView: UIView, UDTextFieldDelegate {

    let disposeBag = DisposeBag()

    var text: String? {
        textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var presetNames: [String] {
        didSet {
            nameScrollPicker.names = presetNames
        }
    }

    var onTextChange: ((String?) -> Void)?

    @discardableResult
    override func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
        return super.resignFirstResponder()
    }

    lazy var textField: UDTextField = {
        let view = AIUtils.makeAINameTextField()
        view.config.font = Cons.textFieldFont
        view.config.textAlignment = .center
        return view
    }()

    lazy var nameScrollPicker: AINameScrollPickerView = {
        let view = AINameScrollPickerView()
        view.showsHorizontalScrollIndicator = false
        view.selectedNameCallBack = { [weak self] name in
            self?.textField.text = name
            self?.onTextChange?(name)
        }
        view.names = presetNames
        view.clipsToBounds = false
        return view
    }()

    lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = BundleI18n.LarkAI.MyAI_IM_Onboarding_ChooseName_Text
        view.font = Cons.labelFont
        view.textColor = .ud.textCaption
        view.textAlignment = .center
        return view
    }()

    init(presetNames: [String]) {
        self.presetNames = presetNames
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(nameScrollPicker)

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(Cons.labelHeight)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
        }
        textField.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(Cons.labelTextFieldSpacing)
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(Cons.textFieldHeight)
        }
        nameScrollPicker.snp.makeConstraints { (make) in
            make.top.equalTo(textField.snp.bottom).offset(Cons.textFieldScrollPickerSpacing)
            make.left.right.equalTo(titleLabel)
            make.height.equalTo(Cons.scrollPickerHeight)
            make.bottom.equalToSuperview()
        }

        // 默认选中第一个候选名称
        DispatchQueue.main.async {
            if !self.presetNames.isEmpty {
                self.nameScrollPicker.setSelectIndex(0)
            }
        }

        // 输入发生变化时，重置 NamePicker 选中状态和按钮可用状态
        textField.input.rx.value.asDriver().drive(onNext: { [weak self] value in
            let value = value?.lf.trimCharacters(in: .whitespacesAndNewlines, postion: .both)
            if let currentName = self?.nameScrollPicker.currentSelectedItem?.name,
               value != currentName {
                self?.nameScrollPicker.setSelectNone()
            }
            self?.onTextChange?(value)
        }).disposed(by: self.disposeBag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 重设渐变色（渐变色要根据 bounds 重新计算）
        let size = textField.bounds.size
        let borderColor = UDColor.AIPrimaryContentDefault.toColor(withSize: size)
        textField.config.borderActivatedColor = borderColor
        let textColor = UDColor.AIPrimaryContentDefault.toColor(withSize: CGSize(width: size.width * 1.5, height: size.height))
        textField.config.textColor = textColor
    }
}

// MARK: - AINameScrollPickerView

class AINameScrollPickerView: UIScrollView {

    var selectedNameCallBack: ((String) -> Void)?

    var currentSelectedItem: (index: Int, name: String)?

    var names: [String] = [] {
        didSet {
            updateItemViews()
        }
    }

    func setSelectNone() {
        if let currentSelectedItem = self.currentSelectedItem,
           self.itemViews.count > currentSelectedItem.index {
            self.itemViews[currentSelectedItem.index].isSelected = false
        }
        currentSelectedItem = nil
    }

    func setSelectIndex(_ selectedIndex: Int) {
        guard selectedIndex < names.count else { return }
        for (index, itemView) in itemViews.enumerated() {
            itemView.isSelected = index == selectedIndex
        }
        currentSelectedItem = (selectedIndex, names[selectedIndex])
        selectedNameCallBack?(names[selectedIndex])
    }

    private lazy var stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = AINamePickerView.Cons.nameItemSpacing
        return stack
    }()

    private lazy var paddingView = UIView()

    private var itemViews: [AINamePickerItemView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.left.right.equalTo(self.contentLayoutGuide)
            make.height.equalTo(self.safeAreaLayoutGuide)
        }
        stack.addArrangedSubview(paddingView)
        stack.setCustomSpacing(0, after: paddingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeButton(_ title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        return button
    }

    func makePaddingView() -> UIView {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    private func centerItemsIfNeeded() {
        paddingView.isHidden = true
        layoutIfNeeded()
        DispatchQueue.main.async {
            if self.stack.frame.width < self.bounds.width {
                self.paddingView.snp.remakeConstraints { make in
                    make.width.equalTo((self.bounds.width - self.stack.frame.width) / 2)
                }
                self.paddingView.isHidden = false
            }
        }
    }

    private func updateItemViews() {
        for itemView in itemViews {
            itemView.removeFromSuperview()
        }
        itemViews.removeAll()
        for (index, name) in names.enumerated() {
            let itemView = AINamePickerItemView(onSelectBlock: { [weak self] in
                guard let self = self else { return }
                self.setSelectNone()
                self.currentSelectedItem = (index: index, name: name)
                self.selectedNameCallBack?(name)
            })
            itemView.setText(name)
            itemViews.append(itemView)
            stack.addArrangedSubview(itemView)
        }
        centerItemsIfNeeded()
    }
}

class AINamePickerItemView: UIView {

    var isSelected: Bool = false {
        didSet {
            guard isSelected != oldValue else { return }
            updateColor()
        }
    }
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = AINamePickerView.Cons.nameItemFont
        label.textColor = .ud.textCaption
        return label
    }()

    private lazy var background = UIView()

    var onSelectBlock: (() -> Void)?

    override var bounds: CGRect {
        didSet {
            guard bounds != oldValue else { return }
            updateColor()
        }
    }

    init(onSelectBlock: (() -> Void)? = nil) {
        self.onSelectBlock = onSelectBlock
        super.init(frame: .zero)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(AINamePickerView.Cons.nameItemHPadding)
            make.right.equalToSuperview().offset(-AINamePickerView.Cons.nameItemHPadding)
        }
        self.snp.makeConstraints { make in
            make.height.equalTo(AINamePickerView.Cons.nameItemHeight)
        }
        layer.borderWidth = 1
        layer.cornerRadius = AINamePickerView.Cons.nameItemHeight / 2
        layer.masksToBounds = true
        updateColor()
        self.lu.addTapGestureRecognizer(action: #selector(onTapped), target: self)
    }

    @objc
    func onTapped() {
        guard !isSelected else { return }
        onSelectBlock?()
        self.isSelected = true
    }

    func setText(_ value: String) {
        label.text = value
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColor()
        }
    }

    private func updateColor() {
        if #available(iOS 13.0, *) {
            traitCollection.performAsCurrent {
                updateColorInternal()
            }
        } else {
            updateColorInternal()
        }
    }

    private func updateColorInternal() {
        if isSelected {
            let gradientColor = UDColor.AIPrimaryContentPressed.toColor(withSize: bounds.size)
            self.label.textColor = gradientColor
            self.layer.borderColor = gradientColor?.cgColor
            self.backgroundColor = UDColor.AIPrimaryFillSolid02.toColor(withSize: bounds.size)
        } else {
            self.label.textColor = UIColor.ud.textCaption
            self.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
            self.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
        }
    }
}

extension AINamePickerView {
    enum Cons {
        static let vMargin: CGFloat = 12    // UI 元素离组件边缘的垂直距离
        static let hMargin: CGFloat = 16    // UI 元素离组件边缘的水平距离

        static let avatarPickerCenterYOffsetWhenKeyboardFold: CGFloat = 131

        static let labelHeight: CGFloat = 20
        static var labelFont: UIFont { UIFont.ud.body2(.fixed) }

        static var labelTextFieldSpacing: CGFloat = 8
        static var textFieldHeight: CGFloat = 48
        static var textFieldFont: UIFont { UIFont.ud.body0(.fixed) }
        static var textFieldScrollPickerSpacing: CGFloat = 8

        static let nameItemHPadding: CGFloat = 16
        static let nameItemHeight: CGFloat = 36
        static let nameItemSpacing: CGFloat = 8
        static var nameItemFont: UIFont { UIFont.ud.body0(.fixed) }
        static var scrollPickerHeight: CGFloat = 52

        static var totalHeight: CGFloat {
            labelHeight
            + labelTextFieldSpacing
            + textFieldHeight
            + textFieldScrollPickerSpacing
            + scrollPickerHeight
        }
    }
}
