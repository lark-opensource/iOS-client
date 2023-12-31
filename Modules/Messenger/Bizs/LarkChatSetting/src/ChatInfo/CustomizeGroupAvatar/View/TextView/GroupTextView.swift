//
//  GroupTextView.swift
//  LarkChatSetting
//
//  Created by kangsiwan on 2020/4/17.
//

import Foundation
import UIKit
import EditTextView
import RxSwift

/// 自定义文字
final class GroupTextView: UIView, UITextViewDelegate {
    private let disposeBag = DisposeBag()
    /// 选择颜色
    private var nameLabel = UILabel()
    /// 推荐文字区域
    private var textButtonView = TextButtonView()
    /// 自定义输入文字
    private var textView = LarkEditTextView()
    /// 所有需要展示的推荐内容
    private var textArray = [String]()
    /// 忽略textChangedHandler
    private var ignoreTextViewChanged = false
    /**埋点使用Chat参数*/
    var extraInfo: [String: Any] = [:]
    /// 用户选中/输入的内容变化，往外抛出的是：最多八个字符&去掉前后空格的
    var textChangedHandler: ((String) -> Void)?
    var selectButtonTag: Int {
        textButtonView.selectButtonTag - TextButtonView.buttonBeginTag
    }
    var inputText: String {
        textView.text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        // 选择颜色
        self.addSubview(nameLabel)
        nameLabel.text = BundleI18n.LarkChatSetting.Lark_Core_custmoized_groupavatar
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(20)
            maker.left.equalTo(16)
        }
        textButtonView.delegate = self
        self.addSubview(textButtonView)
        textButtonView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(nameLabel.snp.bottom)
        }
        // 自定义输入内容
        textView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 4
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = UIColor.ud.bgBody
        textView.textContainerInset = UIEdgeInsets(top: 9, left: 12, bottom: 8.5, right: 12)
        textView.rx.text.asDriver().drive(onNext: { [weak self] (text) in
            guard let `self` = self, let text = text else { return }
            // 输入内容时，清除选中文字
            if self.textButtonView.selectButtonTag != -1 {
                self.textButtonView.setButtonNormal(tag: self.textButtonView.selectButtonTag)
                self.textButtonView.selectButtonTag = -1
            }
            // 中文输入法，正在输入拼音时不进行截取处理
            if let language = self.textView.textInputMode?.primaryLanguage, language == "zh-Hans" {
                // 获取高亮部分
                let selectedRange = self.textView.markedTextRange ?? UITextRange()
                // 对已输入的文字进行字数统计和限制
                if self.textView.position(from: selectedRange.start, offset: 0) == nil {
                    let fixText = self.splitText(text: text)
                    // fix：输入单个表情时drive信号无限触发
                    if fixText != text { self.textView.text = fixText }
                } else {
                    // 正在输入拼音时，不对文字进行统计和限制
                    return
                }
            } else {
                // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
                let fixText = self.splitText(text: text)
                // fix：输入单个表情时drive信号无限触发
                if fixText != text { self.textView.text = fixText }
            }
            if self.ignoreTextViewChanged {
                self.ignoreTextViewChanged = false
            } else {
                // 抛出去的内容去掉前后空格&换行
                self.textChangedHandler?(self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }).disposed(by: self.disposeBag)
        // 调整占位符格式
        textView.placeholderTextView.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        textView.placeholder = BundleI18n.LarkChatSetting.Lark_Core_custmoized_groupavatar_words
        // 调整内容格式
        textView.defaultTypingAttributes = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.ud.N900,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                return paragraphStyle
            }()
        ]
        self.addSubview(textView)
        textView.returnKeyType = .done
        textView.delegate = self
        textView.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.right.equalTo(-16)
            maker.top.equalTo(textButtonView.snp.bottom).offset(12)
            maker.bottom.equalTo(-19)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 点击Done退出编辑，此回调会先于textView.rx.text.drive执行，如果此回调返回false，则textView.rx.text.drive不会触发&text不会入textView
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.endEditing(true)
            return false
        }
        return true
    }

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        let extraInfo = self.extraInfo
        ChatSettingTracker.trackGroupProfileAvatarTextInputBox(chatInfo: extraInfo)
        return true
    }

    /// 只截取前8个字符数，空格也算，抹除换行符
    private func splitText(text: String) -> String {
        let newString = text.replacingOccurrences(of: "\n", with: "")
        // 总字符数
        var countOfChar = 0
        // 中文/日文/表情算2字符长度，其他算1字符长度
        for (index, item) in newString.enumerated() {
            if item.isChinese() || item.isJapanese() || item.isEmoji() {
                countOfChar += 2
            } else {
                countOfChar += 1
            }
            // 超过8个字符，需要截取
            if countOfChar > 8 { return String(newString.prefix(index)) }
        }
        return newString
    }

    /// 清空输入框内容
    private func cleatTextForTextView() {
        // 本身就为空时，设置text = ""将不会触发rx.text.drive，提前排除这种情况
        guard !textView.text.isEmpty else { return }

        ignoreTextViewChanged = true
        textView.text = ""
    }

    /// 展示所给内容，对内容进行预处理，只保留8个字符长度
    func setupWithData(textArray: [String]) {
        self.textArray = textArray.map({ self.splitText(text: $0) })
        textButtonView.layoutTheButton(textArray: self.textArray)
    }

    /// 清空选中态，清空输入内容
    func clearSelectAndInput() {
        if textButtonView.selectButtonTag != -1 {
            textButtonView.setButtonNormal(tag: textButtonView.selectButtonTag)
            textButtonView.selectButtonTag = -1
        }
        cleatTextForTextView()
    }

    /// 当前用户选中/输入的内容
    func currSelectOrInputText() -> String {
        // 没有选中推荐文字，则返回输入的内容
        if textButtonView.selectButtonTag == -1 { return textView.text ?? "" }
        // 返回选中的推荐文字
        return textArray[textButtonView.selectButtonTag - TextButtonView.buttonBeginTag]
    }

    /// 让某个标签选中
    func setSelctText(text: String) {
        guard let index = self.textArray.firstIndex(where: { $0 == text }) else { return }

        textButtonView.selectButtonTag = TextButtonView.buttonBeginTag + index
        textButtonView.setButtonSelected(tag: textButtonView.selectButtonTag)
    }
}

