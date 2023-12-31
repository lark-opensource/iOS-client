//
//  SceneDetailViewModel.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/10.
//

import Foundation
import LarkContainer
import EENavigator
import LarkSDKInterface
import RxSwift
import RxCocoa
import ServerPB
import ByteWebImage
import RustPB
import LarkModel
import LarkCore
import LarkImageEditor
import LarkVideoDirector
import LarkAssetsBrowser
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkAIInfra
import LarkSetting
import LarkLocalizations

enum SceneDetailParamType {
    /// 未指定
    case unkown
    /// 场景Icon
    case sceneIcon
    /// 场景标题
    case sceneTitle
    /// 场景设定
    case sceneSetting
    /// 模型选择
    case sceneModel
    /// 插件选择
    case scenPlugin
    /// 开场白
    case openingStatement
    /// 引导问题
    case leadingQuestion
    /// 添加引导问题
    case addLeadingQuestion
    /// 分享
    case canShare
    /// 发布
    case publish
}

protocol SceneDetailCellViewModel: AnyObject {
    /// cell的类型
    var paramType: SceneDetailParamType { get }
    /// 列表的代理方法集合
    var cellVMDelegate: SceneDetailCellDelegate? { get set }
    /// TableView若使用自动高度，刷新时列表可能会闪，在vm初始化时直接声明预期高度
    var rowHeight: CGFloat { get }
    /// 提交更改前会调用这个方法，如果为false则阻塞此提交
    func checkBeforeSubmit() -> Bool
}

extension SceneDetailCellViewModel {
    func checkBeforeSubmit() -> Bool { true }
    var rowHeight: CGFloat { 48 }
}

protocol SceneDetailListApi: UIViewController {
    var userResolver: UserResolver { get }
    var _tableView: UITableView { get }
    func showSelectActionSheet(sender: UIView, finish: ((UIImage) -> Void)?)
    func dismiss()
    func reloadCell(cellVM: any SceneDetailCellViewModel)
    func removeCell(cellVM: SceneDetailCellViewModel)
    func reloadTable()
    func addCellIn(section: Int, cellVM: any SceneDetailCellViewModel)
    func scrollToCellAtTop(indexPath: IndexPath, endAction: (() -> Void)?)
    func updateState()
}

extension SceneDetailListApi {
    /// 弹拍摄/从相册选择窗
    func showSelectActionSheet(sender: UIView, finish: ((UIImage) -> Void)?) {
        // 拍摄完成后需要进行裁剪
        let complete: (UIImage, UIViewController) -> Void = { (image, picker) in
            let cropperVC = CropperFactory.createCropper(with: image)
            cropperVC.successCallback = { image, _, _ in
                picker.dismiss(animated: true) {
                    finish?(image)
                }
            }
            cropperVC.cancelCallback = { _ in picker.dismiss(animated: true) }
            picker.navigationController?.pushViewController(cropperVC, animated: true)
        }
        let actionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: false,
                popSource: UDActionSheetSource(
                    sourceView: sender,
                    sourceRect: CGRect(x: sender.bounds.width, y: sender.bounds.height / 2, width: 0, height: 0),
                    arrowDirection: .left)))

        // 拍摄
        actionSheet.addDefaultItem(text: BundleI18n.LarkAI.Lark_Legacy_UploadImageTakePhoto) { [weak self] in
            guard let self = self else { return }
            LarkCameraKit.takePhoto(from: self, userResolver: self.userResolver, completion: complete)
        }
        // 从相册选择
        actionSheet.addDefaultItem(text: BundleI18n.LarkAI.Lark_Legacy_ChooseFromPhotolibrary) { [weak self] in
            guard let self = self else { return }
            self.showPhotoLibrary(from: self, finish: { image in
                finish?(image)
            })
        }
        // 取消
        actionSheet.setCancelItem(text: BundleI18n.LarkAI.Lark_Legacy_Cancel)
        self.userResolver.navigator.present(actionSheet, from: self)
    }

    /// 从相册选择
    private func showPhotoLibrary(from: NavigatorFrom, finish: ((UIImage) -> Void)?) {
        let picker = ImagePickerViewController(assetType: .imageOnly(maxCount: 1))
        picker.showSingleSelectAssetGridViewController()
        picker.imagePickerFinishSelect = { [weak self] (picker, result) in

            guard let asset = result.selectedAssets.first, let view = self?.view else { return }
            let hud = UDToast.showLoading(on: view)
            DispatchQueue.global().async {
                let shortSideLimit = LarkImageService.shared.imageUploadSetting.avatarConfig.limitImageSize
                let shortSide = min(asset.pixelWidth, asset.pixelHeight)
                let ratio = CGFloat(min(1, Double(shortSideLimit) / Double(shortSide)))
                let size = CGSize(width: round(CGFloat(asset.pixelWidth) * ratio),
                                  height: round(CGFloat(asset.pixelHeight) * ratio))
                let image = asset.imageWithSize(size: size)
                DispatchQueue.main.async {
                    hud.remove()
                    guard let image = image else { return }
                    let cropperVC = CropperFactory.createCropper(with: image)
                    cropperVC.successCallback = { [weak picker] image, _, _ in
                        picker?.dismiss(animated: true, completion: {
                            finish?(image)
                        })
                    }
                    cropperVC.cancelCallback = { [weak picker] _ in picker?.dismiss(animated: true) }
                    picker.pushViewController(cropperVC, animated: true)
                }
            }
        }
        picker.imagePikcerCancelSelect = { (picker, _) in
            picker.dismiss(animated: true, completion: nil)
        }
        picker.modalPresentationStyle = .fullScreen
        self.userResolver.navigator.present(picker, from: self)
    }
}

