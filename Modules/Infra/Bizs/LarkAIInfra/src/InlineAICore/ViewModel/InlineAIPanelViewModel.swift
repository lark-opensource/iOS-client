//
//  InlineAIPanelViewModel.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/4/26.
//  


import UIKit
import RxRelay
import RxSwift
import LarkKeyboardKit
import TangramService
import LarkBaseKeyboard
import EditTextView
import LarkModel
import ByteWebImage
import LarkSetting
import LarkDocsIcon

final class InlineAIPanelViewModel {
    
    // 绑定AI面板上的点击事件，不包括独立二级菜单面板
    var eventRelay = PublishRelay<InlineAIEvent>()
    
    var subPromptEventRelay = PublishRelay<InlineAIEvent>()
    
    var showPanelRelay = PublishRelay<InlineAIPanelModel>()
    
    var isShowing = BehaviorRelay<Bool>(value: false)
    
    var model: InlineAIPanelModel?
    
    var setVisible = false

    let disposeBag = DisposeBag()

    weak var panelView: UIView?
    
    lazy var imageCache = InlineAIImageCache()
    
    lazy var historyPrompts: [RecentAction] = []

    lazy var tracker: LarkInlineAITracker = {
        return LarkInlineAITracker.init(baseParqams: { [weak self] in
            guard let aiFullDelegate = self?.aiFullDelegate else { return [:] }
            return aiFullDelegate.getBizReportCommonParams()
        }, scenario: config.scenario)
    }()
    
    lazy var downloadImageManager: DownloadImageManager = {
#if DEBUG
        let isUnitTestEnv = ProcessInfo.processInfo.environment["IS_TESTING_INLINE_AI"] == "1"
        var api: DownloadAIImageAPI?
        if !isUnitTestEnv {
            api = LarkImageService.shared
        }
        let manager = DownloadImageManager(api: api)
#else
        let manager = DownloadImageManager(api: LarkImageService.shared)
#endif
    
        manager.delegate = self
        return manager
    }()
    
    lazy var dataProvider: InlineAIDataProvider = {
        return InlineAIDataProvider(userResolver: self.config.userResolver)
    }()
    
    var aiInfoService: MyAIInfoService? {
        return try? config.userResolver.resolve(type: MyAIInfoService.self)
    }
    
    lazy var promptSearchUtils = PromptSearchUtils()

    lazy var urlParser: InlineAIURLParser = {
        let linkRegex = InlineAISettings.urlRegexConfig?.linkRegex ?? ""
        let userResolver = self.config.userResolver
        let parser = LarkAIInfra.InlineAIURLParser(regexString: linkRegex,
                                             docsIconRequest: DocsIconRequest(userResolver: userResolver),
                                             docsUrlUtil: DocsUrlUtil(userResolver: userResolver))
        parser.delegate = self
        return parser
    }()
    
    lazy var settings: InlineAISettings = {
        return InlineAISettings(userResolver: self.config.userResolver)
    }()

    var aiState = InlineAIState(sectionId: "")
    
    var inputText: String = ""

    enum Output {
        case none
        case updatePanelViewBottom(inset: CGFloat, duration: CGFloat)
        case handlePanGestureRecognizer(gestureRecognizer: UIPanGestureRecognizer)
        case textViewHeightChange
        case resignInputFirstResponder
        case hideAllSubPromptView
        case clearTextView
        case show(model: InlineAIModelWrapper)
        case lockScreen(lock: Bool)
        case updateImageCheckbox([InlineAICheckableModel])
        case insertPickerItems(items: [PickerItem]?, range: NSRange)
        case presentVC(UIViewController)
        case statusChangeToLoading // 最开始loading时
        case showAlert // 最开始loading时
        case showPromptPanel(model: InlineAIPanelModel.Prompts, dragBar: InlineAIPanelModel.DragBar)
        case showErrorMsg(String)
        case showSuccessMsg(String)
        case dismissPanel
        case contentRenderEnd
        case updateSubPromptPanel(model: InlineAIPanelModel.Prompts, dragBar: InlineAIPanelModel.DragBar)
        case showFeedbackAlert(LarkInlineAIFeedbackConfig)
        case debugInfo(AITask)
        case localResourceMapLoaded([String: String])
    }
    
    var modelDescription = ModelDescription(visiableViews: [], changes: [])
    
    var output = BehaviorRelay<Output>(value: .none)

    weak var aiDelegate: LarkInlineAIUIDelegate?
    
    weak var aiFullDelegate: LarkInlineAISDKDelegate?
    
