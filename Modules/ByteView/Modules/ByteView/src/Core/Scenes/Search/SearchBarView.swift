//
//  SearchView.swift
//  ByteView
//
//  Created by huangshun on 2019/6/4.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignIcon

class SearchBarView: UIView {

    var hideSelfClosure: (() -> Void)?

    typealias Param = [NSAttributedString.Key: Any]

    lazy var contentView: UIView = {
        let contentView = UIView(frame: CGRect.zero)
        contentView.layer.cornerRadius = 6
        contentView.backgroundColor = UIColor.ud.udtokenInputBgDisabled
        contentView.clipsToBounds = true
        return contentView
    }()

    lazy var textContentView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [textField, clearButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    lazy var textField: SearchTextField = {
        let textField = SearchTextField.init(frame: CGRect.zero)
        textField.textColor = UIColor.ud.textTitle
        textField.returnKeyType = .search
        textField.enablesReturnKeyAutomatically = true
        textField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        textField.delegate = self
        return textField
    }()

    var editingDidBegin: ((Bool) -> Void)?
    var editingDidEnd: ((Bool) -> Void)?

    lazy var clearButton: UIButton = {
        let clearButton = UIButton(type: .custom)
        clearButton.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16)), for: .normal)
        clearButton.isHidden = true
        clearButton.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: .horizontal)
        clearButton.addTarget(self, action: #selector(clearButtonAction(_:)), for: .touchUpInside)
        return clearButton
    }()

    var tapClearButton: ((Bool) -> Void)?

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom)
        cancelButton.isHidden = true
        cancelButton.alpha = 0
        cancelButton.setTitle(I18n.View_G_CancelButton, for: .normal)
        cancelButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        cancelButton.addTarget(self, action: #selector(cancelButtonAction(_:)), for: .touchUpInside)
        return cancelButton
    }()

    var tapCancelButton: (() -> Void)?

    lazy var shareButton: UIButton = {
        let shareButton = UIButton(type: .custom)
        shareButton.isHidden = true
        shareButton.backgroundColor = UIColor.ud.udtokenInputBgDisabled
        shareButton.layer.cornerRadius = 6
        shareButton.setTitle(I18n.View_M_Invite, for: .normal)
        shareButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        //shareButton.setImage(UDIcon.getIconByKey(.shareOutlined, iconColor: .ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
        //shareButton.setImage(UDIcon.getIconByKey(.shareOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16)), for: .highlighted)
        shareButton.setContentHuggingPriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        shareButton.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1000.0), for: .horizontal)
        shareButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(36)
            maker.width.greaterThanOrEqualTo(76)
        }
        return shareButton
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [contentView, shareButton, cancelButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView(image: UDIcon.getIconByKey(.searchOutlined, iconColor: .ud.iconN3, size: CGSize(width: iconImageDimension, height: iconImageDimension)))
        return iconImageView
    }()

    var iconImageDimension: CGFloat = 16 {
        didSet {
            iconImageView.snp.updateConstraints { (make) in
                make.size.equalTo(CGSize(width: iconImageDimension, height: iconImageDimension))
            }
        }
    }
    var iconImageLeftMargin: CGFloat = 16 {
        didSet {
            iconImageView.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(iconImageLeftMargin)
            }
        }
    }
    var iconImageToContentMargin: CGFloat = 12 {
        didSet {
            textContentView.snp.updateConstraints { (make) in
                make.left.equalTo(iconImageView.snp.right).offset(iconImageToContentMargin)
            }
        }
    }
    var iconImageEditingColor = UIColor.ud.iconN3
    var iconImageNonEditedColor = UIColor.ud.iconN3

    private let textSubject: PublishSubject<String> = PublishSubject()
    var textDidChange: ((String) -> Void)?

    private var editEndCleanBag: DisposeBag?

    var didMoveToSuperViewCompletion: ((SearchBarView) -> Void)?

    private let isNeedCancel: Bool
    var isNeedShare: Bool {
        didSet {
            if !isNeedShare {
                shareButton.isHidden = true
            }
            stackView.setCustomSpacing(isNeedShare ? 6 : 12, after: contentView)
        }
    }

    init(frame: CGRect, isNeedCancel: Bool = false, isNeedShare: Bool = false) {
        self.isNeedCancel = isNeedCancel
        self.isNeedShare = isNeedShare
        super.init(frame: frame)

        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
        }

        contentView.snp.makeConstraints { (make) in
            make.height.equalTo(self.snp.height)
        }

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(iconImageLeftMargin)
            make.size.equalTo(CGSize(width: iconImageDimension, height: iconImageDimension))
        }

        contentView.addSubview(textContentView)
        textContentView.snp.makeConstraints { (make) in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(iconImageView.snp.right).offset(iconImageToContentMargin)
        }

        clearButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.width.equalTo(clearButton.snp.height)
        }

        textField.rx.text
            .map { $0?.isEmpty ?? false }
            .bind(onNext: clearButton.rx.isHidden.onNext)
            .disposed(by: rx.disposeBag)

        clearButton.rx.tap
            .map { nil }
            .bind(onNext: textField.rx.text.onNext)
            .disposed(by: rx.disposeBag)

        clearButton.rx.tap
            .map { "" }
            .bind(onNext: textSubject.onNext)
            .disposed(by: rx.disposeBag)

        clearButton.rx.tap
            .map { true }
            .bind(onNext: clearButton.rx.isHidden.onNext)
            .disposed(by: rx.disposeBag)

        clearButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.textField.becomeFirstResponder()
            })
            .disposed(by: rx.disposeBag)

        addShareActionsIfNeeded()
        addCancelActionsIfNeeded()

        bindColors()
        bindText()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.didMoveToSuperViewCompletion?(self)
    }

    func bindColors() {

        textField.rx.controlEvent([.editingDidBegin])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.iconImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: self.iconImageEditingColor, size: CGSize(width: self.iconImageDimension, height: self.iconImageDimension))
            })
            .disposed(by: rx.disposeBag)

        textField.rx.controlEvent([.editingDidEnd])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if self.textField.text?.isEmpty == true {
                    self.iconImageView.image = UDIcon.getIconByKey(.searchOutlined, iconColor: self.iconImageNonEditedColor, size: CGSize(width: self.iconImageDimension, height: self.iconImageDimension))
                }
            })
            .disposed(by: rx.disposeBag)
    }

    func addShareActionsIfNeeded() {
        guard isNeedShare else { return }

        self.shareButton.isHidden = false

        textField.rx.controlEvent([.editingDidBegin])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                if !self.shareButton.isHidden {
                    self.shareButton.alpha = 0
                }
            })
            .disposed(by: self.rx.disposeBag)

        let hideShareButton = Observable.concat([self.shareButton.rx.hidden(duration: 0.25),
                                                 self.shareButton.rx.fadeOut(duration: 0.25)])
        textField.rx.controlEvent([.editingDidBegin])
            .flatMap { hideShareButton }
            .subscribe()
            .disposed(by: rx.disposeBag)

        let showShareButton = Observable.concat([shareButton.rx.cancelHidden(duration: 0.25),
                                                 shareButton.rx.fadeIn(duration: 0.25)])
        if isNeedCancel {
            cancelButton.rx.tap
                .flatMap { showShareButton }
                .subscribe()
                .disposed(by: rx.disposeBag)
        }
    }

    func addCancelActionsIfNeeded() {
        guard isNeedCancel else { return }

        let showCancelButton = Observable.concat([
            cancelButton.rx.cancelHidden(duration: 0.25),
            cancelButton.rx.fadeIn(duration: 0.25)
        ])
        textField.rx
            .controlEvent([.editingDidBegin])
            .flatMap { showCancelButton }
            .subscribe()
            .disposed(by: rx.disposeBag)

        let hideCancelButton = Observable.concat([
            cancelButton.rx.hidden(duration: 0.25),
            cancelButton.rx.fadeOut(duration: 0.25)
        ])
        cancelButton.rx.tap
            .flatMap { hideCancelButton }
            .subscribe()
            .disposed(by: rx.disposeBag)

        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                self?.hideSelfClosure?()
                self?.resetSearchBar()
            })
            .disposed(by: rx.disposeBag)
    }

    func resetSearchBar() {
        self.textField.text = nil
        self.textSubject.onNext("")
        self.clearButton.isHidden = true
        self.cancelButton.isHidden = true
        self.cancelButton.alpha = 0
        self.shareButton.isHidden = !isNeedShare
        self.shareButton.alpha = isNeedShare ? 1 : 0
        self.stackView.setCustomSpacing(isNeedShare ? 6 : 12, after: contentView)
        if self.textField.isFirstResponder {
            self.textField.resignFirstResponder()
        }
    }

    func bindText() {
        self.setPlaceholder(I18n.View_M_Search)
        textFieldDidChange
            .map { textField -> String in
                guard textField.markedTextRange == nil else {
                    return ""
                }
                return textField.text ?? ""
        }
        .bind(onNext: textSubject.onNext)
        .disposed(by: rx.disposeBag)

        textSubject.subscribe(onNext: { [weak self] text in
            self?.textDidChange?(text)
        })
        .disposed(by: rx.disposeBag)
    }

    func retryCurrentSearch() {
        if let text = textField.text, !text.isEmpty {
            textSubject.onNext(text)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setPlaceholder(_ placeholder: String, attributes: [NSAttributedString.Key: Any]? = nil) {
        let holderAttributes: [NSAttributedString.Key: Any]
        if let attributes = attributes {
            holderAttributes = attributes
        } else {
            holderAttributes = [
                .foregroundColor: UIColor.ud.textPlaceholder,
                .font: UIFont.systemFont(ofSize: 14, weight: .regular)
            ]
        }
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: holderAttributes)
    }

    @objc private func clearButtonAction(_ b: Any) {
        tapClearButton?(textField.isEditing)
    }

    @objc private func cancelButtonAction(_ b: Any) {
        tapCancelButton?()
    }
}

extension SearchBarView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        editingDidBegin?(textField.text?.isEmpty ?? true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        editingDidEnd?(textField.text?.isEmpty ?? true)
    }
}

extension SearchBarView {

    var textFieldDidChange: Observable<UITextField> {
        let field = self.textField
        return textField.rx
            .controlEvent([.editingChanged])
            .map { field }
    }

    var resultTextObservable: Observable<String> {
        return textSubject.asObservable()
    }
}

class SearchTextField: UITextField {
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.placeholderRect(forBounds: bounds)
        return CGRect(x: rect.minX, y: rect.minY, width: rect.width - 16, height: rect.height)
    }
}
