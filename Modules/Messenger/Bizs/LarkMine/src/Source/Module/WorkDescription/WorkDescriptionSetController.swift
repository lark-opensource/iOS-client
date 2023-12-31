//
//  WorkDescriptionSetController.swift
//  Lark
//
//  Created by lichen on 2018/3/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import SnapKit
import LarkModel
import LKCommonsLogging
import UniverseDesignToast
import EditTextView
import CryptoSwift
import UniverseDesignColor
import UniverseDesignIcon
import LarkSDKInterface
import LKCommonsTracker
import Homeric
import FigmaKit
import LarkCore
import LarkContainer
import LarkRichTextCore
import LarkBaseKeyboard
import LarkSetting

final class WorkDescriptionSetController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    // 支持编辑框URL预览 FG
    lazy var isSupportUrlPreview: Bool = model.userResolver.fg.staticFeatureGatingValue(with: "core.profile.signature_with_url")

    static let logger = Logger.log(WorkDescriptionSetController.self, category: "Module.Mine.Set.Description")

    /// 状态保存成功执行的回调
    var completion: ((String) -> Void)?

    private let disposeBag = DisposeBag()
    private var current: Chatter.Description = Chatter.Description()
    private var model: WorkDescriptionViewModel
    private var fistAppear: Bool = true

    //不支持url预览前的限制，最大半角字符数
    private var maxLength = 100
    //支持url预览后的限制
    private var maxSaveLength = 100
    private var maxInputLength = 5000

    private lazy var textInputProtocolSet = TextViewInputProtocolSet()

    private lazy var saveButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Legacy_Save)
        item.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        item.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        item.addTarget(self, action: #selector(didTapSaveButton), for: .touchUpInside)
        return item
    }()

    private lazy var cancelButton: LKBarButtonItem = {
        let item = LKBarButtonItem(title: BundleI18n.LarkMine.Lark_Legacy_Cancel)
        item.setProperty(alignment: .left)
        item.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        item.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        item.addTarget(self, action: #selector(didTapCancelButton), for: .touchUpInside)
        return item
    }()

    /// 上边的编辑区域
    private lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 1
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        return view
    }()

    private lazy var textView: LarkEditTextView = {
        let textView = LarkEditTextView()
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.maxHeight = 0
        textView.defaultTypingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4
                return paragraphStyle
            }()
        ]
        /// 调整占位符格式
        textView.placeholderTextView.typingAttributes = [
            .font: Cons.descriptionFont,
            .foregroundColor: UIColor.ud.textPlaceholder
        ]
        textView.placeholder = BundleI18n.LarkMine.Lark_Profile_EnterYourSignature
        return textView
    }()

    /// 清空textView按钮
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)
        button.addTarget(self, action: #selector(didTapClearButton), for: .touchUpInside)
        button.tintColor = UIColor.ud.iconN3
        return button
    }()

    /// 内容剩余可输入长度
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    /// 下面的历史记录区域
    private var historyHeader: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkMine.Lark_Profile_SignatureHistory
        label.font = Cons.headerFont
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var histroyTable: InsetTableView = {
        let tableView = InsetTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.register(DescriptionHistoryCell.self, forCellReuseIdentifier: String(describing: DescriptionHistoryCell.self))
        return tableView
    }()

    init(viewModel: WorkDescriptionViewModel) {
        self.model = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = false
        self.view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkMine.Lark_Profile_PersonalSignature

        navigationItem.rightBarButtonItem = saveButton
        navigationItem.leftBarButtonItem = cancelButton
        if isSupportUrlPreview {
            //textView注册InputHandler
            self.initInputHandler()
        }
        Self.logger.info("support url preview: \(isSupportUrlPreview)")
        addTextViewDidChangeObserve()
        /// 创建topView
        do {
            view.addSubview(topView)
            topView.addSubview(textView)
            topView.addSubview(clearButton)
            topView.addSubview(numberLabel)
            view.addSubview(historyHeader)
            view.addSubview(histroyTable)

            topView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(20)
                make.leading.trailing.equalTo(histroyTable.insetLayoutGuide)
                make.height.equalTo(Cons.textViewHeiht)
            }
            /// 中间的textView
            textView.snp.makeConstraints { (make) in
                make.top.equalTo(10)
                make.bottom.equalTo(-28)
                make.left.equalToSuperview().offset(Cons.hPadding)
                make.right.equalToSuperview().offset(-Cons.hPadding)
            }
            clearButton.snp.makeConstraints { (make) in
                make.bottom.equalTo(-12)
                make.width.height.equalTo(14)
                make.right.equalTo(-12)
            }
            /// 剩余可输入长度
            numberLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(clearButton)
                make.right.equalTo(clearButton.snp.left).offset(-10)
            }
        }

        historyHeader.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(28)
            make.height.equalTo(Cons.headerFont.figmaHeight)
            make.top.equalTo(topView.snp.bottom).offset(16)
        }
        histroyTable.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(historyHeader.snp.bottom).offset(4)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard self.fistAppear else { return }
        self.fistAppear = false
        /// get description from local and remote
        self.loadCurrent()
        self.loadHistory()

        let hasHistory = self.model.hasHistory ? "true" : "false"
        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_SIGNATURE_SETTING_VIEW,
                                               params: ["is_historical_signature_record_shown": hasHistory]))
    }

    private func addTextViewDidChangeObserve() {
        self.textView.rx.value.asDriver().drive(onNext: { [weak self, weak textView] (value) in
            guard let self = self, let textView = textView else { return }
            if !value.isEmpty {
                self.customTextViewDidChange(textView)
            }
        }).disposed(by: self.disposeBag)
    }

    private func updateCurrentDescription() {
        if self.textView.text != self.current.text {
            self.textView.text = self.current.text
        }
        updateTextCount(getLength(forText: textView.text))
    }

    @objc
    private func didTapClearButton() {
        current.text = ""
        updateCurrentDescription()
        current.type = .onDefault
        view.endEditing(true)
    }

    @objc
    private func didTapSaveButton() {
        if isSupportUrlPreview {
            guard getLength(forText: textView.text) <= maxSaveLength else {
                UDToast.showFailure(with: BundleI18n.LarkMine.Lark_IM_Profile_CharacterLimitReached100_Toast, on: self.view)
                return
            }
            current.text = NSMutableAttributedString(attributedString: RichTextTransformKit.preproccessDescriptionAttributedStr(textView.attributedText)).string
        }
        self.view.endEditing(true)
        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_SIGNATURE_SETTING_CLICK,
                                               params: ["click": "save",
                                                        "target": "none",
                                                        "signature_length": getLength(forText: self.current.text)]))
        let loadingHUD = UDToast.showDefaultLoading(on: self.view, disableUserInteraction: true)
        WorkDescriptionSetController.logger.info("update information：\(self.current.text.md5())")
        // Remove white space & new line at start and end.
        current.text = current.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.model.saveWorkDescription(self.current)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                loadingHUD.remove()
                if let keyWindow = UIApplication.shared.keyWindow {
                    let successHUD = UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_SaveSuccess, on: keyWindow)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        successHUD.remove()
                    }
                }
                guard let `self` = self else { return }
                if self.presentingViewController != nil {
                    self.dismissSelf()
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
                self.completion?(self.current.text)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                loadingHUD.remove()
                let apiErrors = error.metaErrorStack.compactMap({
                    $0 as? APIError
                })
                if let errorMsg = apiErrors.first(where: { !$0.displayMessage.isEmpty })?.displayMessage {
                    let failureHUD = UDToast.showFailure(with: errorMsg, on: self.view)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        failureHUD.remove()
                    }
                }
                WorkDescriptionSetController.logger.error("更新工作状态失败", error: error)
            }).disposed(by: disposeBag)
    }

    @objc
    private func didTapCancelButton() {
        dismissSelf()
    }

    @objc
    private func dismissSelf() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func loadCurrent() {
        if let current = self.model.loadLocalDescription() {
            WorkDescriptionSetController.logger.info("get information from local：\(current.text.md5())")
            self.current = current
            self.updateCurrentDescription()
        }

        let hud = UDToast.showDefaultLoading(on: self.view, disableUserInteraction: true)
        let userid = self.model.userID

        self.model.loadCurrent(userID: userid).subscribe(onNext: { [weak self] (description) in
            guard let self = self else { return }
            hud.remove()
            WorkDescriptionSetController.logger.info("get information from remote：\(description.text.md5())")
            self.current = description
            self.updateCurrentDescription()
            if self.isSupportUrlPreview {
                let attributedText = NSMutableAttributedString(string: description.text, attributes: self.textView.defaultTypingAttributes) ?? NSMutableAttributedString()
                self.model.inlineService.replaceWithInlineEntityTrySDK(sourceID: userid,
                                                           sourceText: description.text,
                                                           type: .personalSig,
                                                           strategy: .forceServer,
                                                           textColor: Self.Cons.textColor,
                                                           linkColor: Self.Cons.linkColor,
                                                           font: Self.Cons.descriptionFont) { [weak self] attr, urlRange, _, _ in
                    guard let self = self else { return }
                    var mutable = attr
                    for (range, (url, entity)) in urlRange {
                        let replaceStr = LinkTransformer.transformToURLAttrInDescription(entity: entity, originURL: url, attributes: self.textView.defaultTypingAttributes ?? [:])
                        guard range.location + range.length <= mutable.length else { return }
                        mutable.replaceCharacters(in: range, with: replaceStr)
                    }
                    mutable.mutableString.replaceOccurrences(
                        of: "\u{200b}",
                        with: "",
                        options: [],
                        range: NSRange(location: 0, length: mutable.length)
                    )
                    self.current.text = mutable.string
                    self.updateCurrentDescription()
                    self.textView.attributedText = mutable
                }
            }
        }, onError: { (error) in
            hud.remove()
            WorkDescriptionSetController.logger.error("加载工作状态失败", error: error)
        }).disposed(by: disposeBag)
    }

    private func loadHistory() {
        self.model.loadHistory().subscribe(onNext: { [weak self] (_) in
            self?.histroyTable.reloadData()
        }, onError: { (error) in
            WorkDescriptionSetController.logger.error("加载工作历史状态失败", error: error)
        }).disposed(by: disposeBag)
    }

    private func delete(item: Chatter.Description) {
        self.model.delete(item: item).subscribe().disposed(by: disposeBag)
        self.histroyTable.reloadData()
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.historyItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.model.historyItems.count else { return UITableViewCell() }

        let item = self.model.historyItems[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: DescriptionHistoryCell.self)) as? DescriptionHistoryCell {
            cell.chatterDescriotion = item
            cell.deleteBlock = { [weak self] item in
                self?.delete(item: item)
            }
            cell.dividingLine?.isHidden = indexPath.row == model.historyItems.count - 1
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_SIGNATURE_SETTING_CLICK,
                                               params: ["click": "historical_signature_record",
                                                        "target": "none"]))

        let item = self.model.historyItems[indexPath.row]
        WorkDescriptionSetController.logger.info("select information：\(item.text.md5())")
        self.current = item
        self.updateCurrentDescription()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height

        if self.model.hasMoreHistory,
            !self.model.loadingHistory,
            offset + height * 2 > contentHeight {
            self.loadHistory()
        }
    }
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }

    //编辑框编辑态变色逻辑，url预览FG打开时才会用到
    func changeBorderEditingColor(_ textLength: Int) {
        if textLength > maxSaveLength {
            topView.ud.setLayerBorderColor(UIColor.ud.functionDangerContentDefault)
        } else {
            topView.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        let validTextLength = getLength(forText: getValidText(textView))
        if isSupportUrlPreview {
            changeBorderEditingColor(validTextLength)
        } else {
            view.ud.setLayerBorderColor(UIColor.ud.primaryContentDefault)
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if isSupportUrlPreview {
            topView.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        } else {
            view.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        }
    }
    func getValidText(_ textView: UITextView) -> String {
        var selectedLength = 0
        if let range = textView.markedTextRange {
            selectedLength = textView.offset(from: range.start, to: range.end)
        }
        let contentLength = max(0, textView.text.count - selectedLength)
        return String(textView.text.prefix(contentLength))
    }

    func customTextViewDidChange(_ textView: UITextView) {
        let limit = isSupportUrlPreview ? maxInputLength : maxLength
        let validText = getValidText(textView)
        let validTextLength = getLength(forText: validText)
        if let undoManager = textView.undoManager,
           undoManager.isUndoing || undoManager.isRedoing {
            /// 系统撤销会调用 textViewDidChange()
            /// textViewDidChange() 内部存在字数限制，需要去修改当前 text
            /// 系统记录完文本操作历史后又产生了新的、不被记录的文本变化，于是最终执行 undo 时数据前后不匹配，crash
            current.text = validText
            updateTextCount(validTextLength)
            return
        }
        if validTextLength > limit {
            let trimmedText = getPrefix(limit, forText: textView.text)
            textView.text = trimmedText
            current.text = trimmedText
            updateTextCount(getLength(forText: trimmedText))
            notifyTextLimitation()
        } else {
            current.text = validText
            updateTextCount(validTextLength)
        }
        if isSupportUrlPreview { changeBorderEditingColor(validTextLength) }
        // Adjust content offset to avoid UI bug under iOS13
        if #unavailable(iOS 13) {
            let range = NSRange(location: (textView.text as NSString).length - 1, length: 1)
            textView.scrollRangeToVisible(range)
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        /// 端上限制字符数时，如果进行撤销操作可能导致 range 越界，此时继续返回 true 会造成 crash
        if NSMaxRange(range) > textView.text.utf16.count {
            return false
        }
        var result = true
        if isSupportUrlPreview {
            result = self.textInputProtocolSet.textView(textView, shouldChangeTextIn: range, replacementText: text)
            if !result { customTextViewDidChange(textView) }
        }
        return result
    }

    // 按照特定字符计数规则，获取字符串长度
    private func getLength(forText text: String) -> Int {
        return text.reduce(0) { res, char in
            // 单字节的 UTF-8（英文、半角符号）算 1 个字符，其余的（中文、Emoji等）算 2 个字符
            return res + min(char.utf8.count, 2)
        }
    }

    // 按照特定字符计数规则，截取字符串
    private func getPrefix(_ maxLength: Int, forText text: String) -> String {
        guard maxLength >= 0 else { return "" }
        var currentLength: Int = 0
        var maxIndex: Int = 0
        for (index, char) in text.enumerated() {
            guard currentLength <= maxLength else { break }
            currentLength += min(char.utf8.count, 2)
            maxIndex = index
        }
        return String(text.prefix(maxIndex))
    }

    private func updateTextCount(_ textCount: Int) {
        let limit = isSupportUrlPreview ? maxSaveLength : maxLength
        let displayCount = isSupportUrlPreview ? Int(ceil(Float(textCount))) : Int(ceil(Float(textCount) / 2))
        let totalCount = isSupportUrlPreview ? Int(ceil(Float(limit))) : Int(ceil(Float(limit) / 2))
        let exceedColor = isSupportUrlPreview ? UIColor.ud.functionDangerContentDefault : UIColor.ud.functionWarningContentDefault
        let fullText = "\(displayCount)/\(totalCount)"
        let fullAttr = NSMutableAttributedString(string: fullText)
        if isSupportUrlPreview, (textCount > limit) {
            //更新displayText字体颜色
            fullAttr.addAttributes([.foregroundColor: exceedColor], range: (fullText as NSString).range(of: String(displayCount)))
        }
        numberLabel.attributedText = fullAttr
    }

    private func notifyTextLimitation() {
        // May be toast.
    }

    // MARK: - URL Preview
    fileprivate func initInputHandler() {
        let urlInputHandler = WorkDescriptionURLInputHander(urlPreviewAPI: self.model.urlPreviewAPI)
        urlInputHandler.previewCompleteBlock = { [weak self] textView in
            guard let self = self else { return }
            Self.logger.info("url preview complete")
            let textCount = self.getLength(forText: textView.text)
            self.updateTextCount(textCount)
            self.changeBorderEditingColor(textCount)
        }
        let textInputProtocolSet = TextViewInputProtocolSet([urlInputHandler])
        self.textInputProtocolSet = textInputProtocolSet
        self.textInputProtocolSet.register(textView: textView)
    }
}

class WorkDescriptionURLInputHander: BaseURLInputHander {
    override var psdaToken: String {
        return "LARK-PSDA-url_preview_url_input_handler"
    }
}

extension WorkDescriptionSetController {

    enum Cons {
        static var descriptionFont: UIFont { .systemFont(ofSize: 16) }
        static var headerFont: UIFont { .systemFont(ofSize: 14) }
        static var textViewHeiht: CGFloat { 136 }
        static var hMargin: CGFloat { 16 }
        static var hPadding: CGFloat { 12 }
        static var linkColor: UIColor { UIColor.ud.textLinkNormal }
        static var textColor: UIColor { UIColor.ud.textTitle }
    }
}