typealias SceneDetailCellDelegate = SceneDetailListApi

protocol SceneDetailCell: UITableViewCell {
    associatedtype VM = SceneDetailCellViewModel
    static var identifier: String { get }
    func setCell(vm: VM)
}

//struct SceneCellViewModel
struct SceneDetailSection {
    let title: String?
    let isRequired: Bool
    var cellVMs: [any SceneDetailCellViewModel]
    public init(title: String?, isRequired: Bool, cellVMs: [any SceneDetailCellViewModel]) {
        self.title = title
        self.isRequired = isRequired
        self.cellVMs = cellVMs
    }
}

struct SceneDetailDataSource {
    var sections: [SceneDetailSection]
}

struct SceneDetailParams {
    var sceneName: String = ""
    var imageKey: String = ""
    var prologue: String = ""
    var guideQuestions: [String] = []
    var systemInstruction: String = ""
    var aiModel: String = ""
}

public class SceneDetailViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    lazy var dataSource: SceneDetailDataSource = initDataSource()
    @ScopedInjectedLazy private var sceneAPI: SceneAPI?
    private let disposeBag = DisposeBag()

    enum State {
        case blank
        case loading
        case failed
        case success
    }

    var state: State = .blank
    var sceneId: Int64?

    var navTitle: String {
        editMode ? BundleI18n.LarkAI.MyAI_Scenario_EditScenario_Title : BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Title
    }

    var confirmTitle: String {
        editMode ? BundleI18n.LarkAI.MyAI_Scenario_EditScenario_Save_Button : BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Create_Button
    }

    private let editMode: Bool
    weak var listApi: SceneDetailListApi? {
        didSet {
            resetDelegate()
        }
    }

    func resetDelegate() {
        dataSource.sections.map { $0.cellVMs }.forEach {
            $0.forEach { cellVM in
                cellVM.cellVMDelegate = self.listApi
            }
        }
    }

    /// 如果用户的表单填写不合法，则前置拦截
    func checkBeforeSubmit() -> Bool {
        var canSubmit: Bool = true
        var firstErrorIndexPath: IndexPath?
        var needReloads = [IndexPath]()
        dataSource.sections.map { $0.cellVMs }.forEach {
            $0.forEach { cellVM in
                let cellCanSubmit = cellVM.checkBeforeSubmit()
                if !cellCanSubmit, let indexPath = self.getIndexPath(cellVM: cellVM) {
                    needReloads.append(indexPath)
                    if firstErrorIndexPath == nil {
                        firstErrorIndexPath = indexPath
                    }
                    canSubmit = false
                }
            }
        }
        /// 跳转到第一个报错的cell
        if let indexPath = firstErrorIndexPath {
            listApi?.scrollToCellAtTop(indexPath: indexPath) { [weak self] in
                self?.listApi?._tableView.reloadRows(at: needReloads, with: .automatic)
            }
        }
        return canSubmit
    }

    var modelsPB: ServerPB_Office_ai_GetAgentModelResponse?
    var oldScene: ServerPB_Office_ai_MyAIScene?
    private let chat: Chat

    public init(userResolver: UserResolver, chat: Chat) {
        self.userResolver = userResolver
        self.editMode = false
        self.state = .loading
        self.chat = chat
        self.listApi?.updateState()

        self.sceneAPI?.getAgentModels().subscribe(onNext: { [weak self] res in
            guard let self = self else { return }
            self.state = .success
            self.modelsPB = res
            self.listApi?.updateState()
        }, onError: { [weak self] _ in
            guard let self = self else { return }
            self.state = .failed
            self.listApi?.updateState()
        }).disposed(by: disposeBag)
    }

    public init(userResolver: UserResolver, chat: Chat, sceneId: Int64) {
        self.sceneId = sceneId
        self.userResolver = userResolver
        self.editMode = true
        self.state = .loading
        self.chat = chat
        self.listApi?.updateState()

        guard let sceneAPI = self.sceneAPI else { return }
        let modelOb = sceneAPI.getAgentModels()
        let sceneOb = sceneAPI.getSceneDetail(sceneId: sceneId)

        Observable
            .combineLatest(modelOb, sceneOb)
            .subscribe(onNext: { [weak self] modelsPB, scenePB in
                guard let self = self else { return }
                self.state = .success
                self.modelsPB = modelsPB
                self.oldScene = scenePB.scene
                self.dataSourceTransformBy(pb: scenePB)
                self.listApi?.updateState()
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                self.state = .failed
                self.listApi?.updateState()
            })
            .disposed(by: disposeBag)
    }

    func openSelectModelView(from: NavigatorFrom) {
        guard let modelsPB = modelsPB else { return }
        let locale = LanguageManager.currentLanguage.localeIdentifier
        let customModels: [AgentModel] = modelsPB.customModels.compactMap { pb -> AgentModel? in
            let name = pb.i18NName.text[locale] ?? pb.i18NName.default
            return AgentModel(name: name, id: pb.id)
        }
        let systemModels: [AgentModel] = modelsPB.systemModels.compactMap { pb -> AgentModel? in
            let name = pb.i18NName.text[locale] ?? pb.i18NName.default
            return AgentModel(name: name, id: pb.id)
        }
        let cellVMs = dataSource.sections.compactMap { section in
            return section.cellVMs.first(where: { cellVM in
                cellVM.paramType == .sceneModel
            })
        }
        guard !cellVMs.isEmpty, let cellVM = cellVMs[0] as? SceneDetailSelectorCellViewModel else { return }
        var agentModelSection: [AgentModelSection] = [.init(name: nil, models: systemModels)]
        /// 若存在企业自定义模型，则加一个section
        if !customModels.isEmpty {
            agentModelSection.append(.init(name: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_OrgModel_Option, models: customModels))
        }
        let vc = ModelSelectViewController(agentModelSection, selectedModel: cellVM.model) { [weak cellVM, weak self] model in
            cellVM?.model = model
            if let cellVM = cellVM {
                self?.listApi?.reloadCell(cellVM: cellVM)
            }
        }
        self.userResolver.navigator.present(vc, from: from)
    }

    func uploadImage(_ image: UIImage, imageKeySubject: BehaviorSubject<String>) {
        guard let imageApi = try? self.userResolver.resolve(assert: ImageAPI.self) else {
            imageKeySubject.onNext("")
            return
        }
        /// 图片压缩到240*240(pixel）
        Observable<ImageProcessResult?>.create { observer -> Disposable in
            let sendImageProcessor = SendImageProcessorImpl()
            observer.onNext(sendImageProcessor.process(source: .image(image), options: .needConvertToWebp, destPixel: 240, compressRate: 0.7, scene: .Chat))
            observer.onCompleted()
            return Disposables.create()
        /// 上传图片
        }.subscribe(onNext: { result in
            if let data = result?.imageData {
                imageApi.uploadSecureImage(data: data, type: .normal, imageCompressedSizeKb: 0)
                    .subscribe(onNext: { key in
                        imageKeySubject.onNext(key)
                    }, onError: { error in
                        imageKeySubject.onError(error)
                    }, onCompleted: {
                        imageKeySubject.onCompleted()
                    })
            }
        }).disposed(by: disposeBag)
    }

    func sendRequest(from: UIViewController) {
        guard checkBeforeSubmit() else {
            if self.editMode {
                IMTracker.Scene.Click.editScene(self.chat, params: ["click_status": "false"])
            } else {
                IMTracker.Scene.Click.newScene(self.chat, params: ["click_status": "false"])
            }
            return
        }

        let imageKeySubject: BehaviorSubject<String> = .init(value: "")
        /// 开始展示转圈圈的HUD
        let loadingHUD = UDToast.showDefaultLoading(on: from.view, disableUserInteraction: true)
        var param = SceneDetailParams()
        for cellVM in dataSource.sections.map({ $0.cellVMs }).flatMap({ $0 }) {
            switch cellVM.paramType {
            case .sceneIcon:
                if let cellVM = cellVM as? SceneDetailIconCellViewModel {
                    switch cellVM.image {
                    case .uiimage(let uiimage):
                        /// 如果没有key，需要先上传图片
                        uploadImage(uiimage, imageKeySubject: imageKeySubject)
                    case .passThrough(let passThrough):
                        imageKeySubject.onNext(passThrough.key ?? "")
                    }
                }
            case .sceneTitle:
                if let cellVM = cellVM as? SceneDetailTextFieldCellViewModel {
                    param.sceneName = cellVM.trimmedinputText
                }
            case .sceneSetting:
                if let cellVM = cellVM as? SceneDetailInputCellViewModel {
                    param.systemInstruction = cellVM.trimmedinputText
                }
            case .sceneModel:
                if let cellVM = cellVM as? SceneDetailSelectorCellViewModel {
                    param.aiModel = cellVM.model?.id ?? ""
                }
            case .openingStatement:
                if let cellVM = cellVM as? SceneDetailInputCellViewModel {
                    param.prologue = cellVM.trimmedinputText
                }
            case .leadingQuestion:
                if let cellVM = cellVM as? SceneDetailTextFieldCellViewModel {
                    param.guideQuestions.append(cellVM.trimmedinputText)
                }
            default:
                break
            }
        }

        imageKeySubject.filter { !$0.isEmpty }.subscribe(onNext: { [weak self, weak from] key in
            guard let self = self, let sceneAPI = self.sceneAPI, let from = from else { return }
            param.imageKey = key
            if self.editMode {
                self.sendPutRequest(param: param, sceneAPI: sceneAPI, from: from)
            } else {
                self.sendCreateRequest(param: param, sceneAPI: sceneAPI, from: from)
            }
        }, onError: { [weak loadingHUD, weak from, weak self] error in
            guard let self = self else { return }
            if self.editMode {
                IMTracker.Scene.Click.editScene(self.chat, params: ["click_status": "false"])
            } else {
                IMTracker.Scene.Click.newScene(self.chat, params: ["click_status": "false"])
            }
            loadingHUD?.remove()
            if let view = from?.view {
                UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_EditUnsaved_Toast, on: view, error: error)
            }
        }, onCompleted: { [weak loadingHUD] in
            loadingHUD?.remove()
        }).disposed(by: disposeBag)
    }

    func sendPutRequest(param: SceneDetailParams, sceneAPI: SceneAPI, from vc: UIViewController) {
        let isOfficial = (oldScene?.isOfficial) ?? true
        let ob = sceneAPI.putScene(sceneID: sceneId ?? 0,
                                   sceneName: param.sceneName,
                                   imageKey: param.imageKey,
                                   prologue: param.prologue,
                                   description_p: isOfficial ? "" : param.prologue,
                                   guideQuestions: param.guideQuestions,
                                   systemInstruction: param.systemInstruction,
                                   aiModel: param.aiModel)
        ob.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak vc] res in
            guard let view = vc?.view, let `self` = self else { return }
            IMTracker.Scene.Click.editScene(self.chat, params: ["click_status": "success"])
            (try? self.userResolver.resolve(assert: MyAISceneService.self))?.editSceneSubject.onNext(res.scene)
            /// 编辑成功
            UDToast.showSuccess(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_EditSaved_Toast, on: view)
            self.listApi?.dismiss()
        }, onError: { [weak vc, weak self] error in
            guard let view = vc?.view, let `self` = self else { return }
            IMTracker.Scene.Click.editScene(self.chat, params: ["click_status": "false"])
            /// 编辑失败
            UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_EditUnsaved_Toast, on: view, error: error)
        }).disposed(by: disposeBag)
    }

    func sendCreateRequest(param: SceneDetailParams, sceneAPI: SceneAPI, from vc: UIViewController) {
        let ob = sceneAPI.createScene(sceneName: param.sceneName,
                                      imageKey: param.imageKey,
                                      prologue: param.prologue,
                                      guideQuestions: param.guideQuestions,
                                      systemInstruction: param.systemInstruction,
                                      aiModel: param.aiModel)
        ob.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak vc] res in
            guard let view = vc?.view, let `self` = self else { return }
            IMTracker.Scene.Click.newScene(self.chat, params: ["click_status": "success"])
            // "创建成功"
            (try? self.userResolver.resolve(assert: MyAISceneService.self))?.createSceneSubject.onNext(res.scene)
            UDToast.showSuccess(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_EditSaved_Toast, on: view)
            self.listApi?.dismiss()
        }, onError: { [weak vc, weak self] error in
            guard let view = vc?.view, let `self` = self else { return }
            IMTracker.Scene.Click.newScene(self.chat, params: ["click_status": "false"])
            // "创建失败"
            UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_EditUnsaved_Toast, on: view, error: error)
        }).disposed(by: disposeBag)
    }

    func removeCellVM(cellVM: SceneDetailCellViewModel) -> IndexPath? {
        let index = self.getIndexPath(cellVM: cellVM)
        guard let section = index?.section,
              let row = index?.row, section < dataSource.sections.count,
              row < dataSource.sections[section].cellVMs.count else { return nil }
        dataSource.sections[section].cellVMs.remove(at: row)
        return IndexPath(row: row, section: section)
    }

    func getIndexPath(cellVM: any SceneDetailCellViewModel) -> IndexPath? {
        for (section, array) in dataSource.sections.map({ $0.cellVMs }).enumerated() {
            for (row, value) in array.enumerated() {
                if cellVM === value {
                    return IndexPath(row: row, section: section)
                }
            }
        }
        return nil
    }

    func addTextCellToPre(sourceVM: SceneDetailAddTextCellViewModel) {
        guard let sourceSection = self.getIndexPath(cellVM: sourceVM)?.section else { return }
        let section = sourceSection - 1
        guard section >= 0, section <= self.dataSource.sections.count else { return }
        let limit = 20
        /// 引导问题存在数量限制
        if self.dataSource.sections[section].cellVMs.count >= limit {
            if let view = self.listApi?.view {
                UDToast.showFailure(with: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_ExamplePromptsExceedLimit_Toast(limit), on: view)
            }
            return
        }
        let cellVM = SceneDetailTextFieldCellViewModel(paramType: .leadingQuestion,
                                                       placeHolder: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_ExamplePrompts_Placeholder,
                                                       limit: 240,
                                                       inputText: nil,
                                                       canRemove: true)
        /// 更新数据源
        self.dataSource.sections[section].cellVMs.append(cellVM)
        let indexPath = IndexPath(row: self.dataSource.sections[section].cellVMs.count - 1, section: section)
        // 插入新行
        if let tableView = self.listApi?._tableView {
            tableView.beginUpdates()
            tableView.insertRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
        self.resetDelegate()
    }
}

