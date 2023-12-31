//
//  RecognizeAttachmentTextFactory.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/20.
//

import Foundation
import EditTextView
import LarkKeyboardView

final class RecognizeAttachmentTextFactory {
    let loadingView: AudioRecognizingView = {
        let view = AudioRecognizingView(text: "")
        view.startAnimationIfNeeded()
        return view
    }()

    func loadingViewString(showReady: Bool, showSpeakTip: Bool, font: UIFont?, defaultTypingAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        if showReady {
            loadingView.text = BundleI18n.LarkAudio.Lark_Chat_PrepareRecordAudio
        } else if showSpeakTip {
            loadingView.text = BundleI18n.LarkAudio.Lark_Chat_AudioToTextSpeakTip
        } else {
            loadingView.text = ""
        }
        var attachmentBounds = loadingView.attachmentBounds
        if let font = font {
            attachmentBounds.origin.y = font.descender
        }
        let attachment = CustomTextAttachment(customView: loadingView, bounds: attachmentBounds)
        let attachmentText = NSMutableAttributedString(attachment: attachment)
        attachmentText.addAttributes(defaultTypingAttributes, range: NSRange(location: 0, length: attachmentText.length))
        return attachmentText
    }

    // 识别到的文字，添加字体样式
    /// NSAttributedString: 把 text 转为富文本，增加loading 效果
    /// NSRange: lastDiffRange, 不确定的 diff 区域
    /// int: 不添加loading 效果的 length
    func getText(text: String, finish: Bool, diffIndexSlice: [Int32], typingAttributes: [NSAttributedString.Key: Any], loading: NSAttributedString?) -> (NSAttributedString, NSRange?, Int) {
        // 识别出的文字，添加字体样式
        let resultText = NSMutableAttributedString(string: text)
        resultText.addAttributes(typingAttributes, range: NSRange(location: 0, length: resultText.length))
        let notLoadingText = resultText

        guard let loading else {
            return (resultText, nil, text.count)
        }

        if !finish {
            resultText.append(loading)
        }

        // diff
        var diffStartIndex = resultText.length
        let sorted = diffIndexSlice.sorted(by: { $0 > $1 })
        sorted.forEach { index in
            if index == diffStartIndex - 1 {
                diffStartIndex = Int(index)
            }
        }
        // 最短添加3个字符的未确认
        if diffStartIndex > resultText.length - 3 && resultText.length >= 3 {
            diffStartIndex = resultText.length - 3
        }

        let diffOffset = resultText.length - diffStartIndex
        let diffRange = NSRange(location: diffStartIndex, length: diffOffset)
        let lastDiffRange = diffRange
        if diffOffset > 0, !finish, diffRange.location >= 0, diffRange.location + diffRange.length <= resultText.length {
            resultText.addAttribute(.foregroundColor, value: UIColor.ud.textPlaceholder, range: diffRange)
        }
        return (resultText, lastDiffRange, notLoadingText.length)
    }

    func cleanDiffAndLoading(attributedText: NSMutableAttributedString, diffRange: NSRange?, attrs: [NSAttributedString.Key: Any]?) -> NSMutableAttributedString {
        var resultText = cleanDiff(attributedText: attributedText, diffRange: diffRange, attrs: attrs)
        resultText = cleanLoading(attributedText: resultText)
        return resultText
    }

    func cleanLoading(attributedText: NSMutableAttributedString) -> NSMutableAttributedString {
        var loadingRange: NSRange?
        attributedText.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedText.length), options: [], using: { (value, range, _) in
            if let attachment = value as? CustomTextAttachment, attachment.customView == self.loadingView {
                loadingRange = range
            }
        })
        if let loadingRange {
            attributedText.replaceCharacters(in: loadingRange, with: "")
        }
        return attributedText
    }

    func cleanDiff(attributedText: NSMutableAttributedString, diffRange: NSRange?, attrs: [NSAttributedString.Key: Any]?) -> NSMutableAttributedString {
        if let diffRange, attributedText.length >= diffRange.location + diffRange.length {
            attributedText.setAttributes(attrs, range: diffRange)
        }
        return attributedText
    }
}
