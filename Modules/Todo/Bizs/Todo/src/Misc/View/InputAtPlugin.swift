//
//  InputAtPlugin.swift
//  Todo
//
//  Created by 张威 on 2021/5/6.
//

import RxSwift
import RxCocoa

/// InputAtPlugin
/// 捕获 textView 输入中的 at

final class InputAtPlugin {
    /// at 信息；
    /// - Parameter attrText. 包含控制符 `@`
    /// - Parameter range, 包含控制符 `@` 的 range
    /// - Parameter query, 搜索关键字
    typealias AtInfo = (attrText: AttrText, range: NSRange, query: String)

    /// 触发了有效 at，range 描述 at 符号的位置
    var onTiggered: ((_ atRange: NSRange) -> Void)?

    /// Query 变化
    var onQueryChanged: ((_ info: AtInfo) -> Void)?
    /// Query 失效
    var onQueryInvalid: (() -> Void)?

    /// 最新的 at info
    var latestAtInfo: AtInfo?

    // 记录每一次输入 at 的位置

    private let textView: UITextView
    // 最大 query 长度
    private let maxAtQueryLength = 10
    private var lastDisposable: Disposable?

    init(textView: UITextView) {
        self.textView = textView
    }

    func captureReplacementText(_ text: String, in range: NSRange) {
        if text == "@" {
            let isDelete = !NSEqualRanges(range, textView.selectedRange) && range.length > 0
            let isAtUser = isAt(text: textView.text ?? "", selectedRange: textView.selectedRange, isDelete: isDelete)
            if isAtUser {
                DispatchQueue.main.async {
                    self.onTiggered?(NSRange(location: range.location, length: 1))
                }
                lastDisposable?.dispose()
                lastDisposable = textView.rx.didChangeSelection.subscribe(onNext: { [weak self] _ in
                    guard self?.textView.isFirstResponder == true else { return }
                    self?.handleSelectionChanged()
                })
            } else {
                lastDisposable?.dispose()
            }
        }
    }

    /// 监测 at query
    func detectAtQuery() {
        lastDisposable?.dispose()
        lastDisposable = textView.rx.didChangeSelection.subscribe(onNext: { [weak self] _ in
            guard self?.textView.isFirstResponder == true else { return }
            self?.handleSelectionChanged()
        })
        handleSelectionChanged()
    }

    func reset() {
        lastDisposable?.dispose()
        latestAtInfo = nil
        onQueryInvalid?()
    }

    private func handleSelectionChanged() {
        let cursor = NSMaxRange(textView.selectedRange)
        if let atInfo = self.atInfo(in: textView.attributedText ?? .init(), before: cursor) {
            latestAtInfo = atInfo
            onQueryChanged?(atInfo)
        } else {
            latestAtInfo = nil
            onQueryInvalid?()
        }
    }

    private func atInfo(in attrText: AttrText, before location: Int) -> AtInfo? {
        guard attrText.length > 0 && attrText.length >= location else {
            return nil
        }
        guard let charLocation = atCharLocation(in: attrText, before: location),
              charLocation < location else {
            return nil
        }

        // 如果 at 符号处于 anchor/at/mention 中，则忽略掉
        let atCharRange = NSRange(location: charLocation, length: 1)
        let ignoreKeys: [AttrText.Key] = [.anchor, .at, .mention]
        var shouldIgnore = false
        attrText.enumerateAttributes(in: atCharRange, options: []) { (attrs, _, stop) in
            for key in attrs.keys where ignoreKeys.contains(key) {
                shouldIgnore = true
                stop.pointee = true
            }
        }
        guard !shouldIgnore else {
            return nil
        }

        let range = NSRange(location: charLocation, length: location - charLocation)
        let attrText = attrText.attributedSubstring(from: range)
        let query: String
        let rawStr = attrText.string as String
        if rawStr.isEmpty {
            query = ""
        } else {
            let fromIndex = rawStr.index(after: rawStr.startIndex)
            query = String(rawStr[fromIndex..<rawStr.endIndex])
        }
        return (attrText, range, query)
    }

    // 返回 atChar 在 attrText 中的位置
    private func atCharLocation(in attrText: AttrText, before cursor: Int) -> Int? {
        guard attrText.length >= 1 else {
            return nil
        }
        var index = cursor
        var cnt = 0
        while index > 0, cnt < maxAtQueryLength {
            index -= 1
            cnt += 1
            let range = NSRange(location: index, length: 1)
            if attrText.attributedSubstring(from: range).string == "@" {
                return index
            }
        }
        return nil
    }

    private func isAt(text: String, selectedRange: NSRange, isDelete: Bool) -> Bool {
        // 当 text 为空的时候，响应 @
        if text.isEmpty { return true }
        let nsCurrentText = text as NSString

        // 当为删除操作时候不响应 @
        if isDelete { return false }

        // 当 selectedRange length 长度不为 0 的时候不响应 @
        if selectedRange.length > 0 { return false }

        let location = selectedRange.location
        let frontContent = nsCurrentText.substring(to: location)

        // 当光标为第一位的时候，响应 @
        if frontContent.isEmpty { return true }

        // 当光标前一位为空格的时候，响应 @
        let lastChar = substring(of: frontContent, from: frontContent.count - 1)
        if lastChar == " " { return true }

        // 当光标前不为数字或者字母的时候，响应 @
        do {
            let regexp = try NSRegularExpression(pattern: "[\\da-zA-Z]", options: [])
            let matches = regexp.matches(in: lastChar, options: [], range: NSRange(location: 0, length: 1))
            if matches.isEmpty { return true }
        } catch {}

        return false
    }

    private func substring(of str: String, from index: Int) -> String {
        if str.count > index {
            let startIndex = str.index(str.startIndex, offsetBy: index)
            let subString = str[startIndex..<str.endIndex]
            return String(subString)
        } else {
            return str
        }
    }
}
