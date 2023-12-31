//
//  SearchView.swift
//  Calendar
//
//  Created by zhuchao on 2019/1/16.
//  Copyright © 2019 EE. All rights reserved.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UIKit
import RxSwift

final class SearchView: UIView {
    private static let defaultHeight: CGFloat = 45.0
    private let textField = UITextField(frame: .zero)
    private let textChanged: (String) -> Void
    private let textDone: ((String) -> Void)?
    private let icon = UIImageView()
    private let bag = DisposeBag()
    init(textChanged: @escaping (String) -> Void, textDone: ((String) -> Void)? = nil) {
        self.textChanged = textChanged
        self.textDone = textDone
        // 外部使用 autolayout 布局 无需此处提供宽度
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: SearchView.defaultHeight))
        self.backgroundColor = UIColor.ud.bgBody
        let bgView = UIView()
        self.layoutBackgroundView(bgView)
        self.layoutSearchIcon(on: bgView)
        self.layoutSearchField(textField, on: bgView)
    }

    var text: String {
        get { return textField.text ?? "" }
        set { textField.text = newValue }
    }

    private func layoutBackgroundView(_ bg: UIView) {
        self.addSubview(bg)
        bg.backgroundColor = UIColor.ud.N100
        bg.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 12, bottom: 8, right: 12))
        }
        bg.layer.cornerRadius = 4
    }

    private func layoutSearchIcon(on bgView: UIView) {
        icon.image = UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3)
        bgView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
    }

    private func layoutSearchField(_ textField: UITextField, on bgView: UIView) {
        bgView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(32)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-5)
        }
        textField.attributedPlaceholder = NSAttributedString(string: BundleI18n.Calendar.Calendar_Common_Search,
                                                             attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
        textField.font = UIFont.cd.regularFont(ofSize: 14)
        textField.textColor = UIColor.ud.N800
        textField.returnKeyType = .done
        textField.addTarget(textField, action: #selector(resignFirstResponder), for: .editingDidEndOnExit)
        textField.rx.text.orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .subscribeForUI(onNext: { [weak self] searchText in
                self?.textChanged(searchText)
            }).disposed(by: bag)
        textField.addTarget(self, action: #selector(textFieldDidEnd(_:)), for: .editingDidEnd)
        textField.clearButtonMode = .whileEditing
    }

    @objc
    private func textFieldDidEnd(_ textField: UITextField) {
        self.textDone?(textField.text ?? "")
    }

    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        if textField.markedTextRange != nil { return }
        self.textChanged(textField.text ?? "")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = SearchView.defaultHeight
        return size
    }

    public func setPlaceHolder(_ text: String) {
        textField.placeholder = text
    }

    public func setKeyBoardType(_ keyboardType: UIKeyboardType) {
        textField.keyboardType = keyboardType
    }

    public func setKeyBoardReturnKeyType(_ returnKeyType: UIReturnKeyType) {
        textField.returnKeyType = returnKeyType
    }

    public func hideSearchIcon() {
        icon.isHidden = true
        textField.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(8)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-5)
        }
    }
}
