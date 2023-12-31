//
//  SmartComposeServiceImpl.swift
//  LarkAI
//
//  Created by ByteDance on 2023/6/19.
//

import UIKit
import LarkModel
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkCore
import EditTextView
import LarkGuide
import LarkGuideUI
import LarkContainer
import LarkAccountInterface
import Lottie
import LarkSearchCore
import LKCommonsLogging
import LarkMessengerInterface
import LarkStorage
import UniverseDesignColor

public class SmartComposeServiceImpl: SmartComposeService, GuideSingleBubbleDelegate {
    static var logger = Logger.log(SmartComposeService.self)
    public weak var fromController: UIViewController?
    private weak var inputTextView: LarkEditTextView?
    /// 会话id
    private var chatId: String = ""
    /// 场景
    private var scene: SmartComposeScene = .MESSENGER
    /// viewModel
    private let viewModel: SmartComposeViewModel
    private static let globalStore = KVStores.AI.global()

    /// 手势的view
    private lazy var tapView: UIView = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.selectedComposeSuggestion))
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.selectedComposeSuggestion))
        swipe.direction = .right
        let tapView = UIView(frame: CGRect.zero)
        tapView.addGestureRecognizer(tap)
        tapView.addGestureRecognizer(swipe)
        return tapView
    }()

    /// 暗示图标
    private let tapLabel: UILabel = {
        var tapLabel = UILabel()
        tapLabel.text = "Tap"
        tapLabel.font = UIFont.systemFont(ofSize: 12)
        tapLabel.textColor = UIColor.ud.N500
        tapLabel.ud.setLayerBorderColor(UIColor.ud.N500)
        tapLabel.layer.borderWidth = 0.5
        tapLabel.layer.cornerRadius = 2
        tapLabel.textAlignment = .center
        return tapLabel
    }()
    /// 是否已经展示Smart Compose
    private var isShowSmartCompose: Bool = false

    /// 拿去请求的最后一个输入
    private var lastRequestPrefix: String = "" {
        didSet {
            self.lastInputPrefix = lastRequestPrefix
        }
    }
    /// 当前输入的文本
    private var lastInputPrefix: String = ""
    /// 用户的最新输入
    private var newInput: String = ""
    /// 拿去请求的最后一个输入的suggestion
    private var latestRequestSuggestion: String = "" {
        didSet {
            self.latestComposeSuggestion = latestRequestSuggestion
        }
    }
    /// 正在展示的suggestion
    private var latestComposeSuggestion: String = ""

    private let disposeBag = DisposeBag()

    let userResolver: UserResolver
    public init(resolver: UserResolver) {
        self.userResolver = resolver
        self.viewModel = SmartComposeViewModel(resolver: resolver)
    }
    public func setupSmartCompose(chat: LarkModel.Chat?,
                                  scene: SmartComposeScene,
                                  with inputTextView: LarkEditTextView?,
                                  fromVC: UIViewController?) {
        /// 判断是否打开开关
        let smartComposeSetting = KVPublic.Setting.smartComposeMessage.value(forUser: userResolver.userID)
        let smartComposeFG = AIFeatureGating.smartCompose.isUserEnabled(userResolver: userResolver)
        guard smartComposeSetting, smartComposeFG else {
            Self.logger.info("smart compose switch state: \(smartComposeSetting), fg \(smartComposeFG)")
            return
        }
        guard let chatId = chat?.id,
              (chat?.chatMode) != .threadV2,
              (chat?.isPrivateMode) != true else {
            Self.logger.info("smart correct chat value \(chatId), chatModel \(String(describing: chat?.chatMode)),  isPrivateModel \(String(describing: chat?.isPrivateMode))")
            return
        }
        self.chatId = chatId
        self.scene = scene
        self.inputTextView = inputTextView
        self.fromController = fromVC
        let inputText = inputTextView?.rx.text.orEmpty.asObservable()

        inputText?
            .filter { [weak self] _ in
                /// 输入拼音时阴影状态暂不处理
                let selectedRange = self?.inputTextView?.markedTextRange ?? UITextRange()
                if self?.inputTextView?.position(from: selectedRange.start, offset: 0) == nil {
                    return true
                }
                return false
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (textString) in
                guard let self = self else { return }
                if let range = textString.range(of: self.lastInputPrefix) {
                    // 取出新输入的字符
                    self.newInput = textString
                    self.newInput.removeSubrange(range)
                    if let suggestionRange = self.newInput.range(of: self.latestComposeSuggestion) {
                        self.newInput.removeSubrange(suggestionRange)
                    }
                    // 判断新输入字符是不是和补全建议的前几个字符匹配
                    if !self.newInput.isEmpty && self.latestComposeSuggestion.hasPrefix(self.newInput) {
                        guard let newInputRange = self.latestComposeSuggestion.range(of: self.newInput),
                                let inputTextView = inputTextView else { return }
                        self.latestComposeSuggestion.removeSubrange(newInputRange)
                        /// 如果之前移除了tapView，需要添加上
                        if !self.tapView.isDescendant(of: inputTextView) {
                            self.addTapView()
                        }
                        // 用户继续输入内容和建议文字匹配
                        let inputString = self.lastInputPrefix + self.newInput + self.latestComposeSuggestion
                        let attributedString = NSMutableAttributedString(string: inputString)
                        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 17),
                                                        .foregroundColor: UIColor.ud.N1000,
                                                        .paragraphStyle: {
                                                            let paragraphStyle = NSMutableParagraphStyle()
                                                            paragraphStyle.lineSpacing = 2
                                                            return paragraphStyle
                                                        }()],
                                                       range: NSRange(location: 0, length: self.lastInputPrefix.utf16.count + self.newInput.utf16.count))
                        attributedString.addAttributes([.font: UIFont.systemFont(ofSize: 17),
                                                        .foregroundColor: UIColor.ud.N500,
                                                        .paragraphStyle: {
                                                            let paragraphStyle = NSMutableParagraphStyle()
                                                            paragraphStyle.lineSpacing = 2
                                                            return paragraphStyle
                                                        }()],
                                                       range: NSRange(location: self.lastInputPrefix.utf16.count + self.newInput.utf16.count, length: self.latestComposeSuggestion.utf16.count))
                        self.inputTextView?.replace(attributedString, useDefaultAttributes: false)
                        // 将光标移动到用户输入结束的位置
                        guard let inputTextView = self.inputTextView else { return }
                        if let newPosition = inputTextView.position(from: inputTextView.endOfDocument, offset: -(self.latestComposeSuggestion.utf16.count)) {
                            inputTextView.selectedTextRange = inputTextView.textRange(from: newPosition,
                                                                                      to: newPosition)
                        }
                        self.lastInputPrefix += self.newInput
                    } else if !self.newInput.isEmpty {
                        // 用户继续输入和建议文字不匹配
                        self.tapView.removeFromSuperview()
                        if let range = textString.range(of: self.latestComposeSuggestion) {
                            var changedInput = textString
                            changedInput.removeSubrange(range)
                            self.replace(changedInput)
                        }
                        self.latestComposeSuggestion = ""
                    }
                } else {
                    // 删除输入内容
                    self.lastRequestPrefix = ""
                    self.tapView.removeFromSuperview()
                    if let range = textString.range(of: self.latestComposeSuggestion) {
                        var changedInput = textString
                        changedInput.removeSubrange(range)
                        self.replace(changedInput)
                    }
                }
            })
            .disposed(by: disposeBag)

        // 触发补全请求
        inputText?
            .debounce(.milliseconds(500),
                      scheduler: MainScheduler.instance)
            .filter { self.validateShouldRequestSmartCompose(validateString: $0) }
            .flatMapLatest { prefix in
                self.viewModel.getSmartComposeSuggestion(chatId: self.chatId,
                                                         prefix: prefix,
                                                         scene: self.scene)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (lastRequestPrefix, response) in
                guard let self = self else { return }
                if let suggestionItem = response.suggestion.first {
                    let suggestion = suggestionItem.suggestion
                    // 将补全建议插入输入框
                    if self.inputTextView?.text.contains(suggestion) != true {
                        self.insertSuggestionString(suggestion)
                        self.lastRequestPrefix = lastRequestPrefix
                        self.latestRequestSuggestion = suggestion
                    }
                    // 生成补全建议选择区域手势
                    self.showSmartComposeSelectedView()
                }
            })
            .disposed(by: disposeBag)
    }

    /// 选择补全建议的手势操作
    @objc
    private func selectedComposeSuggestion() {
        var storage: Int = SmartComposeServiceImpl.globalStore.value(forKey: KVKeys.AI.smartComposeKey)
        storage += 1
        if storage < 10 {
            /// 防溢出
            SmartComposeServiceImpl.globalStore.set(storage, forKey: KVKeys.AI.smartComposeKey)
        }
        let content = lastInputPrefix + latestComposeSuggestion
        self.replace(content)
        self.lastInputPrefix = content
        self.latestComposeSuggestion = ""
        self.tapView.removeFromSuperview()
    }

    func addTapView() {
        guard let inputTextView = inputTextView else { return }
        guard let tapRect = rect(forTapView: latestComposeSuggestion, in: inputTextView) else { return }
        tapView.frame = tapRect
        inputTextView.addSubview(tapView)
    }
    /// 添加补全建议选择的手势蒙层
    func showSmartComposeSelectedView() {
        guard let inputTextView = inputTextView else { return }
        addTapView()
        // 判断是否需要展示引导
        let storage: Int = SmartComposeServiceImpl.globalStore.value(forKey: KVKeys.AI.smartComposeKey)
        if storage <= 2 {
            // tap 提示
            guard let textRect = rects(forString: latestComposeSuggestion, in: inputTextView).last else { return }
            let tapRect = CGRect(x: 0, y: 0, width: 37, height: 22)
            let tapCenter = CGPoint(x: textRect.centerX + textRect.width / 2, y: textRect.height / 2)
            tapLabel.frame = tapRect
            tapLabel.center = tapCenter
            tapView.addSubview(tapLabel)
        } else {
            tapLabel.removeFromSuperview()
        }
    }

    /// 判断是否需要请求Smart Compose请求
    /// - Parameter validateString: 用户输入的字符串
    /// - Returns: 判断结果
    /// - Note: 判断规则：从第二个单词开始，输入单词第一个字母之后，进行请求
    private func validateShouldRequestSmartCompose(validateString: String) -> Bool {
        let selectedRange = self.inputTextView?.markedTextRange ?? UITextRange()
        if self.inputTextView?.position(from: selectedRange.start, offset: 0) == nil {
            if validateString.count > 2 {
                let suffix = validateString.suffix(2)
                if suffix.first == " " || suffix.first == "\n" || suffix.first == "\t" {
                    return true
                }
                return false
            }
        } else {
            // 正在输入拼音时，不对文字进行统计和限制
            return false
        }
        return false
    }

    /// 补全建议文本所在区域集合
    ///
    /// - Parameter string:   文本
    /// - Parameter textview: 输入框
    /// - Returns: 补全建议的点击区域集合
    private func rects(forString string: String, in textview: UITextView) -> [CGRect] {
        guard let inputString = textview.text else { return [] }
        guard let range: Range = inputString.range(of: string) else { return [] }
        guard let start = textview.position(from: textview.beginningOfDocument,
                                            offset: range.lowerBound.utf16Offset(in: inputString)) else { return [] }
        guard let end = textview.position(from: start,
                                          offset: string.utf16.count - 1) else { return [] }
        // 获取文本在inputView里的range
        guard let textRange = textview.textRange(from: start, to: end) else { return [] }
        // 获取文本在inputView里的rects
        let rectArr = textview.selectionRects(for: textRange)
        // 拼接文本在inputView里的rects
        var resultRect = rectArr.first?.rect
        rectArr.forEach { (rect) in
            resultRect = resultRect?.union(rect.rect)
        }
        return rectArr.map { $0.rect }.filter { (rect) -> Bool in
            rect.width != 0 && rect.height != 0
        }
    }

    /// 补全建议文本所在区域 合并之后的区域
    ///
    /// - Parameter string:   文本
    /// - Parameter textview: 输入框
    /// - Returns: 补全建议的点击区域
    private func rect(forString string: String, in textview: UITextView) -> CGRect? {
        let rectArr = rects(forString: string, in: textview)
        // 拼接文本在inputView里的rects
        var resultRect = rectArr.first
        rectArr.forEach { (rect) in
            resultRect = resultRect?.union(rect)
        }
        return resultRect
    }

    /// 补全建议的点击区域（文本所在区域，加上输入框的空白区域）
    ///
    /// - Parameter string:   文本
    /// - Parameter textview: 输入框
    /// - Returns: 补全建议的点击区域
    private func rect(forTapView string: String, in textview: UITextView) -> CGRect? {
        guard var resultRect = rect(forString: latestComposeSuggestion, in: textview) else { return CGRect.zero }
        // 拼接文本右方及下方空白区域
        if resultRect.maxX < textview.bounds.maxX || resultRect.maxY < textview.bounds.maxY {
            resultRect = resultRect.union(CGRect(x: resultRect.maxX,
                                                 y: resultRect.minY,
                                                 width: textview.bounds.maxX - resultRect.maxX,
                                                 height: textview.bounds.maxY - resultRect.minY))
        }
        return resultRect
    }

    /// 插入智能补全建议
    /// - Parameter str: 补全建议
    private func insertSuggestionString(_ str: String) {
        guard let inputTextView = self.inputTextView else { return }
        // 插入建议
        let mStr = NSMutableAttributedString(string: str)
        mStr.addAttributes([.font: UIFont.systemFont(ofSize: 17),
                            .foregroundColor: UIColor.ud.N500,
                            .paragraphStyle: {
                                let paragraphStyle = NSMutableParagraphStyle()
                                paragraphStyle.lineSpacing = 2
                                return paragraphStyle
                            }()],
                           range: NSRange(location: 0, length: str.utf16.count))
        inputTextView.insert(mStr, useDefaultAttributes: false)
        // 将光标移动到用户输入结束的位置
        if let newPosition = inputTextView.position(from: inputTextView.endOfDocument, offset: -str.utf16.count) {
            inputTextView.selectedTextRange = inputTextView.textRange(from: newPosition,
                                                                      to: newPosition)
        }

    }

    private func replace(_ str: String) {
        self.inputTextView?.replace(NSAttributedString(string: str), useDefaultAttributes: true)
    }
}