    var isKeyboardShow = false
    
    var keyBoardHeight = 0.0
    
    var currentModel: InlineAIModelWrapper?
    
    var urlPreviewAPI: URLPreviewAPI? {
        return try? config.userResolver.resolve(type: URLPreviewAPI.self)
    }
    
    var nickName: String {
        return aiInfoService?.info.value.name ?? "My AI"
    }

    var myAIEnable: BehaviorRelay<Bool> {
        guard let enableRelay =  aiInfoService?.enable else {
            LarkInlineAILogger.error("info service is nil")
            return BehaviorRelay<Bool>(value: false)
        }
        return enableRelay
    }

    lazy var feedbackCallback: ((LarkInlineAIFeedbackConfig) -> ()) = { [weak self] in
        guard let self = self else { return }
        if $0.isLike, self.lastLikeState == true {
            self.sendLikeFeedback(config: $0) // 点赞上报
        } else if !$0.isLike, self.lastLikeState == false {
            self.output.accept(.showFeedbackAlert($0)) // 点踩弹框
        }
    }
    
    /// 最后的赞踩按钮选中状态:    nil：未选中，true：已点赞，false：已点踩
    private(set) var lastLikeState: Bool?
    
    var config: InlineAIConfig

    init(aiDelegate: LarkInlineAIUIDelegate?, aiFullDelegate: LarkInlineAISDKDelegate?, config: InlineAIConfig) {
        self.aiDelegate = aiDelegate
        self.aiFullDelegate = aiFullDelegate
        self.config = config
        handleUIEvent()
        handleSubPromptEvent()
        initData()
    }

