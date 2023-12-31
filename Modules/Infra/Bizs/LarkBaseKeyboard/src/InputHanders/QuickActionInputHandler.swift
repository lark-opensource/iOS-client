//
//  QuickActionInputHandler.swift
//  LarkBaseKeyboard
//
//  Created by Hayden on 4/7/2023.
//

import UIKit
import RxSwift
import RxCocoa
import ServerPB
import EditTextView
import LarkLocalizations
import UniverseDesignFont
import LarkSetting

// MARK: - InputHandler

open class QuickActionInputHandler: TextViewInputProtocol, TextViewListenersProtocol {

    public func onSetTextViewAttributedText() {
        guard let textView = textView else { return }
        textViewDidChange(textView)
    }
    
    public func onSetTextViewText() {}

    private weak var textView: UITextView?


    let disposeBag = DisposeBag()

    public var isDeleting: Bool = false
    var changedTextInfo: (attributes: [NSAttributedString.Key: Any], range: NSRange)?

    var isCopyFromCustomHandler: Bool = false

    public init() {}

    open func register(textView: UITextView) {

        self.textView = textView

        // 监听 Lark 定制的粘贴操作，由于 Lark 定制的粘贴不走 UITextView 的回调（技术实现原因），因此这里监听后主动调用一次
        if let editTextView = textView as? LarkEditTextView, let handler = editTextView.interactionHandler as? CustomTextViewInteractionHandler {
            editTextView.addListener(self)
            handler.shouldChange = { [weak self, weak textView] (range, attrText) in
                // 禁用 Lark 定制的粘贴（表情、URL等）
                guard let self = self, let textView = textView else { return false }
                let shouldChange = self.textView(textView, shouldChangeTextIn: range, replacementText: attrText.string)
                if shouldChange { self.isCopyFromCustomHandler = true }
                return shouldChange
            }
            handler.didChange = { [weak self, weak textView] in
                guard let self = self, let textView = textView else { return }
                self.textViewDidChange(textView)
                self.isCopyFromCustomHandler = false
            }
        }
        // 监听光标变化，rx 监听太早会失败，所以在下一个 Runloop 执行
        DispatchQueue.main.async(execute: {
            textView.rx.didChangeSelection
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak textView] in
                    guard let textView = textView else { return }
                    self?.textViewDidChangeSelection(textView)
                }).disposed(by: self.disposeBag)
        })
    }

    func textViewDidChangeSelection(_ textView: UITextView) {

        // 允许全选
        if textView.selectedRange == textView.attributedText.fullRange { return }

        // 寻找合适的位置，放置光标
        let newCursorRange = findCursorRange(from: textView.selectedRange, content: textView.attributedText)
        setSelectedRangeIfNeeded(newCursorRange, textView: textView)
    }

    private func setSelectedRangeIfNeeded(_ newRange: NSRange, textView: UITextView) {
        guard newRange.location >= 0, newRange.upperBound <= textView.attributedText.length else { return }
        guard newRange != textView.selectedRange else { return }
        textView.selectedRange = newRange
    }

    private func findCursorRange(from cursor: NSRange, content: NSAttributedString) -> NSRange {

        // 如果 selectedRange 完全落在在内容区域，允许自由选择
        if content.getRanges(ofKey: .paramContentKey).contains(where: { $0.contains(cursor) }) {
            return cursor
        }

        // 如果光标在 QuickActionTitle 上，将光标强制设在 Title 的最后
        let actionTitleRanges = content.getRanges(ofKey: .titleKey)
        if let currentActionTitle = actionTitleRanges.first(where: { $0.intersection(cursor) != nil }) {
            let newCursor = currentActionTitle.lastPlace
            if newCursor == cursor { return cursor }
            return findCursorRange(from: newCursor, content: content)
        }

        // 如果光标在 ParamTitle 上，将光标强制设在 ParamTitle 最后
        let paramTitleRanges = content.getRanges(ofKey: .paramTitleKey)
        if let currentParamTitle = paramTitleRanges.first(where: { $0.intersection(cursor) != nil }) {
            let newCursor = currentParamTitle.lastPlace
            if newCursor == cursor { return cursor }
            return findCursorRange(from: newCursor, content: content)
        }

        // 如果点击区域在 Placeholder 上，将光标强制设在 Placeholder 的首位
        let placeholderRanges = content.getRanges(ofKey: .paramPlaceholderKey)
        if let currentPlaceholder = placeholderRanges.first(where: { $0.contains(cursor) }) {
            let newCursor = currentPlaceholder.firstPlace
            if newCursor == cursor { return cursor }
            return findCursorRange(from: newCursor, content: content)
        }

        // 如果点击区域在 Divider 上，将光标强制设在 Divider 前面
        let dividerRanges = content.getRanges(ofKey: .dividerKey)
        if let currentDivider = dividerRanges.first(where: { $0.contains(cursor) }) {
            let newCursor = currentDivider.firstPlace
            if newCursor == cursor { return cursor }
            return findCursorRange(from: newCursor, content: content)
        }

        return cursor
    }

    open func textViewDidChange(_ textView: UITextView) {

        let attributedText = textView.attributedText ?? NSAttributedString(string: "")
        // 获取所有的 ParamTitle 所在的 range
        let titleRanges = attributedText.getRanges(ofKey: .paramTitleKey)
        // 遍历每个 ParamTitleRange，对内容做处理
        for titleRange in titleRanges {
            let titleAttributes = attributedText.attributes(at: titleRange.location, effectiveRange: nil)
            let titleParamValue = titleAttributes[.paramKey] as? String
            // 找到 titleRange 所对应的 endRange，则 titleRange - endRange 之间的区域就是 content 或者 placeholder
            guard let endRange = attributedText.getRanges(ofKey: .dividerKey).first(where: { dividerRange in
                let dividerParamValue = attributedText.attributes(at: dividerRange.location, effectiveRange: nil)[.paramKey] as? String
                return dividerParamValue != nil && dividerParamValue == titleParamValue
            }) else { continue }
            // 计算出对应的 contentRange
            let contentRange = NSRange(location: titleRange.location + titleRange.length,
                                       length: endRange.location - titleRange.location - titleRange.length)
            // 防止越界
            guard attributedText.fullRange.contains(contentRange) else { continue }
            if contentRange.length == 0 {
                // 如果内容区域目前为空，需要添加 Placeholder
                guard let titleParamValue = titleParamValue, let paramInfo = QuickActionAttributeUtils.ParamInfo.fromString(titleParamValue) else { continue }
                var placeholderAttributes = attributedText.attributes(at: titleRange.location, effectiveRange: nil)
                placeholderAttributes[.paramKey] = titleParamValue
                placeholderAttributes[.paramTitleKey] = nil
                placeholderAttributes[.paramContentKey] = nil
                placeholderAttributes[.paramPlaceholderKey] = paramInfo.name
                placeholderAttributes[.foregroundColor] = QuickActionAttributeUtils.Cons.placeholderColor
                let placeholderString = NSMutableAttributedString(string: paramInfo.placeholder, attributes: placeholderAttributes)
                placeholderString.setNormalFont()
                textView.textStorage.insert(placeholderString, at: contentRange.location)
            } else {
                // 如果这个区域内是 Placeholder，则忽略
                guard attributedText.attributes(at: contentRange.location, effectiveRange: nil)[.paramPlaceholderKey] == nil else { continue }
                // 构建 attributes 并添加到 content 区域
                var contentAttributes: [NSAttributedString.Key: Any] = [:]
                contentAttributes[.paramKey] = titleParamValue
                contentAttributes[.paramContentKey] = titleAttributes[.paramTitleKey]
                textView.textStorage.addAttributes(contentAttributes, range: contentRange)
                // 如果当前区域还有 placeholder，那么删除 placeholder（如 @ 人的情况，会被认为添加文字，并没有走 shouldChange）
                if let placehodlerRange =  attributedText.getRanges(ofKey: .paramPlaceholderKey, in: contentRange).first {
                    textView.textStorage.deleteCharacters(in: placehodlerRange)
                }
            }
        }

        // 将新输入的文字添加 paramContentKey
        if let changedTextInfo = self.changedTextInfo {
            // textView.textStorage.addAttributes(changedTextInfo.attributes, range: changedTextInfo.range)
            self.changedTextInfo = nil

            // 如果是粘贴自 InputHandler，则重新检查 Placeholder 并删除（Keyboard 遗留问题）
            if isCopyFromCustomHandler {
                if let changedParamRange = textView.attributedText.getRanges(ofKey: .paramKey).first(where: { $0.contains(changedTextInfo.range) }),
                   let placeholderRange = textView.attributedText.getRanges(ofKey: .paramPlaceholderKey, in: changedParamRange).first {
                    textView.textStorage.deleteCharacters(in: placeholderRange)
                }
            }
        }
    }

    open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 处理删除操作
        if text.isEmpty && range.length != 0 {
            let allowDelete = handleDelete(textView: textView, range: range)
            if allowDelete { isDeleting = true }
            return allowDelete
        }
        // 处理输入操作
        if !text.isEmpty {
            let allowInput = handleInput(textView: textView, range: range, replacementText: text)
            if allowInput { isDeleting = false }
            return allowInput
        }
        return true
    }

    // 处理删除操作
    // 返回 true 代表同意输入框删除操作
    // 返回 false 代表不执行删除操作，在方法内部执行自定义删除方法
    private func handleDelete(textView: UITextView, range: NSRange) -> Bool {
        if range == textView.attributedText.fullRange { return true }
        return handleDeleteAtTitleArea(textView: textView, range: range)
        && handleDeleteAtParamArea(textView: textView, range: range)
    }

    private func handleDeleteAtTitleArea(textView: UITextView, range: NSRange) -> Bool {
        guard let attributedText = textView.attributedText else { return true }
        var canEdit = true
        attributedText.enumerateAttribute(.titleKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, titleRange, stop) in
            if value == nil { return }
            // 判断是否是从最后删除
            if range.location + range.length == titleRange.location + titleRange.length, range.length <= titleRange.length {
                let mutableAttr = NSMutableAttributedString(attributedString: attributedText)
                mutableAttr.deleteCharacters(in: titleRange)
                textView.attributedText = mutableAttr
                canEdit = false
                //这里是为了触发下setPlaceholderVisible
                textView.attributedText = textView.attributedText
                stop.pointee = true
            } else if NSIntersectionRange(range, titleRange).length > 0 {
                canEdit = false
                stop.pointee = true
            }
        })
        return canEdit
    }

    // 处理删除操作
    // 返回 true 代表同意输入框删除操作
    // 返回 false 代表不执行删除操作，在方法内部执行自定义删除方法
    private func handleDeleteAtParamArea(textView: UITextView, range: NSRange) -> Bool {

        guard var attributedText = textView.attributedText else {
            return true
        }

        if let markedRange = textView.markedTextNSRange, markedRange.contains(textView.selectedRange) {
            return true
        }

        var canEdit = true
        attributedText.enumerateAttribute(.paramTitleKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, paramTitleRange, stop) in
            if value == nil { return }
            // 判断是否是从最后删除
            if range.location + range.length == paramTitleRange.location + paramTitleRange.length, range.length <= paramTitleRange.length {
                // 若果是从最后开始删除，需要全部删除
                textView.textStorage.deleteCharacters(in: paramTitleRange)
                attributedText = textView.textStorage
                canEdit = false
                stop.pointee = true
            } else if NSIntersectionRange(range, paramTitleRange).length > 0 {
                textView.textStorage.deleteCharacters(in: paramTitleRange)
                canEdit = false
                stop.pointee = true
            }
        })

        // 如果 Param 没有了 title，则将 Param 整体删除
        attributedText.enumerateAttribute(.paramKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, paramRange, _) in
            guard value != nil else { return }
            if attributedText.getRanges(ofKey: .paramTitleKey, in: paramRange).isEmpty,
               textView.textStorage.fullRange.contains(paramRange) {
                textView.textStorage.deleteCharacters(in: paramRange)
                // UGLY: 操作 textStorage 似乎不会触发 textViewDidChangeSelection，因此手动调用一次，让光标来到正确的位置
                textViewDidChangeSelection(textView)
            }
        })
        return canEdit
    }

    // 处理输入操作
    private func handleInput(textView: UITextView, range: NSRange, replacementText text: String) -> Bool {
        handleInsertAtTitleArea(textView: textView, range: range, replacementText: text) &&
        handleInsertAtParamArea(textView: textView, range: range, replacementText: text)
    }

    private func handleInsertAtTitleArea(textView: UITextView, range: NSRange, replacementText text: String) -> Bool {
        guard let attributedText = textView.attributedText else { return true }
        var canEdit = true
        attributedText.enumerateAttribute(.titleKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, titleRange, _) in
            if value == nil { return }
            if range.intersection(titleRange) != nil {
                canEdit = false
            }
        })
        return canEdit
    }

    /// Param 区域不允许编辑，只允许整体删除
    private func handleInsertAtParamArea(textView: UITextView, range: NSRange, replacementText text: String) -> Bool {
        guard let attributedText = textView.attributedText else { return true }

        var insertRange = fixInsertRange(textView: textView, range: range, replacementText: text)
        
        // 禁止在 ParamTitle 部分输入文字
        var canEdit = true
        attributedText.enumerateAttribute(.paramTitleKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, paramTitleRange, stop) in
            if value != nil, insertRange.intersection(paramTitleRange) != nil {
                canEdit = false
                stop.pointee = true
            }
        })
        if !canEdit { return false }

        // 在输入文字时，去掉 Placeholder
        attributedText.enumerateAttribute(.paramPlaceholderKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, paramPlaceholderRange, stop) in
            if value != nil, insertRange.intersection(paramPlaceholderRange) != nil {
                textView.textStorage.deleteCharacters(in: paramPlaceholderRange)
                stop.pointee = true
            }
        })

        // 在 Param 其他部分输入的文字添加 ParamContent 属性
        attributedText.enumerateAttribute(.paramKey,
                                          in: attributedText.fullRange,
                                          options: [],
                                          using: { (value, paramRange, stop) in
            guard let value = value as? String, let paramInfo = QuickActionAttributeUtils.ParamInfo.fromString(value) else { return }
            if paramRange.contains(range.firstPlace) {
                let changedRange = NSRange(location: insertRange.location, length: text.utf16.count)
                changedTextInfo = (attributes: [.paramKey: value, .paramContentKey: paramInfo.name], range: changedRange)
                stop.pointee = true
            }
        })
        return canEdit
    }

    ///处理微信键盘问题
    ///https://bytedance.feishu.cn/wiki/FFJHwgY15iXtNkki5EAc4vnWnOf
    private func fixInsertRange(textView: UITextView, range: NSRange, replacementText text: String) -> NSRange {
        guard let inputMode = textView.textInputMode, 
              String(describing: type(of: inputMode)).contains("Extension") else { 
            //非三方键盘不做处理
            return range
        }
        //使用键盘输入一个字符、textView中文字不处于选中态，无markedText
        //此时以selectedRange为准，作为文字的insertRange
        if text.utf16.count == 1,
           textView.selectedRange.length == 0,
           textView.markedTextRange == nil {
            return textView.selectedRange
        } else {
            return range
        }
    }
}

