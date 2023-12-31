//
//  BTNumberKeyboardView.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/12.
//  

import UIKit
import RxSwift
import Foundation
import SKFoundation
import UniverseDesignColor

final class BTNumberKeyboardView: UIInputView {
    var commonTrackParams: [String: Any]?
    private weak var target: (UIKeyInput & UITextInput)?
    private let bag = DisposeBag()
    private let items: [[BTNumberKeyboardKeyType]] = [
        [.digital(7), .digital(4), .digital(1), .function(.point)],
        [.digital(8), .digital(5), .digital(2), .digital(0)],
        [.digital(9), .digital(6), .digital(3), .function(.sign)],
        [.function(.delete), .function(.done)]
    ]
    private let disableItems: [BTNumberKeyboardKeyType]
    private var itemViews: [[BTNumberKeyboardButton]] = []
    private let itemViewContentProvider = BTNumberKeyContentProviderImpl()
    private let layout: BTNumberKeyboardLayout = BTNumberKeyboardLayoutImpl()
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var horizontalStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = layout.spacing
        sv.alignment = .fill
        return sv
    }()
    private var verticalStackViews: [UIStackView] = []
    
    init(target: UIKeyInput & UITextInput, disableKeys: [BTNumberKeyboardKeyType] = []) {
        self.target = target
        disableItems = disableKeys
        super.init(frame: .zero, inputViewStyle: .keyboard)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        self.backgroundColor = UIColor.ud.N300 & UIColor.ud.bgBodyOverlay.alwaysDark
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
            make.width.equalTo(BTNumberKeyboardLayoutImpl.preferedTotalSize.width)
        }
        container.addSubview(horizontalStackView)
        horizontalStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(layout.margin)
        }
        let minItemHeight = minItemHeight()
        for column in items {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.distribution = .fill
            stackView.spacing = layout.spacing
            stackView.alignment = .fill
            horizontalStackView.addArrangedSubview(stackView)
            var columnItemViews: [BTNumberKeyboardButton] = []
            for i in 0..<column.count {
                let type = column[i]
                let disable = disableItems.contains(where: { $0 == type })
                let itemView = createItemView(type, disable: disable)
                stackView.addArrangedSubview(itemView)
                columnItemViews.append(itemView)
                guard i < column.endIndex - 1 else { continue }
                itemView.snp.makeConstraints { make in
                    make.height.equalTo(minItemHeight)
                }
            }
            itemViews.append(columnItemViews)
        }
    }
    
    private func minItemHeight() -> CGFloat {
        let h = (self.frame.height - self.safeAreaInsets.bottom - layout.margin * 2.0 - layout.spacing * 3.0) / 4
        return h
    }
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        updateLayout()
    }
    private func updateLayout() {
        let minItemHeight = minItemHeight()
        itemViews.flatMap({ $0.dropLast() })
            .forEach({
                $0.snp.updateConstraints { make in
                    make.height.equalTo(minItemHeight)
                }
            })
    }
    override var intrinsicContentSize: CGSize {
        var activeSize = BTNumberKeyboardLayoutImpl.preferedTotalSize
        return activeSize
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 17.0, *) {
            // iOS 17，上方 layoutMarginsDidChange 中 self.frame.height 为 0，布局将会异常
            // 这里在 layoutSubviews 可以获取到有效的 self.frame.height 高度
            updateLayout()
        }
    }
}

