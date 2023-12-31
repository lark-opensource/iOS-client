//
//  AvatarTextEditView.swift
//  LarkChatSetting
//
//  Created by liluobin on 2023/2/16.
//

import UIKit
import UniverseDesignTag
import RxSwift
import EditTextView

final class AvatarTextEditView: UIView,
                          UITextViewDelegate,
                          UITextPasteDelegate,
                          ClearSeletedStatusProtocol {
    private var disposeBag = DisposeBag()
    var textUpdate: ((String?) -> Void)?
    var textFilter: ((String) -> String?)?
    var shouldChangeText = true
    var tagsMap: [String: String] = [:]
    /// 埋点使用
    var hadSelectedTag: Bool = false
    var selectedText: String {
        if let title = self.tagView.getSelectedTags().first?.title {
            return self.tagsMap[title] ?? ""
        }
        return self.textView.attributedText.string
    }
    lazy var tagView: UDTagListView = {
        let tagListView = UDTagListView()
        tagListView.backgroundColor = UIColor.clear
        tagListView.textColor = UIColor.ud.N900
        tagListView.selectedTextColor = UIColor.ud.primaryOnPrimaryFill
        tagListView.tagBackgroundColor = UIColor.ud.N200
        tagListView.tagSelectedBackgroundColor = UIColor.ud.colorfulBlue
        tagListView.paddingX = 14
        tagListView.paddingY = 8
        tagListView.marginX = 6
        tagListView.marginY = 6
        let font = UIFont.systemFont(ofSize: 14)
        tagListView.tagCornerRadius = (tagListView.paddingY * 2 + font.lineHeight) / 2.0
        tagListView.textFont = font
        tagListView.onTagSelected = { [weak self] (_, tagView) in
            guard let self = self else { return }
            let isSelected = !tagView.isSelected
            self.tagView.tagViews.forEach { item in
                item.isSelected = false
            }
            self.textViewClearSeletedStatus()
            if isSelected { self.hadSelectedTag = true }
            tagView.isSelected = isSelected
            self.textUpdate?(isSelected ? (self.tagsMap[tagView.title ?? ""]) : "")
            self.endEditing(true)
        }
        return tagListView
    }()

    lazy var textView: LarkEditTextView = {
        let textView = LarkEditTextView()
        textView.placeholder = BundleI18n.LarkChatSetting.Lark_Core_Mobile_CustomizedGroupAvatar_Placeholder
        textView.placeholderTextView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                return paragraphStyle
            }()
        ]
        textView.layer.borderWidth = 1
        textView.pasteDelegate = self
        textView.layer.cornerRadius = 6
        textView.maxHeight = 60
        textView.textContainer.maximumNumberOfLines = 2
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        textView.delegate = self
        return textView
    }()

    init(textUpdate: ((String?) -> Void)?,
         textFilter: ((String) -> String?)?) {
        self.textUpdate = textUpdate
        self.textFilter = textFilter
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.backgroundColor = .clear
        self.addSubview(tagView)
        self.addSubview(textView)

        tagView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        textView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.top.equalTo(tagView.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }
        addTextViewObserver()
    }

    func addTextViewObserver() {
        textView.rx.text.asDriver().drive(onNext: { [weak self] (text) in
            guard let self = self else { return }
            self.tagView.getSelectedTags().forEach({ $0.isSelected = false })
            /// 沿用原有的线上逻辑
            if let language = self.textView.textInputMode?.primaryLanguage, language == "zh-Hans" {
                // 获取高亮部分
                let selectedRange = self.textView.markedTextRange ?? UITextRange()
                if self.textView.position(from: selectedRange.start, offset: 0) == nil {
                    self.textUpdate?(text)
                }
            } else {
                self.textUpdate?(text)
            }
        }).disposed(by: self.disposeBag)
    }

    /// textView delegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.textView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        self.textView.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
    }

    func textViewDidChange(_ textView: UITextView) {
        let selectedRange = textView.selectedRange
        let cursorLocationEnd = (selectedRange.location + selectedRange.length == textView.text.utf16.count)
        if let textFilter = self.textFilter,
           textView.markedTextRange == nil,
           let text = self.textView.text,
           let filterText = textFilter(text) {
            textView.text = filterText
            /// 这里修改文字之后 光标在特殊情况下会发生异常，需要异步校正一下
            if cursorLocationEnd, text.utf16.count != filterText.utf16.count {
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: filterText.utf16.count, length: 0)
                }
            }
        }
    }

    func clearSeletedStatus() {
        self.textViewClearSeletedStatus()
        self.tagView.clearSeletedStatus()
    }

    private func textViewClearSeletedStatus() {
        if self.textView.attributedText.string.isEmpty { return }
        self.disposeBag = DisposeBag()
        self.textView.clearSeletedStatus()
        self.addTextViewObserver()
    }

    func addTags(_ tags: [String]) {
        let texts = tags.map({ tag in
            let text = tag.replacingOccurrences(of: "\n", with: " ")
            tagsMap[text] = tag
            return text
        })
        self.tagView.addTags(texts)
        self.textView.snp.updateConstraints { make in
            make.top.equalTo(tagView.snp.bottom).offset(tags.isEmpty ? 2 : 12)
        }
    }

    func selectedTitle(_ title: String) {
        self.tagsMap.forEach { key, value in
            if value == title {
                self.tagView.selectedTitle(key)
            }
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !shouldChangeText {
            shouldChangeText = true
            return false
        }
        let newLineRange = (textView.text as NSString).range(of: "\n")
        if newLineRange.location != NSNotFound && newLineRange.length > 0, text == "\n" {
            return newLineRange == range
        }
        return true
    }

    public func textPasteConfigurationSupporting(
        _ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting,
        combineItemAttributedStrings itemStrings: [NSAttributedString],
        for textRange: UITextRange) -> NSAttributedString {
            let muAttr = NSMutableAttributedString()
            itemStrings.forEach { attr in
                muAttr.append(attr)
            }
            let text = textView.attributedText.string
            /// 输入框的内容为空 或全部替换
            if text.isEmpty {
                return muAttr
            }

            /// 如果光标选择区在最后，支持粘贴
            if textView.selectedRange.location + textView.selectedRange.length == text.utf16.count {
                return muAttr
            }
            var beyondLimit = muAttr.string.avatarCountInfo().count > AvatarTextAnalyzer.maxCountOfCharacter || muAttr.string.components(separatedBy: "\n").count > 2
            if !beyondLimit {
                let targetText = (text as NSString).replacingCharacters(in: textView.selectedRange, with: muAttr.string)
                beyondLimit = targetText.avatarCountInfo().count > AvatarTextAnalyzer.maxCountOfCharacter
            }
            self.shouldChangeText = !beyondLimit
            return muAttr
    }
}

extension LarkEditTextView: ClearSeletedStatusProtocol {
    func clearSeletedStatus() {
        self.attributedText = NSAttributedString(string: "")
    }
}

extension UDTagListView: ClearSeletedStatusProtocol {
    func clearSeletedStatus() {
        self.tagViews.forEach { item in
            item.isSelected = false
        }
    }

    func selectedTitle(_ title: String) {
        self.tagViews.first { item in
            item.title == title
        }?.isSelected = true
    }
}