// MARK: - Attrbute Utils

public extension NSAttributedString.Key {
    /// 标记 QuickAction 的标题区域，值为 `actionID`
    static let titleKey = NSAttributedString.Key(rawValue: "ai.quickAction.actionID")
    /// 标记 QuickAction 的每个参数区域（包含参数名、Placeholder 和 Content），值为该参数的必要信息 `ParamInfo`
    static let paramKey = NSAttributedString.Key(rawValue: "ai.quickAction.paramKey")
    /// 标记 QuickAction 每个参数的参数名，值为 `QuickAction.ParamDetail.name`
    static let paramTitleKey = NSAttributedString.Key(rawValue: "ai.quickAction.paramTitleKey")
    /// 标记 QuickAction 每个参数的占位符，值为 `QuickAction.ParamDetail.name`
    static let paramPlaceholderKey = NSAttributedString.Key(rawValue: "ai.quickAction.paramPlaceholderKey")
    /// 标记 QuickAction 每个参数的取值，值为 `QuickAction.ParamDetail.name`，方便取参数时获取 name 和 content
    static let paramContentKey = NSAttributedString.Key(rawValue: "ai.quickAction.paramContentKey")
    /// 标记 QuickAction 每个参数的结束符，值为 `QuickAction.ParamDetail.name`
    static let dividerKey = NSAttributedString.Key(rawValue: "ai.quickAction.dividerKey")
}