extension SceneDetailViewModel {
    /// 从setting中生成默认头像的ImagePassThrough
    func getDefaultPassthrough() -> ImagePassThrough {
        guard let config = try? self.userResolver.settings.setting(with: SceneDetailDefaultIconSetting.self) else {
            return ImagePassThrough()
        }
        return config.passThrough
    }

    /// SceneDetailViewModel初始化时初始化DataSource的方法
    func initDataSource(imagePassThrough: ImagePassThrough? = nil,
                        sceneTitle: String? = nil,
                        sceneSetting: String? = nil,
                        openingStatement: String? = nil,
                        leadingQuestion: [String] = [],
                        sceneModel: AgentModel? = nil
    ) -> SceneDetailDataSource {
        let passThrough: ImagePassThrough = imagePassThrough ?? getDefaultPassthrough()

        return SceneDetailDataSource(sections: [
            .init(title: nil, isRequired: true, cellVMs: [
                SceneDetailIconCellViewModel(paramType: .sceneIcon,
                                             image: .passThrough(passThrough))
            ]),
            // 场景话题名称
            .init(title: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Name_Title, isRequired: true, cellVMs: [
                SceneDetailTextFieldCellViewModel(paramType: .sceneTitle,
                                                  placeHolder: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Name_Placeholder,
                                                  limit: 30,
                                                  inputText: sceneTitle)
            ]),
            // 场景设定
            .init(title: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Prompts_Title, isRequired: true, cellVMs: [
                SceneDetailInputCellViewModel(paramType: .sceneSetting,
                                              placeHolder: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Settings_Placeholder,
                                              inputText: sceneSetting,
                                              limit: 1000,
                                              rowHeight: 300)
            ]),
            // 开场白
            .init(title: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Introductions_Title, isRequired: true, cellVMs: [
                SceneDetailInputCellViewModel(paramType: .openingStatement,
                                              placeHolder: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_Introductions_Placeholder,
                                              inputText: openingStatement,
                                              limit: 240)
            ]),
            // 引导问题
            .init(title: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_ExamplePrompts_Title, isRequired: false, cellVMs: leadingQuestion.map {
                return SceneDetailTextFieldCellViewModel(paramType: .leadingQuestion,
                                                         placeHolder: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_ExamplePrompts_Placeholder,
                                                         limit: 240,
                                                         inputText: $0,
                                                         canRemove: true)
            }),
            .init(title: nil, isRequired: false, cellVMs: [
                SceneDetailAddTextCellViewModel(paramType: .addLeadingQuestion,
                                                title: BundleI18n.LarkAI.MyAI_Scenario_NewScenario_ExamplePromptsAdd_Button) { [weak self] cellVM in
                                                    self?.addTextCellToPre(sourceVM: cellVM)
                }
            ]),
            // 模型和插件
            .init(title: BundleI18n.LarkAI.MyAI_Scenario_ModelAndExtension_Mobile_Title, isRequired: true, cellVMs: [
                SceneDetailSelectorCellViewModel(paramType: .sceneModel,
                                                 title: BundleI18n.LarkAI.MyAI_Scenario_SelectModel_Mobile_Title,
                                                 model: sceneModel) { [weak self] from in
                                                     self?.openSelectModelView(from: from)
                }
            ])
            // 发布和分享
            // AI需求变动大，MVP先取消这个Cell。下期使用 >_<
            //.init(title: "发布和分享", isRequired: false, cellVMs: [
            //    SceneDetailSwitchCellViewModel(paramType: .publish,
            //                                   title: "允许通过链接分享场景",
            //                                   subTitle: "开启后，你可以通过链接分享这个场景，同时拥有这个链接的人也可以继续分享给其他人。",
            //                                   isSelected: true)
            //])
        ])
    }

