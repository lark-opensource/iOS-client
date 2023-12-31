//
//  DKInlineAIServiceModule.swift
//  SKDrive
//
//  Created by huayufan on 2023/10/11.
//  


import SKUIKit
import LarkContainer
import LarkAIInfra
import SKFoundation
import RxSwift
import RxCocoa
import SKResource
import ServerPB
import SKInfra
import UniverseDesignToast
import LarkReleaseConfig
import LarkEMM

// ReleaseConfig.isFeishu
fileprivate enum LanguageType: String, CaseIterable {
    /** 简体中文 */
    case simplifiedChinese = "Simplified Chinese"
    /** 繁体中文 */
    case traditionalChinese = "Traditional Chinese"
     /** 英语 */
    case english = "English"
     /** 日语 */
    case japanese = "Japanese"
     /** 泰语 */
    case thai = "Thai"
     /** 印地语 */
    case hindi = "Hindi"
     /** 印度尼西亚语 */
    case indonesian = "Indonesian"
     /** 法语 */
    case french = "French"
     /** 西班牙语 */
    case spanish = "Spanish"
     /** 葡萄牙语 */
    case portuguese = "Portuguese"
     /** 韩语 */
    case korean = "Korean"
     /** 越南语 */
    case vietnamese = "Vietnamese"
     /** 俄语 */
    case russian = "Russian"
     /** 德语 */
    case german = "German"
     /** 意大利语 */
    case italian = "Italian"
     /** 阿拉伯语 */
    case arabic = "Arabic"
     /** 波兰语 */
    case polish = "Polish"
     /** 塔加路语（菲律宾语） */
    case tagalog = "Tagalog" // Filipino

    var title: String {
        switch self {
        case .simplifiedChinese:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_ZHsimplified_Option
        case .english:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_EN_Option
        case .traditionalChinese:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_ZHtradition_Option
        case .japanese:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_JP_Option
        case .thai:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Thai_Option
        case .hindi:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Hindi_Option
        case .indonesian:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Indo_Option
        case .french:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Fr_Option
        case .spanish:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_ES_Option
        case .portuguese:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_PT_Option
        case .korean:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_KO_Option
        case .vietnamese:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Vi_Option
        case .russian:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_RU_Option
        case .german:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_De_Option
        case .italian:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_IT_Option
        case .arabic:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Arab_Option
        case .polish:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Polish_Option
        case .tagalog:
            return BundleI18n.SKResource.LarkCCM_Docs_MyAi_TranslateInto_Tagalog_Option
        default:
            DocsLogger.error("[AILogger] [pdf] language:\(self.rawValue) title")
            return ""
        }
    }
}

enum DKPDFInlineAIAction {
    case none
    case updateMenus([PDFMenuType])
    case canCopyOutside(Bool)
    case canCopyInside(Bool)
}

// PDF接入AI浮窗
class DKInlineAIServiceModule: DKBaseSubModule {
    
    var userResolver: LarkContainer.UserResolver {
        return Container.shared.getCurrentUserResolver()
    }
    private lazy var aiModule: LarkInlineAISDK = {
        var placeHolder = PlaceHolder.defaultPlaceHolder
        placeHolder.update(waitingPlaceHolder: BundleI18n.SKResource.LarkCCM_Docs_MyAi_ForViewer_WhatToKnwo_Placeholder)
        var config = InlineAIConfig(captureAllowed: true,
                                    scenario: .pdfView,
                                    placeHolder: placeHolder,
                                    maskType: .fullScreen,
                                    userResolver: self.userResolver)
#if DEBUG || BETA || ALPHA
        config.update(debug: true)
#endif
        let module = LarkInlineAIModuleGenerator.createAISDK(config: config, customView: nil, delegate: self)
        return module
    }()
    
    private var quickActions: [InlineAIQuickAction] = []
    
    private let disposeBag = DisposeBag()
    
    private var menus: [PDFMenuType] = []
    
    private var aiOutput: String?
    
    private var selectedText: String?
    
    private var pointId: String?

    private var canCopyOutside: Bool = false
    
    private var canCopyInside: Bool = false

    private var cachePromptGroup: [AIPromptGroup] = []
    
    let translateKey = "translate"
    
    var needLandscapeWarnig: Bool {
        return SKDisplay.phone && UIApplication.shared.statusBarOrientation.isLandscape
    }