public final class QuickActionAttributeUtils {

    struct ParamInfo: Equatable {
        var name: String
        var nameLength: Int
        var placeholder: String
        var defaultValue: String

        static func ==(lhs: ParamInfo, rhs: ParamInfo) -> Bool {
            return lhs.name == rhs.name
        }

        func toString() -> String? {
            let variables = [
                "name": name,
                "nameLength": "\(nameLength)",
                "placeholder": placeholder,
                "defaultValue": defaultValue
            ]
            if let jsonData = try? JSONSerialization.data(withJSONObject: variables, options: []) {
                return String(data: jsonData, encoding: .utf8)
            }
            return nil
        }

        static func fromString(_ string: String) -> ParamInfo? {
            if let jsonData = string.data(using: .utf8),
               let variables = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: String],
               let name = variables["name"],
               let nameLength = Int(variables["nameLength"] ?? ""),
               let placeholder = variables["placeholder"],
               let defaultValue = variables["defaultValue"] {
                return ParamInfo(name: name, nameLength: nameLength, placeholder: placeholder, defaultValue: defaultValue)
            }
            return nil
        }
    }

    public init() {}

    public enum Cons {
        private static var invisibleMark: String = {
            if let uIntValue = try? SettingManager.shared.setting(with: UInt16.self, key: UserSettingKey.make(userKeyLiteral: "ai_quick_action_divider_placeholder")),
               let unicode = UnicodeScalar(uIntValue) {
                return String(unicode)
            }
            return "\u{200C}"
        }()
        public static var normalTextColor: UIColor { UIColor.ud.textTitle }
        public static var placeholderColor: UIColor { UIColor.ud.textPlaceholder }
        //微信键盘辅助输入开启「中文和数字间加空格」设置后，在中文后输入数字会自动删除数字后的空格，
        //在dividerMark处增加不可见字符来规避
        public static var dividerMark: String { invisibleMark + " " + invisibleMark }
        public static var periodMark: String {
            BundleI18n.LarkBaseKeyboard.MyAI_QuickCommandPlatform_UserPromptTemplateMain_Text(command: "", content: "") + invisibleMark
        }
        public static var colonMark: String {
            BundleI18n.LarkBaseKeyboard.MyAI_QuickCommandPlatform_UserPromptTemplateParameter_Text(parameter: "", value: "") + invisibleMark
        }
    }

    public static var defaultAttributes: [NSAttributedString.Key: Any] {
        let font = UIFont.systemFont(ofSize: 17)
        let lineHeight: CGFloat = 24
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        // Paragraph style.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        // Set.
        return [
            .font: font,
            .baselineOffset: baselineOffset,
            .paragraphStyle: mutableParagraphStyle,
            .foregroundColor: Cons.normalTextColor
        ]
    }

    /// 将 QuickAction 转换成 `NSAttributedString` 以便展示在输入框中
    public static func transformContentToString(_ quickAction: ServerPB_Office_ai_QuickAction,
                                                attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {

        // 文字的默认参数
        let presetAttributes = attributes ?? defaultAttributes

        // 构建快捷指令
        let content = NSMutableAttributedString()

        // 快捷指令名称
        let title = NSMutableAttributedString(string: quickAction.displayName + Cons.periodMark, attributes: presetAttributes)
        title.addAttribute(.titleKey, value: quickAction.id)
        title.setBoldFont()
        content.append(title)

        for param in quickAction.paramDetails where param.needConfirm {

            let paramString = NSMutableAttributedString()

            // 参数 Title
            let paramTitleString = NSMutableAttributedString(string: param.realDisplayName + Cons.colonMark, attributes: presetAttributes)
            paramTitleString.addAttribute(.paramTitleKey, value: param.name)
            paramTitleString.setBoldFont()
            paramString.append(paramTitleString)

            // 参数内容（默认值或 Placeholder）
            if param.hasDefaultContent {
                // 如果有默认值，填充默认值
                let defaultContentString = NSMutableAttributedString(string: param.default, attributes: presetAttributes)
                defaultContentString.addAttribute(.paramContentKey, value: param.name)
                paramString.append(defaultContentString)
            } else {
                // 如果没有默认值，填充占位符
                let placeholderString = NSMutableAttributedString(string: param.placeHolder, attributes: presetAttributes)
                placeholderString.addAttributes([.paramPlaceholderKey: param.name, .foregroundColor: Cons.placeholderColor])
                paramString.append(placeholderString)
            }

            // 参数最后的空格，作为和其他参数的分割
            let endString = NSMutableAttributedString(string: Cons.dividerMark, attributes: presetAttributes)
            endString.addAttribute(.dividerKey, value: param.name)
            paramString.append(endString)

            // Param 整体添加 .paramKey
            paramString.addAttribute(.paramKey, value: ParamInfo(
                name: param.name,
                nameLength: paramTitleString.length,
                placeholder: param.placeHolder,
                defaultValue: param.default
            ).toString() ?? "")

            content.append(paramString)
        }
        return content
    }

    /// 从输入框的 `NSAttributedString` 中解析出 QuickAction 的 ID 和 params
    /// - Returns: 一个包含 ID 和 params 的元祖。如果为空，表示这是一个非法的 QuickAction
    public static func parseQuickAction(from content: NSAttributedString) -> (id: String, params: [String: String])? {
        // 解析 ID
        guard let id: String = content.getValueList(ofKey: .titleKey).first else {
            return nil
        }
        // 解析用户填入的参数
        var inputParams: [String: String] = content.getValueMap(ofKey: .paramContentKey)
        // 补充用户未填入，但是有默认值的参数
        let placeholderRanges = content.getRanges(ofKey: .paramPlaceholderKey)
        for range in placeholderRanges {
            if let infoString = content.attribute(.paramKey, at: range.location, effectiveRange: nil) as? String,
               let info = ParamInfo.fromString(infoString) {
                if inputParams[info.name] == nil, !info.defaultValue.isEmpty {
                    inputParams[info.name] = info.defaultValue
                }
            }
        }
        return (id, inputParams)
    }
    
    /// 从输入框的 `NSAttributedString` 中解析出 QuickAction 的 ID 和 params
    /// - Returns: 一个包含 ID 和 params 的元祖。如果为空，表示这是一个非法的 QuickAction
    public static func parseQuickActionAndAttributes(from content: NSAttributedString) -> (id: String, params: [String: NSAttributedString])? {
        // 解析 ID
        guard let id: String = content.getValueList(ofKey: .titleKey).first else {
            return nil
        }
        // 解析用户填入的参数, preProccess传false是因为要保留其中的URL对象
        var inputParams: [String: NSAttributedString] = content.getValueMap(ofKey: .paramContentKey, preProccess: false)
        // 补充用户未填入，但是有默认值的参数
        let placeholderRanges = content.getRanges(ofKey: .paramPlaceholderKey)
        for range in placeholderRanges {
            if let infoString = content.attribute(.paramKey, at: range.location, effectiveRange: nil) as? String,
               let info = ParamInfo.fromString(infoString) {
                if inputParams[info.name] == nil, !info.defaultValue.isEmpty {
                    inputParams[info.name] = NSAttributedString(string: info.defaultValue)
                }
            }
        }
        return (id, inputParams)
    }

    /// 从输入框的 `NSAttributedString` 中解析出 QuickAction 中的 at chatter 信息，
    /// - Returns: 以 quick_execute_param_rich_tag 为 key 的字典，
    /// value 是 { "param_name1": {"at_info":[{"content": "", "user_id":""}, ...]}, "param_name2": {...},...}
    /// value 最终是 json 转成的字符串；后续还可扩展其他参数（跟 at_info 同级）
    /// https://bytedance.sg.larkoffice.com/docx/I2yAdY7TCoGx3GxCzRrlbazvgff
    public static func parseQuickActionRichTagParams(from content: NSAttributedString, with needInputParams: [String] = []) -> [String: String] {
        var customParams: [String: String] = [:]
        if !needInputParams.isEmpty {
            let chatterInfos: [AtChatterInfo] = content.getValueList(ofKey: AtTransformer.UserIdAttributedKey)
            typealias AtInfo = [String: String]
            var atInfos: [AtInfo] = []
            for chatterInfo in chatterInfos {
                var atInfo: [String: String] = [:]
                atInfo["content"] = chatterInfo.name
                atInfo["user_id"] = chatterInfo.id
                atInfos.append(atInfo)
            }
            var quickExecuteParamRichTag: [String: ([String: [AtInfo]])] = [:]
            for paramName in needInputParams {
                quickExecuteParamRichTag[paramName] = ["at_info": atInfos]
            }

            if let json = try? JSONSerialization.data(withJSONObject: quickExecuteParamRichTag, options: .prettyPrinted),
               let str = String(data: json, encoding: .utf8) {
                customParams["quick_execute_param_rich_tag"] = str
            }
        }
        return customParams
    }

    /// 在发送 QuickAction，要先去除所有的 Placeholder
    public static func clipEmptyPlaceholders(from content: NSAttributedString) -> NSAttributedString {
        let mutableContent = NSMutableAttributedString(attributedString: content)
        let placeholderRanges = mutableContent.getRanges(ofKey: .paramPlaceholderKey)
        for range in placeholderRanges.reversed() {
            // 要从后向前删，不会影响到前面的 range。否则会 Index out of range
            mutableContent.deleteCharacters(in: range)
        }
        return mutableContent
    }

    /// 判断输入中是否包含不是 QuickAction 的字符
    /// - NOTE: QuickAction 只允许在 Placeholder 处输入文字。比如在 QuickAction 标题后输入了自定义的字符，则 QuickAction 应该降级为普通文本消息
    public static func checkQuickActionValidity(from contents: NSAttributedString) -> Bool {
        var isValid = true
        contents.enumerateAttributes(in: contents.fullRange) { attrs, _, stop in
            if attrs[.titleKey] == nil, attrs[.paramKey] == nil {
                isValid = false
                stop.pointee = true
            }
        }
        return isValid
    }
}

