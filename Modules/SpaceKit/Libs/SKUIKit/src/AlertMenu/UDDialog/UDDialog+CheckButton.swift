//
//  UDDialog+CheckButton.swift
//  SKUIKit
//
//  Created by guoqp on 2021/7/6.
//

import UniverseDesignDialog
import UniverseDesignCheckBox
import SnapKit
import RxSwift
import RxCocoa
import SKFoundation
import SKResource


// MARK: - contentView
extension UDDialog {
    public var isChecked: Bool {
        get {
            guard let checked = objc_getAssociatedObject(self, &UDDialog._kIsCheckedKey) as? Bool else {
                let checked = false
                self.isChecked = checked
                return checked
            }
            return checked
        }
        set { objc_setAssociatedObject(self, &UDDialog._kIsCheckedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var _kIsCheckedKey: UInt8 = 0

    fileprivate var contentView: ConfirmView {
        get {
            guard let view = objc_getAssociatedObject(self, &UDDialog._kContentViewKey) as? ConfirmView else {
                let view = ConfirmView()
                self.contentView = view
                return view
            }
            return view
        }
        set { objc_setAssociatedObject(self, &UDDialog._kContentViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private static var _kContentViewKey: UInt8 = 0
}

extension UDDialog {
    public func setTitle(
        text: String,
        style: TextStyle = UDDialog.TextStyle.title(),
        checkButton: Bool) {
        if checkButton {
            contentView.setTitle(text, style: style)
            _setContenView()
        } else {
            setTitle(text: text)
        }
    }

    public func setContent(view: UIView, checkButton: Bool) {
        contentView.setDetail(view)
    }

    public func setContent(
        text: String,
        style: TextStyle = UDDialog.TextStyle.content(),
        checkButton: Bool = false) {
        if checkButton {
            contentView.setDetail(text, style: style)
            _setContenView()
        } else {
            setContent(text: text,
                       color: style.color,
                       font: style.font,
                       alignment: style.alignment,
                       lineSpacing: style.lineSpacing,
                       numberOfLines: style.numberOfLines)
        }
    }

    public func setCheckButton(text: String,
                               style: UDCheckBoxUIConfig.Style = .circle,
                               checkAction: ((Bool) -> Void)? = nil) {
        contentView.setCheckButton(text: text, style: style)
        _setContenView()
        _ = contentView.isChecked.distinctUntilChanged().subscribe(onNext: { [weak self] ret in
            self?.isChecked = ret
            checkAction?(ret)
        })
    }

//    public func setCloseButton(_ image: UIImage?,
//                        dismissCheck: @escaping () -> Bool = { true }) {
//        contentView.setCloseButton(image)
//        _ = contentView.closeButton.rx.tap.bind { [weak self] in
//            if dismissCheck() {
//                self?.dismiss(animated: true, completion: nil)
//            }
//        }
//        _setContenView()
//    }

    private func _setContenView() {
        customMode = .checkButton
        setContent(view: contentView)
    }
}


// MARK: - AlertConfirmView
private class ConfirmView: UIView {
    private let disposeBag = DisposeBag()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private var detailView = UIView()
    private(set) var isChecked: BehaviorRelay<Bool> = BehaviorRelay(value: false)
    private let leftOffset = 20

    fileprivate let closeButton: UIButton = {
        let btn = UIButton()
        let defaultImage = BundleResources.SKResource.Common.Close.confirmClose
        btn.setImage(defaultImage, for: .normal)
        btn.setImage(defaultImage, for: .selected)
        btn.setImage(defaultImage, for: .highlighted)
        return btn
    }()

    private(set) lazy var checkBox: UDCheckBox = {
        let config = UDCheckBoxUIConfig(style: .circle)
        let view = UDCheckBox(boxType: .multiple, config: config) { [weak self] _ in
            self?.tapCheckBox()
        }
        return view
    }()

    private(set) lazy var checkTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.sizeToFit()
        label.isUserInteractionEnabled = true
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(closeButton)
        addSubview(checkBox)
        addSubview(checkTitleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(leftOffset)
        }
        detailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(leftOffset)
            make.trailing.lessThanOrEqualToSuperview().offset(-leftOffset)
            make.bottom.equalTo(checkBox.snp.top).offset(-18)
        }
        closeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.right.equalToSuperview().offset(-8)
            make.width.height.equalTo(24)
        }

        checkBox.snp.makeConstraints { make in
            make.width.equalTo(18)
            make.height.equalTo(18)
            make.leading.equalToSuperview().offset(leftOffset)
//            make.bottom.equalToSuperview().offset(-20)
        }
        _setCheckBox()

        checkTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkBox.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-leftOffset)
            make.top.equalTo(checkBox.snp.top)
            make.bottom.equalToSuperview().offset(-18)
        }

        self.snp.makeConstraints { (make) in
            // 避免 iPad 上太长，以及内容太短时没有撑开导致太小
            make.width.equalTo(303)
        }
        closeButton.isHidden = true

        checkTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCheckTitleLabel)))
    }


    @objc
    private func tapCheckTitleLabel() {
        self.isChecked.accept(!self.isChecked.value)
        _setCheckBox()
    }

    @objc
    private func tapCheckBox() {
        self.isChecked.accept(!self.isChecked.value)
        _setCheckBox()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ text: String, style: UDDialog.TextStyle?) {
        titleLabel.text = text
        _setTitleStyle(style)
    }

    func setDetail(_ text: String, style: UDDialog.TextStyle?) {
        detailLabel.text = text
        _setContentStyle(style, text: text)
    }

    func setDetail(_ view: UIView) {
        detailView = view
        _setDetailView(view)
    }

    func setCheckButton(text: String, style: UDCheckBoxUIConfig.Style) {
        checkBox.isHidden = text.isEmpty
        checkTitleLabel.isHidden = text.isEmpty
        guard text.count > 0 else {
            return
        }
        if style != checkBox.config.style {
            var config = checkBox.config
            config.style = style
            checkBox.updateUIConfig(boxType: checkBox.boxType, config: config)
        }
        checkTitleLabel.text = text
        checkBox.snp.updateConstraints { (make) in
            make.height.equalTo(18).labeled("")
        }
    }

    func setCloseButton(_ image: UIImage?) {
        closeButton.isHidden = false
        closeButton.setImage(image, for: .normal)
        closeButton.setImage(image, for: .selected)
        closeButton.setImage(image, for: .highlighted)
    }

    private func _setCheckBox() {
        checkBox.isSelected = self.isChecked.value
    }

    private func _setDetailView(_ view: UIView) {
        detailLabel.removeFromSuperview()
        addSubview(detailView)
        detailView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.equalTo(leftOffset)
            make.trailing.equalTo(-leftOffset)
            make.bottom.equalTo(checkBox.snp.top).offset(-20)
            if SKDisplay.pad {// 对 iPad Alert 过宽调整
                make.width.equalTo(303)
            }
        }
    }

    private func _setTitleStyle(_ style: UDDialog.TextStyle?) {
        guard let sty = style else { return }
        titleLabel.textColor = sty.color
        titleLabel.font = sty.font
        titleLabel.textAlignment = sty.alignment
        titleLabel.numberOfLines = sty.numberOfLines
    }

    private func _setContentStyle(_ style: UDDialog.TextStyle?, text: String) {
        guard let sty = style else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = sty.lineSpacing
        paragraphStyle.alignment = sty.alignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: sty.font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: sty.color
        ]
        detailLabel.attributedText = NSAttributedString(string: text, attributes: attributes)
        detailLabel.numberOfLines = sty.numberOfLines
    }
}
