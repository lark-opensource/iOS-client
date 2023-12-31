//
//  CalendarDescriptionViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/22.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import LarkUIKit
import UIKit

final class CalendarDescriptionViewController: CalendarController, UITextViewDelegate {
    let desc: String
    let changeDown: ((String) -> Void)?
    let editable: Bool
    // swiftlint:disable weak_delegate
    let textViewDelegate = TextViewLengthLimitedDelegate(maxLength: 250)
    // swiftlint:enable weak_delegate
    let textView: KMPlaceholderTextView = {
        let view = KMPlaceholderTextView()
        view.font = UIFont.cd.regularFont(ofSize: 16)
        view.placeholder = BundleI18n.Calendar.Calendar_Setting_InputCalendarDescription
        return view
    }()

    init(desc: String, editable: Bool, changeDown: ((String) -> Void)? = nil) {
        self.desc = desc
        self.changeDown = changeDown
        self.textView.delegate = textViewDelegate
        self.textView.text = desc
        self.editable = editable
        textView.isEditable = editable
        if editable {
            textView.becomeFirstResponder()
            textView.textColor = UIColor.ud.N800
            textView.placeholder = BundleI18n.Calendar.Calendar_Setting_InputCalendarDescription
            textView.placeholderColor = UIColor.ud.textDisable
        } else {
            textView.textColor = UIColor.ud.textPlaceholder
            textView.placeholder = BundleI18n.Calendar.Calendar_Setting_NoCalendarDescription
        }
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        addCloseItem()
        if editable {
            addSaveItem()
        }
        title = BundleI18n.Calendar.Calendar_Edit_Description
        layout(text: textView)
    }

    private func addCloseItem() {
        let barItem = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).scaleNaviSize().renderColor(with: .n1).withRenderingMode(.alwaysOriginal), title: nil)
        barItem.button.addTarget(self, action: #selector(closePressed), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
    }

    @objc
    private func closePressed() {
        if textView.text != desc {
            EventAlert.showDismissModifiedCalendarAlert(controller: self) { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func addSaveItem() {
        let barItem = LKBarButtonItem(image: nil, title: BundleI18n.Calendar.Calendar_Common_Done)
        barItem.button.addTarget(self, action: #selector(saveItemTapped), for: .touchUpInside)
        barItem.button.tintColor = UIColor.ud.primaryContentDefault
        self.navigationItem.rightBarButtonItem = barItem
    }

    @objc
    private func saveItemTapped() {
        self.changeDown?(textView.text)
        self.navigationController?.popViewController(animated: true)
    }

    private func layout(text: UIView) {
        view.addSubview(text)
        text.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.bottom.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UITextViewDelegate {
    func limitLength(maxLength: Int, textView: UITextView) {
        if textView.text.count > maxLength {
            // 获得已输出字数与正输入字母数
            let selectRange = textView.markedTextRange
            // 获取高亮部分 － 如果有联想词则解包成功
            if let selectRange = selectRange {
                if textView.position(from: (selectRange.start), offset: 0) != nil {
                    return
                }
            }
            guard let textContent = textView.text else {
                textView.text = ""
                return
            }
            let textNum = textContent.count
            if textNum > maxLength {
                let index = textContent.index(textContent.startIndex, offsetBy: maxLength)
                let str = textContent[..<index]
                textView.text = String(str)
            }
        }
    }
}

final class TextViewLengthLimitedDelegate: NSObject, UITextViewDelegate {
    let maxLength: Int
    var onTextChanged: ((String) -> Void)?

    init(maxLength: Int) {
        self.maxLength = maxLength
    }

    func textViewDidChange(_ textView: UITextView) {
        limitLength(maxLength: maxLength, textView: textView)
        onTextChanged?(textView.text)
    }
}