    override init(hostModule: DKHostModuleType) {
        super.init(hostModule: hostModule)
        DispatchQueue.main.async {
            self.fetchAIPrompts()
        }
    }

    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        self.hostModule?.pdfInlineAIAction?.subscribe(onNext: { [weak self] action in
            switch action {
            case .canCopyOutside(let canCopy):
                self?.canCopyOutside = canCopy
            case .canCopyInside(let canCopy):
                self?.canCopyInside = canCopy
            default:
                break
            }
        }).disposed(by: disposeBag)
        return self
    }
    
    private func setupMenus() {
        guard aiModule.isEnable.value else {
            DocsLogger.error("[AILogger] [pdf] ai is invalid now")
            return
        }
        aiModule.isEnable
                .distinctUntilChanged()
                .subscribe(onNext: { [weak self] isEnable in
                  guard let self = self else { return }
                  if isEnable == false, self.aiModule.isPanelShowing.value {
                        self.hidePanel()
                        self.hostModule?.pdfInlineAIAction?.accept(.updateMenus([]))
                  }
        }).disposed(by: self.disposeBag)
        
        var tempMenus: [PDFMenuItem] = []
        for quickAction in quickActions {
            let type = getCommandTypeOfExtraMap(extraMap: quickAction.extraMap) ?? quickAction.id
            tempMenus.append(PDFMenuItem(title: quickAction.name, identifier: "ai_pdf_\(type)", callback: { [weak self] (content, pointId) in
                guard let self = self else { return }
                if self.forceInterfaceOrientation() {
                    return
                }
                self.pointId = pointId
                self.aiMenuAction(content, quickAction)
            }))
        }

        if tempMenus.count > 0 {
            tempMenus.insert(PDFMenuItem(title: getAINickname(), identifier: "My AI", callback: { [weak self] (content, pointId) in
                guard let self = self else { return }
                if self.forceInterfaceOrientation() {
                    return
                }
                self.checkCopyPerm()
                self.pointId = pointId
                self.selectedText = content
                self.aiModule.showPanel(promptGroups: self.cachePromptGroup)
            }), at: 0)
            tempMenus.append(PDFMenuItem(title: BundleI18n.SKResource.LarkCCM_Docs_MyAi_Copy_Menu, identifier: SKPDFView.Identifier.copy, callback: { [weak self] (content, pointId) in
                guard let self = self else { return }
                self.pointId = pointId
                self.handleCopyAction(content: content)
            }))
        }
        if #available(iOS 16, *) {
            // iOS16之后的顺序是反的
            tempMenus.reverse()
        }
        self.menus = tempMenus
        self.hostModule?.pdfInlineAIAction?.accept(.updateMenus(menus))
    }
    
    /// 获取 AI 品牌名（用于填充文案）
    private func getAIBrandName() -> String {
        if let aiInfo = try? userResolver.resolve(type: MyAIInfoService.self) {
            return aiInfo.defaultResource.name
        } else {
            DocsLogger.error("[AILogger] [pdf] can not resolve MyAIInfoService from current userResolver")
            return MyAIResource.getFallbackName(isFeishu: ReleaseConfig.isFeishu)
        }
    }

    /// 获取 AI 昵称
    private func getAINickname() -> String {
        if let aiInfo = try? userResolver.resolve(type: MyAIInfoService.self) {
            return aiInfo.info.value.name
        } else {
            return getAIBrandName()
        }
    }

    func showMsg(msg: String, success: Bool) {
        guard let hostVC = self.hostModule?.hostController else {
            DocsLogger.error("[AILogger] [pdf] hostController is nil")
            return
        }
        if success {
            UDToast.showSuccess(with: msg, on: hostVC.view.window ?? hostVC.view)
        } else {
            UDToast.showFailure(with: msg, on: hostVC.view.window ?? hostVC.view)
        }
    }

    private func cachePrompts() {
        let prompts = quickActions.map {
           let prompt = self.transQuickActionToPrompt($0)
            if prompt.type == translateKey {
                prompt.children = constructTranslatePrompt(parent: prompt, quickAction: $0)
            }
            return prompt
        }
        self.cachePromptGroup = [AIPromptGroup(title: "", prompts: prompts)]
    }
    
    var localChildExtraParams: [String: [String: String]] = [:]

    private func constructTranslatePrompt(parent: AIPrompt, quickAction: InlineAIQuickAction) -> [AIPrompt] {
        var lans: [LanguageType] = []
        if ReleaseConfig.isFeishu {
            lans = [.simplifiedChinese, .english]
        } else {
            lans = LanguageType.allCases
        }
       
        return lans.map({
            let id = UUID().uuidString
            let prompt = AIPrompt(id: parent.id, localId: id, icon: "", text: $0.title, callback: getPromptCallback(quickAction, ["language": $0.rawValue]))
            return prompt
        })
    }
    
    private func aiMenuAction(_ selectedText: String, _ quickAction: InlineAIQuickAction) {
        self.selectedText = selectedText
        let allPrompts = self.cachePromptGroup.flatMap { $0.prompts }
        guard let prompt = allPrompts.first(where: { $0.id == quickAction.id }) else {
            DocsLogger.error("[AILogger] [pdf] click menu name:\(quickAction.name) id:\(quickAction.id) not found")
            return
        }
        checkCopyPerm()
        aiModule.sendPrompt(prompt: prompt, promptGroups: nil)
    }

    private func fetchAIPrompts(){
        guard hostModule?.scene == .space else {
            DocsLogger.error("[AILogger] [pdf] space:\(hostModule?.scene) is not supported")
            return
        }
        guard aiModule.isEnable.value else {
            DocsLogger.error("[AILogger] [pdf] ai is invalid now")
            return
        }
        guard UserScopeNoChangeFG.HYF.pdfInlineAIMenuEnable else { return }
        requstQuickAction().retry(3)
            .subscribe { [weak self] quickActions in
                self?.quickActions = quickActions
                self?.setupMenus()
                self?.cachePrompts()
            } onError: { error in
                DocsLogger.error("[AILogger] [pdf] requstQuickAction error", error: error)
            }.disposed(by: disposeBag)
    }
    
    private func requstQuickAction() -> Observable<[InlineAIQuickAction]> {
        return Observable<[InlineAIQuickAction]>.create { observer -> Disposable in
            self.aiModule.getPrompt(triggerParamsMap: [:]) { result in
                switch result {
                case let .success(actions):
                    observer.onNext(actions)
                case let .failure(error):
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func handleCopyAction(content: String, isMenu: Bool = true) {
        if isMenu { // 气泡菜单才会检测
            if !self.canCopyOutside, !self.canCopyInside {
                self.showMsg(msg: BundleI18n.SKResource.Doc_Doc_CopyFailed, success: false)
                return
            }
        }
         let isSuccess = SKPasteboard.setString(content,
                                                 pointId: isMenu ? self.pointId : nil,
                                  psdaToken: PSDATokens.Drive.drive_preview_aiservice_copy_content)
        
          if isSuccess, !isMenu {
              self.showMsg(msg: BundleI18n.SKResource.Doc_Doc_CopySuccess, success: true)
          } else if !isSuccess {
               DocsLogger.error("[AILogger] [pdf] can not copy to SKPasteboard")
          }
      
    }

    func checkCopyPerm() {
        guard let hostController = self.hostModule?.hostController else {
            DocsLogger.error("[AILogger] [pdf] host vc is nil")
            return
        }
        if !self.canCopyOutside {
            UDToast.showTips(with: BundleI18n.SKResource.LarkCCM_Docs_MyAi_NoPerm_Copy_aiName_Toast(
                getAIBrandName()), on: hostController.view.window ?? hostController.view)
        }
    }
    
    func forceInterfaceOrientation() -> Bool {
        guard let hostVC = self.hostModule?.hostController, needLandscapeWarnig else {
            return false
        }
        UDToast.showTips(with: BundleI18n.SKResource.LarkCCM_Docx_AI_LandscapeMode_Switch,
                         operationText: BundleI18n.SKResource.LarkCCM_Docx_LandscapeMode_Switch_Button,
                         on: hostVC.view.window ?? hostVC.view,
                         operationCallBack: { _ in
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {}
        })
        return true
    }
}

public typealias QuickActionParamDetailParam = ServerPB.ServerPB_Office_ai_inline_QuickActionParam

extension InlineAIQuickAction {
    public var paramDetailsWhichNeedConfirm: [QuickActionParamDetailParam] {
        return self.paramDetails.compactMap {
            if $0.needConfirm {
                return $0
            }
            return nil
        }
    }
}


// MARK: - 构造指令
extension DKInlineAIServiceModule {
    
    func getPromptCallback(_ quickAction: InlineAIQuickAction, _ extraParams: [String: String] = [:]) -> AIPrompt.AIPromptCallback  {
        
        return .init(onStart: { [weak self] in
            guard let self = self else { return .init(isPreviewMode: true, param: [:])}
            var param = self.getPromptParam(quickAction: quickAction)
            if self.canCopyOutside == true {
                param["content"] = self.selectedText ?? ""
            }
            for (key, value) in extraParams {
                param[key] = value
            }
            return .init(isPreviewMode: true, param: param)
        }, onMessage: { [weak self] message in
            self?.aiOutput = message
        }, onError: { error in
            DocsLogger.error("[AILogger] [pdf] quick action error, id: \(quickAction.id)", error: error)
        }, onFinish: { [weak self] state in
            guard let self = self,
                  state == 0 else { return [] }
            return [self.retryButton, self.copyButton, self.exitButton]
        })
    }

    private func transQuickActionToPrompt(_ quickAction: InlineAIQuickAction, extraParams: [String: String] = [:]) -> AIPrompt {
            var templates: PromptTemplates?
            if !quickAction.paramDetailsWhichNeedConfirm.isEmpty {
                templates = .init(templatePrefix: quickAction.name,
                                  templateList: quickAction.paramDetailsWhichNeedConfirm.compactMap({ paramDetail -> PromptTemplate in
                    return .init(templateName: paramDetail.displayName,
                                 key: paramDetail.name,
                                 placeHolder: paramDetail.placeHolder)
                }))
            }
            let type = getCommandTypeOfExtraMap(extraMap: quickAction.extraMap) ?? ""
        return .init(id: quickAction.id, icon: getIconKeyOfExtraMap(extraMap: quickAction.extraMap, type: type) ?? "", text: quickAction.name,
                         type: type,
                         templates: templates,
                         children: [],
                         callback: self.getPromptCallback(quickAction, extraParams))
    }
    
    private func getChildGroupKeyFor(extraMap: [String: String]) -> String? {
            let commentMap = self.getCommentOfExtraMap(extraMap: extraMap)
            return commentMap["group_entry"] as? String
    }
    
    private func getCommentOfExtraMap(extraMap: [String: String]) -> [String: Any] {
            guard let jsonString = extraMap["Comment"] else { return [:] }
            if let jsonData = jsonString.data(using: .utf8) {
               return (try? JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any]) ?? [:]
            }
            return [:]
    }
    
    private func getIconKeyOfExtraMap(extraMap: [String: String], type: String) -> String? {
            let commentMap = getCommentOfExtraMap(extraMap: extraMap)
            let icon = (commentMap["icon"] as? String) ?? ""
            if icon.isEmpty, type == translateKey {
                return "TranslateOutlined"
            }
            return icon
    }
       
    private func getCommandTypeOfExtraMap(extraMap: [String: String]) -> String? {
            let commentMap = getCommentOfExtraMap(extraMap: extraMap)
            return commentMap["type"] as? String
    }
    
    private func getPromptParam(quickAction: InlineAIQuickAction) -> [String: String] {
        return [:]
    }
}

extension DKInlineAIServiceModule: LarkInlineAISDKDelegate {
    func getShowAIPanelViewController() -> UIViewController {
        return self.hostModule?.hostController ?? UIViewController()
    }
    
    var supportedInterfaceOrientationsSetByOutsite: UIInterfaceOrientationMask? {
        return nil
    }
    
    func onHistoryChange(text: String) {
        
    }
    
    func onHeightChange(height: CGFloat) {
        
    }
    
    func getUserPrompt() -> LarkAIInfra.AIPrompt {
        return LarkAIInfra.AIPrompt(id: nil, icon: "", text: "", callback: AIPrompt.AIPromptCallback(onStart: { [weak self] in
            guard let self = self else {
                return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: [:])
            }
            let content = self.selectedText ?? ""
            let selectedText = ["text": content]
            var params: [String: String] = [:]
            do {
                let data = try JSONEncoder().encode(selectedText)
                let jsonStr = String(data: data, encoding: .utf8) ?? "{\"text\":\"\(content)\"}"
                params["selected_text"] = jsonStr
            } catch {
                DocsLogger.error("[AILogger] [pdf] encode drive userPrompt params error", error: error)
            }
            return AIPrompt.PromptConfirmOptions(isPreviewMode: true, param: params)
        }, onMessage: {  [weak self] message in
            self?.aiOutput = message
        }, onError: { error in
            DocsLogger.error("[AILogger] [pdf] userPrompt error", error: error)
        }, onFinish: { [weak self] _ in
            guard let self = self else { return [] }
            return [self.retryButton, self.copyButton, self.exitButton]
        }))
    }
    
    func getBizReportCommonParams() -> [AnyHashable : Any] {
        return [:]
    }
}

// MARK: - OperateButton
extension DKInlineAIServiceModule {
    
    var copyButton: OperateButton {
        return OperateButton(key: "copy", text: BundleI18n.SKResource.LarkCCM_Docs_MyAi_Copy_Menu) { [weak self] (_, content) in
            self?.handleCopyAction(content: content, isMenu: false)
        }
    }
    
    var retryButton: OperateButton {
        return OperateButton(key: "retry", text: BundleI18n.SKResource.LarkCCM_Docs_MyAi_TryAgain_Button) { [weak self] _, _ in
            guard let self = self else { return }
            self.aiModule.retryCurrentPrompt()
        }
    }
    
    var exitButton: OperateButton {
        return OperateButton(key: "quit", text: BundleI18n.SKResource.LarkCCM_Docs_MyAi_Quit_Button) { [weak self] _, _ in
            guard let self = self else { return }
            self.hidePanel()
        }
    }
    
    func hidePanel() {
        self.aiModule.hidePanel(quitType: "click_button_on_result_page")
    }
}