    private func handleUIEvent() {
        eventRelay.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .textViewDidEndEditing:
                LarkInlineAILogger.info("textViewDidEndEditing")
                self.isKeyboardShow = false
                self.aiDelegate?.keyboardChange(show: false)
                
            case .textViewDidBeginEditing:
                LarkInlineAILogger.info("textViewDidBeginEditing")
                self.isKeyboardShow = true
                
            case .autoActiveKeyboard:
                self.isKeyboardShow = true
                self.aiDelegate?.keyboardChange(show: self.isKeyboardShow)
                
            case let .keyboardEventChange(event):
                self.handleKeyboardChange(event)
                
            case let .panGestureRecognizerChange(gestureRecognizer):
                self.handlePanGestureRecognizer(gestureRecognizer)

            case .textViewHeightChange:
                self.handleTextViewHeightChange()

            case .clickOverlapPromptMaskArea:
                self.output.accept(.resignInputFirstResponder)

            case let .clickAIImage(model):
                self.handleClickAIImage(model)
            case .updateTheme:
                guard var currentModel = self.model else { break }
                currentModel.theme = self.getCurrentTheme()
                self.updateModel(currentModel)
            default:
                self.dispatchDelegateDirectly(event: event)
            }
            
        }).disposed(by: disposeBag)
    }
    
    // 直接传递给delegate放这里（减少代码复杂度拆离出来）
    private func dispatchDelegateDirectly(event: InlineAIEvent) {
        handleEventCommonLogic(event)
        if config.isFullSDK {
            handleEventInternal(event: event)
            return
        }
        switch event {
        case let .choosePrompt(prompt):
            self.handleChoosePrompt(prompt: prompt)
            
        case let .deleteHistoryPrompt(prompt):
            self.aiDelegate?.onDeleteHistoryPrompt(prompt: prompt)

        case let .textViewDidChange(text):
            self.inputText = text
            self.aiDelegate?.onInputTextChange(text: text)
            
        case let .chooseOperator(operate):
            self.aiDelegate?.onClickOperation(operate: operate)
            
        case .chooseSheetOperation:
            self.aiDelegate?.onClickSheetOperation()
            
        case .clickMaskErea:
            self.aiDelegate?.onClickMaskArea(keyboardShow: self.isKeyboardShow)
            
        case .closePanel:
            self.aiDelegate?.onSwipHidePanel(keyboardShow: self.isKeyboardShow)
            
        case .clickPrePage:
            self.aiDelegate?.onClickHistory(pre: true)
            
        case let .clickThumbUp(isSelected):
            self.aiDelegate?.onClickFeedback(like: true, callback: feedbackCallback)
            self.model?.feedback?.update(like: isSelected)
            self.model?.feedback?.update(unlike: false)

        case .clickNextPage:
            self.aiDelegate?.onClickHistory(pre: false)
            
        case let .clickThumbDown(isSelected):
            self.aiDelegate?.onClickFeedback(like: false, callback: feedbackCallback)
            self.model?.feedback?.update(unlike: isSelected)
            self.model?.feedback?.update(like: false)

        case let .clickAt(selectedRange):
            switch self.config.mentionTypes.first { // v7.4 只支持单个类型
            case .doc: // 实现在CCM
                self.aiDelegate?.onClickAtPicker { [weak self] pickerItem in
                    let items = pickerItem.map { [$0] }
                    self?.output.accept(.insertPickerItems(items: items, range: selectedRange))
                }
            case .user: // 实现在LarkAI
                if let mentionService = try? self.config.userResolver.resolve(assert: InlineAIMentionUserService.self) {
                    let firstPageLoader = dataProvider.getMentionRecommendUsers()
                    mentionService.setRecommendUsersLoader(firstPageLoader: firstPageLoader, moreLoader: .empty())
                    let title = BundleI18n.LarkAIInfra.Doc_At_MentionUserTip
                    mentionService.showMentionUserPicker(title: title, callback: { [weak self] items in
                        self?.output.accept(.insertPickerItems(items: items, range: selectedRange))
                    })
                }
            case .none:
                break
            }
        case let .keyboardDidSend(richTextContent):
            self.aiDelegate?.onClickSend(content: richTextContent)
            
        case .stopGenerating:
            self.aiDelegate?.onClickStop()
            
        case let .panelHeightChange(height):
            LarkInlineAILogger.info("panelHeightChange: \(height)")
            self.aiDelegate?.onHeightChange(height: height)
        case let .clickCheckbox(model):
            self.handleClickCheckbox(model)
            
        case let .openURL(url):
            LarkInlineAILogger.info("click link")
            self.aiDelegate?.onOpenLink(url: url)
            
        case .getEncryptId(let completion):
            let encryptId = self.aiDelegate?.getEncryptId()
            completion(encryptId)
            
        case let .sendRecentPrompt(prompt):
            self.aiDelegate?.onClickPrompt(prompt: prompt)

        default:
            LarkInlineAILogger.error("event:\(event) is missing")
        }
    }
    
    private func handleSubPromptEvent() {
        subPromptEventRelay.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
            case let .choosePrompt(prompt):
                if !prompt.rightArrow {
                    self.output.accept(.hideAllSubPromptView)
                }
                if self.aiFullDelegate != nil {
                    self.choosePromptInFullMode(prompt: prompt)
                } else {
                    self.aiDelegate?.onClickSubPrompt(prompt: prompt)
                }
            case let .deleteHistoryPrompt(prompt):
                if config.isFullSDK {
                    self.handelDeleteHistoryPrompt(prompt: prompt)
                } else {
                    self.aiDelegate?.onDeleteHistoryPrompt(prompt: prompt)
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    private func handleClickCheckbox(_ model: InlineAICheckableModel) {
        var checked = true
        if self.currentModel != nil {
            // 本地先设置
            if model.checkNum > 0 { // 取消勾选
                self.currentModel?.panelModel.images?.removeIdFromCheckList(id: model.id)
                checked = false
            } else { // 勾选
                self.currentModel?.panelModel.images?.addIdToCheckList(id: model.id)
            }
            if let imagesModel = self.currentModel?.panelModel.images {
                let checkableModels = self.generateImageCheckableModel(with: imagesModel)
                self.output.accept(.updateImageCheckbox(checkableModels))
            } else {
                LarkInlineAILogger.error("images model is nil")
            }
        } else {
            LarkInlineAILogger.error("currentModel is nil")
        }
        self.aiDelegate?.onClickImageCheckbox(imageData: InlineAIPanelModel.ImageData(url: "", id: model.id), checked: checked)
    }
    
    private func handleBrowserVCAction(_ action: InlineImageBrowserViewController.Action) {
        switch action {
        case let .selectImage(model):
            self.handleClickCheckbox(model)
        case let .insertImages(models): // 插入图片到正文
            self.aiDelegate?.imagesInsert(models: models)
        case .saveImage:
            // 目前暂未支持
            break
        }
    }

    // InlineAIEvent的公共部分处理
    private func handleEventCommonLogic(_ event: InlineAIEvent) {
        switch event {
        case .clickThumbUp(let isSelected):
            lastLikeState = isSelected ? true : nil
        case .clickThumbDown(let isSelected):
            lastLikeState = isSelected ? false : nil
        case .contentRenderEnd:
            self.output.accept(.contentRenderEnd)
        case .vcViewDidLoad:
            let completion: ([String: String]) -> Void = { [weak self] map in
                self?.output.accept(.localResourceMapLoaded(map))
                LarkInlineAILogger.info("update filename-path size:\(map.count)")
            }
            aiDelegate?.onExtraOperation(type: InlineAIExtraOperation.getLocalResource, data: completion)
        default:
            break
        }
    }
}

extension InlineAIPanelViewModel {
    
    var isGenerating: Bool {
        return self.currentModel?.panelModel.input?.status == 1
    }
    
    func updateModel(_ model: InlineAIPanelModel) {
        LarkInlineAILogger.info("update AI Model: \(model)")
        if let oldModel = self.model {
            if oldModel.input?.status == 0, model.input?.status == 1 {
                self.output.accept(.statusChangeToLoading)
            }
        } else {
            self.output.accept(.statusChangeToLoading)
        }
        self.model = model
        generateModelDescription(model)
        
        var imagesModel: [InlineAICheckableModel] = []
        if let images = model.images, images.canDisplay == true {
            imagesModel = generateImageCheckableModel(with: images)
            downloadImageManager.downloadImage(models: imagesModel)
        }
        let modelWrapper = InlineAIModelWrapper(panelModel: model, imageModels: imagesModel)
        self.currentModel = modelWrapper
        self.output.accept(.show(model: modelWrapper))
        if let lock = model.lock {
            self.output.accept(.lockScreen(lock: lock))
        }
    }
        
    func generateModelDescription(_ model: InlineAIPanelModel) {
        var changes: Set<UIType> = []
        var visiableViews: Set<UIType> = []
        model.allDisplayModels.forEach {
            if $0.canDisplay {
                visiableViews.insert($0.uiType)
            }
        }
        if model.content?.isEmpty == false {
            visiableViews.insert(.content)
        }
        guard let currentModel = self.currentModel else {
            changes = Set(UIType.allCases)
            if model.images == nil || model.images?.show == false {
                changes.remove(.images)
            }
            self.modelDescription = ModelDescription(visiableViews: visiableViews, changes: changes)
            return
        }
        let panelModel = currentModel.panelModel
        if panelModel.dragBar != model.dragBar {
            changes.insert(.dragBar)
        }
        
        if panelModel.input != model.input {
            changes.insert(.input)
        }
        
        if panelModel.content != model.content {
            changes.insert(.content)
        }
        
        if panelModel.images?.show == false && model.images?.show == true ||
            panelModel.images == nil, model.images?.show == true {
            changes.insert(.images)
        }

        if panelModel.tips != model.tips {
            changes.insert(.tips)
        }
        
        if panelModel.prompts != model.prompts {
            changes.insert(.prompt)
        }
        
        if panelModel.operates != model.operates {
            changes.insert(.operate)
        }
        
        if panelModel.history != model.history {
            changes.insert(.history)
        }
        
        if panelModel.feedback != model.feedback {
            changes.insert(.feedback)
        }
        LarkInlineAILogger.info("changes: \(changes) visiableViews:\(visiableViews)")
        self.modelDescription = ModelDescription(visiableViews: visiableViews, changes: changes)
    }
    
    func generateImageCheckableModel(with imagesModel: InlineAIPanelModel.Images) -> [InlineAICheckableModel] {
        guard imagesModel.show else { return [] }
        var models: [InlineAICheckableModel] = []
        if let data = imagesModel.data, !data.isEmpty {
            for urlModel in data {
                let defaultNum = -1
                let disableNum = -2
                var checkNum = imagesModel.checkList.firstIndex(of: urlModel.id) ?? defaultNum
                let checkable = urlModel.checkable ?? false
                checkNum = checkable ? checkNum : disableNum
                var source: InlineAIImageData = .placeholder
                if imagesModel.canShow, let imageCache = imageCache.imageDownloadCache[urlModel.id] {
                    if let image = imageCache.image {
                        source = .image(image)
                    } else { // 目前暂不会自动重试，直接展示失败兜底图
                        source = .error
                    }
                } else if let url = URL(string: urlModel.url.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    source = .url(url)
                } else {
                    LarkInlineAILogger.info("keep loading, canShow:\(imagesModel.canShow) url:\(urlModel.url.md5())")
                }
                models.append(InlineAICheckableModel(checkNum: checkNum + 1, source: source, id: urlModel.id))
            }
            LarkInlineAILogger.info("show makeup image")
        } else {
            // 默认展示4张loading
            LarkInlineAILogger.info("show default placeholder image")
            let model = InlineAICheckableModel(checkNum: 0, source: .placeholder, id: "placeholder")
            models = Array<InlineAICheckableModel>(repeating: model, count: 4)
        }
        LarkInlineAILogger.info("check info:\(models)")
        return models
    }
    
    /// 检查图片下载结果，并通知前端
    func checkImageDownloadResult() {
        var result: [InlineAIImageDownloadResult] = []
        var downloadingIds: [String] = []
        if let imageModels = self.currentModel?.imageModels {
            for imageModel in imageModels {
                guard let res = self.imageCache.imageDownloadCache[imageModel.id] else {
                    // 仍有图片未下载完
                    downloadingIds.append(imageModel.id)
                    continue
                }
                result.append(InlineAIImageDownloadResult(id: imageModel.id, success: res.success))
            }
        }
        guard downloadingIds.isEmpty else {
            LarkInlineAILogger.info("need downloading id:\(downloadingIds)")
            return
        }
        self.aiDelegate?.imagesDownloadResult(results: result)
    }
}

// MARK: - InlineAIImageManagerDelegate
extension InlineAIPanelViewModel: InlineAIImageManagerDelegate {
    func aiImageDownloadSuccess(with model: InlineAICheckableModel, image: UIImage?) {
        self.imageCache.imageDownloadCache[model.id] = (image, image != nil)
        self.checkImageDownloadResult()
    }
    
    func aiImageDownloadFailure(with model: InlineAICheckableModel) {
        self.imageCache.imageDownloadCache[model.id] = (nil, false)
        self.checkImageDownloadResult()
    }
    
}


// MARK: - keyboard
extension InlineAIPanelViewModel {
    
    func handleKeyboardChange(_ event: KeyboardEvent) {
        guard let vcView = self.panelView?.superview else { return }
        let endFrame = event.options.endFrame
        let duration: CGFloat = 0.25
        switch event.type {
        case .willShow:
            LarkInlineAILogger.info("KeyboardChange: willShow:\(endFrame)")
            var delta: CGFloat = .zero
            if let window = vcView.window, aiDelegate?.getShowAIPanelViewController().isFormSheet == true {
                //fromSheet方式弹出时直接使用endFrame计算
                delta = window.frame.height - endFrame.minY
            } else {
                //键盘落在vcView上的区域
                let frameInView = vcView.convert(endFrame, from: nil)
                //键盘上边缘到vcView底部的距离
                delta = vcView.bounds.height - frameInView.minY
            }
            keyBoardHeight = delta
            output.accept(.updatePanelViewBottom(inset: delta, duration: duration))
            aiDelegate?.keyboardChange(show: true)
        case .willHide:
            LarkInlineAILogger.info("KeyboardChange: willHide:\(endFrame)")
            keyBoardHeight = 0
            output.accept(.updatePanelViewBottom(inset: 0, duration: duration))
            aiDelegate?.keyboardChange(show: false)
        default:
            break
        }
    }
    
    func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        output.accept(.handlePanGestureRecognizer(gestureRecognizer: gestureRecognizer))
    }
    
    func handleTextViewHeightChange() {
        output.accept(.textViewHeightChange)
    }
    
    func handleChoosePrompt(prompt: InlineAIPanelModel.Prompt) {
        self.output.accept(.resignInputFirstResponder)
        self.output.accept(.clearTextView)
        self.aiDelegate?.onClickPrompt(prompt: prompt)
    }
    
    func handleClickAIImage(_ model: InlineAICheckableModel) {
        switch model.source {
        case .placeholder, .url, .error:
            LarkInlineAILogger.info("click ai image invalid")
            return
        case .image:
            break
        }
        if let imagesModel = self.currentModel?.panelModel.images {
            var checkableModels = self.generateImageCheckableModel(with: imagesModel)
            checkableModels = checkableModels.filter { $0.style != .disable && $0.source.isImage }
            if let idx = checkableModels.firstIndex(where: { $0.id == model.id }) {
                LarkInlineAILogger.info("click ai image id:\(model.id)")
                let vc = InlineImageBrowserViewController(config: .init(), dataSource: checkableModels, currentIndex: idx)
                self.output.accept(.presentVC(vc))
                vc.eventRelay.subscribe(onNext: { [weak self] action in
                    self?.handleBrowserVCAction(action)
                }).disposed(by: self.disposeBag)
            } else {
                LarkInlineAILogger.error("generate checkable model not contain id:\(model.id)")
            }
        } else {
            LarkInlineAILogger.error("images model is nil!")
        }
    }
}