// MARK: - Extensions

public extension NSAttributedString {

    var fullRange: NSRange {
        NSRange(location: 0, length: length)
    }

    /// 获取字符串最后一位光标的位置
    var lastCursor: NSRange {
        NSRange(location: length, length: 0)
    }

    func getRanges(ofKey key: NSAttributedString.Key, in range: NSRange? = nil) -> [NSRange] {
        var ranges: [NSRange] = []
        self.enumerateAttribute(key, in: range ?? fullRange) { value, range, _ in
            if value != nil { ranges.append(range) }
        }
        return ranges
    }

    func getValueMap<T: Hashable>(ofKey key: NSAttributedString.Key, in range: NSRange? = nil) -> [T: String] {
        var map: [T: String] = [:]
        self.enumerateAttribute(key, in: range ?? fullRange) { value, range, _ in
            guard let value = value as? T else { return }
            /// 将 URL 标题重新解析为链接
            let transformedText = LinkTransformer().preproccessSendAttributedStr(attributedSubstring(from: range))
            if let existValue = map[value] {
                map[value] = existValue + transformedText.string
            } else {
                map[value] = transformedText.string
            }
        }
        return map
    }
    
    func getValueMap<T: Hashable>(ofKey key: NSAttributedString.Key, preProccess: Bool, in range: NSRange? = nil) -> [T: NSAttributedString] {
        var map: [T: NSAttributedString] = [:]
        self.enumerateAttribute(key, in: range ?? fullRange) { value, range, _ in
            guard let value = value as? T else { return }
            let transformedText: NSAttributedString
            if preProccess { // 将 URL 标题重新解析为链接
                transformedText = LinkTransformer().preproccessSendAttributedStr(attributedSubstring(from: range))
            } else {
                transformedText = attributedSubstring(from: range)
            }
            if let existValue = map[value] {
                let newAttrStr = NSMutableAttributedString(attributedString: existValue)
                newAttrStr.append(transformedText)
                map[value] = newAttrStr
            } else {
                map[value] = transformedText
            }
        }
        return map
    }