extension BTNumberKeyboardView {
    func createItemView(_ key: BTNumberKeyboardKeyType, disable: Bool = false) -> BTNumberKeyboardButton {
        let button = BTNumberKeyboardButton(type: .custom)
        button.rx.tap.subscribe(onNext: { [weak self] in
            self?.didClick(key: key)
        }).disposed(by: bag)
        if key == .function(.delete) {
            button.longPress(timeInterval: 0.2).subscribe(onNext: { [weak self] index in
                self?.handleDelete(count: index < 3 ? 1 : 3)
            }).disposed(by: bag)
        }
        button.titleLabel?.font = UIFont(name: "DINAlternate-Bold", size: 24)
        button.normalBgColor = itemViewContentProvider.normalBgColor(key)
        button.highlightBgColor = itemViewContentProvider.highlightBgColor(key)
        button.layer.cornerRadius = 4
        if itemViewContentProvider.needShadowColor(key) {
            button.layer.shadowColor = UIColor.docs.rgb("#1F2329").cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 1)
            button.layer.shadowRadius = 0
            button.layer.shadowOpacity = 0.4
        }
        if let text = itemViewContentProvider.title(key),
           let enableTextColor = itemViewContentProvider.titleColor(key, enable: true) {
            button.setTitle(text, for: .normal)
            button.setTitleColor(enableTextColor, for: .normal)
            if let disabledTextColor = itemViewContentProvider.titleColor(key, enable: false) {
                button.setTitleColor(disabledTextColor, for: .disabled)
            }
        }
        if let img = itemViewContentProvider.icon(key, enable: true) {
            button.setImage(img, for: .normal)
        }
        if let img = itemViewContentProvider.icon(key, enable: false) {
            button.setImage(img, for: .disabled)
        }
        button.isEnabled = !disable
        return button
    }
}
extension BTNumberKeyboardView {
    private func didClick(key: BTNumberKeyboardKeyType) {
        switch key {
        case .digital(let num):
            insertText("\(num)", at: target?.skSelectedRange)
        case .function(let funcType):
            handleFuncionKeyClick(type: funcType)
        }
    }
    private func handleFuncionKeyClick(type: BTNumberKeyboardFunctionKeyType) {
        switch type {
        case .point:
            insertText(".", at: target?.skSelectedRange)
        case .sign:
            handleClickSign()
        case .delete:
            handleDelete(count: 1)
        case .done:
            handleClickDone()
        }
    }
    private func handleClickSign() {
        var text: String?
        if let tf = target as? UITextField {
            text = tf.text
        } else if let tv = target as? UITextView {
            text = tv.text
        }
        guard let text = text else {
            insertText("-", at: NSRange(location: 0, length: 0))
            return
        }
        if text.hasPrefix("-") {
            insertText(text.mySubString(from: 1), at: NSRange(location: 0, length: text.utf16.count))
        } else if text.hasPrefix("+") {
            insertText("-" + text.mySubString(from: 1), at: NSRange(location: 0, length: text.utf16.count))
        } else {
            insertText("-" + text, at: NSRange(location: 0, length: text.utf16.count))
        }
        
        trackSignKeyClick()
    }
    private func handleClickDone() {
        if let tf = target as? UITextField {
            _ = tf.delegate?.textFieldShouldReturn?(tf)
            return
        }
        if let tv = target as? UITextView, let range = target?.skSelectedRange {
            _ = tv.delegate?.textView?(tv, shouldChangeTextIn: range, replacementText: "\n")
        }
    }
    private func handleDelete(count: Int) {
        for _ in 0..<count {
            target?.deleteBackward()
        }
    }
    private func insertText(_ text: String, at range: NSRange?) {
        guard let range = range else {
            return
        }
        if let tf = target as? UITextField,
           tf.delegate?.textField?(tf, shouldChangeCharactersIn: range, replacementString: text) == false {
            return
        }
        if let tv = target as? UITextView,
           tv.delegate?.textView?(tv, shouldChangeTextIn: range, replacementText: text) == false {
            return
        }
        guard let textRange = textRange(with: range) else {
            return
        }
        target?.replace(textRange, withText: text)
    }
    
    private func textRange(with nsRange: NSRange) -> UITextRange? {
        guard let begin = target?.beginningOfDocument,
              let startPosition = target?.position(from: begin, offset: nsRange.location),
              let endPosition = target?.position(from: begin, offset: nsRange.location + nsRange.length) else {
            return nil
        }
        return target?.textRange(from: startPosition, to: endPosition)
    }
    private func trackSignKeyClick() {
        spaceAssert(commonTrackParams != nil, "bitable common track params can't be nil")
        var params = commonTrackParams ?? [:]
        params["click"] = "minus"
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.bitableKeyboardClick, parameters: params)
    }
}
extension UITextInput {
    var skSelectedRange: NSRange? {
        guard let textRange = selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: textRange.start)
        let length = offset(from: textRange.start, to: textRange.end)
        return NSRange(location: location, length: length)
    }
}

final class BTNumberKeyboardButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            self.backgroundColor = isHighlighted ? highlightBgColor : normalBgColor
            self.layer.shadowOffset = isHighlighted ? .zero : CGSize(width: 0, height: 1)
        }
    }
    var normalBgColor: UIColor? {
        didSet {
            self.backgroundColor = normalBgColor
        }
    }
    var highlightBgColor: UIColor?
    
    private lazy var longPressGesture = UILongPressGestureRecognizer()
    private lazy var bag = DisposeBag()
    private var timerDisposable: Disposable?
    func longPress(timeInterval: TimeInterval) -> Observable<Int> {
        if longPressGesture.view == nil {
            self.addGestureRecognizer(longPressGesture)
        }
        longPressGesture.minimumPressDuration = timeInterval
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            self.longPressGesture.rx.event
                .filter({ $0.state == .began || $0.state == .ended })
                .map({ $0.state == .began })
                .subscribe { [weak self] event in
                    guard let self = self else {
                        observer.onCompleted()
                        return
                    }
                    if case .next(let isBegan) = event {
                        if isBegan {
                            let milliseconds = Int(timeInterval * 1000)
                            self.timerDisposable = Observable<Int>.interval(.milliseconds(milliseconds), scheduler: MainScheduler.instance)
                                .subscribe({ timeEvent in observer.on(timeEvent) })
                        } else {
                            self.timerDisposable?.dispose()
                        }
                    } else {
                        observer.onCompleted()
                    }
                }
                .disposed(by: self.bag)
            return Disposables.create()
        }
    }
}