    /// 从现有的Scene初始化datasource
    func dataSourceTransformBy(pb: ServerPB_Office_ai_GetSceneDetailResponse) {
        let models = (modelsPB?.customModels ?? []) + (modelsPB?.systemModels ?? [])
        let locale = LanguageManager.currentLanguage.localeIdentifier
        guard let modelPb = models.first(where: { $0.id == pb.aiModelID }) else { return }
        let name = modelPb.i18NName.text[locale] ?? modelPb.i18NName.default
        let model = AgentModel(name: name, id: modelPb.id)
        self.dataSource = initDataSource(imagePassThrough: ImagePassThrough.transform(passthrough: pb.scene.scenePhoto),
                                         sceneTitle: pb.scene.sceneName,
                                         sceneSetting: pb.systemInstruction,
                                         openingStatement: pb.scene.greeting,
                                         leadingQuestion: pb.scene.guideQuestions.map { $0.text },
                                         sceneModel: model)
        resetDelegate()
    }
}

/// 默认头像的setting，方便后期调整
struct SceneDetailDefaultIconSetting: SettingDecodable {
    static let settingKey: UserSettingKey = .make(userKeyLiteral: "myai_scene_default_avatar")

    var fsUnit: String
    var key: String
    var width: Double
    var height: Double
    var crypto: Crypto

    struct Crypto: Decodable {
        var type: Int
        var cipher: Cipher
    }

    struct Cipher: Decodable {
        var secret: String
        var nonce: String
    }

    var passThrough: ImagePassThrough {
        var imagePassThrough = ImagePassThrough()
        var cipher = ImagePassThrough.SerCrypto.Cipher()
        cipher.nonce = Data(base64Encoded: self.crypto.cipher.nonce)
        cipher.secret = Data(base64Encoded: self.crypto.cipher.secret)
        var crypto = ImagePassThrough.SerCrypto()
        crypto.type = ImagePassThrough.SerCrypto.TypeEnum(rawValue: self.crypto.type)
        crypto.cipher = cipher
        imagePassThrough.crypto = crypto
        imagePassThrough.fsUnit = self.fsUnit
        imagePassThrough.key = self.key
        return imagePassThrough
    }
}