    func getValueList<T>(ofKey key: NSAttributedString.Key, in range: NSRange? = nil) -> [T] {
        var list: [T] = []
        self.enumerateAttribute(key, in: range ?? fullRange) { value, _, _ in
            guard let value = value as? T else { return }
            list.append(value)
        }
        return list
    }
}

extension UITextView {

    var markedTextNSRange: NSRange? {
        guard let markedTextRange = markedTextRange else { return nil }
        let startOffset = offset(from: beginningOfDocument, to: markedTextRange.start)
        let endOffset = offset(from: beginningOfDocument, to: markedTextRange.end)
        return NSRange(location: startOffset, length: endOffset - startOffset)
    }
}

public extension NSMutableAttributedString {

    var attributes: [Key: Any] {
        guard length > 0 else { return [:] }
        return attributes(at: 0, effectiveRange: nil)
    }

    func setBoldFont(withRange range: NSRange? = nil) {
        if let font = attributes[.font] as? UIFont {
            let range = range ?? fullRange
            self.addAttribute(.font, value: font.withTraits(.traitBold), range: range)
        }
    }
    
    func setNormalFont(withRange range: NSRange? = nil) {
        if var fontAttr = attributes[.font] as? UIFont {
            let range = range ?? fullRange
            let size = fontAttr.pointSize
            //这里之前直接用withoutTraits在iPhoneXSMax上会把字号给自动缩小，先记录下字号后面再添加上去
            fontAttr = fontAttr.withoutTraits(.traitBold)
            fontAttr = fontAttr.withSize(size)
            self.addAttribute(.font, value: fontAttr, range: range)
        }
    }