/// 处理点击事件
extension GroupTextView: TextButtonDelegate {
    func buttonDidSelect(button: UIButton) {
        self.endEditing(true)
        let extraInfo = self.extraInfo

        // 如果选中了之前选中的内容，则取消选中，抛出输入的内容
        if button.tag == textButtonView.selectButtonTag {
            ChatSettingTracker.trackGroupProfileCustomTextAvatarUnchoose(chatInfo: extraInfo)
            textButtonView.selectButtonTag = -1
            textButtonView.setButtonNormal(button: button)
            // 抛出去的内容去掉前后空格&换行
            self.textChangedHandler?(self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines))
            return
        }

        // 让之前选中的按钮取消选中，让当前按钮处于选中态，抛出按钮对应的内容
        if textButtonView.selectButtonTag != -1 {
            ChatSettingTracker.trackGroupProfileCustomTextAvatarUnchoose(chatInfo: extraInfo)
            textButtonView.setButtonNormal(tag: textButtonView.selectButtonTag)
            textButtonView.selectButtonTag = -1
        }
        // 选中按钮时，清空输入框的内容
        cleatTextForTextView()
        // textView.text = ""让rx.text触发完毕后再执行选中操作，不然rx.text内部会清空按钮选中态
        DispatchQueue.main.async {
            ChatSettingTracker.trackGroupProfileCustomTextAvatarChoose(chatInfo: extraInfo)
            self.textButtonView.selectButtonTag = button.tag
            self.textButtonView.setButtonSelected(button: button)
            // 抛出去的内容去掉前后空格&换行
            let fixText = self.splitText(text: button.titleLabel?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            self.textChangedHandler?(fixText)
        }
    }
}