    func addAttribute(_ name: NSAttributedString.Key, value: Any) {
        addAttribute(name, value: value, range: fullRange)
    }

    func addAttributes(_ attrs: [NSAttributedString.Key: Any]) {
        addAttributes(attrs, range: fullRange)
    }
}

public extension NSRange {

    var firstPlace: NSRange {
        NSRange(location: location, length: 0)
    }

    var lastPlace: NSRange {
        NSRange(location: location + length, length: 0)
    }

    /// 前闭后闭的区间判断
    /// - NOTE: 使用 `intersection(:)` 则是前闭后开的区间判断
    func contains(_ anotherRange: NSRange) -> Bool {
        var retval = false
        if self.location <= anotherRange.location && self.location + self.length >= anotherRange.length + anotherRange.location {
            retval = true
        }
        return retval
    }
}

extension Array where Element == NSRange {

    func mergeAdjacent() -> [Element] {
        var mergedRanges: [NSRange] = []
        // Sort the ranges by their location
        let sortedRanges = self.sorted { $0.location < $1.location }
        // Merge adjacent ranges
        var currentRange: NSRange?
        for range in sortedRanges {
            if let current = currentRange, NSMaxRange(current) == range.location {
                currentRange = NSUnionRange(current, range)
            } else {
                if let current = currentRange {
                    mergedRanges.append(current)
                }
                currentRange = range
            }
        }
        if let current = currentRange {
            mergedRanges.append(current)
        }
        return mergedRanges
    }
}

/// QuickAction 参数的扩展方法
extension ServerPB_Office_ai_Param {

    /// 快捷指令参数在输入框展示的名称
    /// - NOTE: 如果没有 displayName，展示 description；如果没有 description，展示 name
    var realDisplayName: String {
        if hasDisplayName { return displayName }
        return name
    }

    /// 快捷指令参数是否有默认值（去掉空字符）
    var hasDefaultContent: Bool {
        hasDefault && !self.default.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
