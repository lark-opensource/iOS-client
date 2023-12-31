//
//  CCMDependencyImpl.swift
//  LarkByteView
//
//  Created by kiri on 2020/9/28.
//

import Foundation
import ByteView
import ByteViewCommon
import SpaceInterface
import LarkContainer
import LarkUIKit
import LarkDocsIcon
import RxSwift
import LarkSetting

final class CCMDependencyImpl: CCMDependency {
    let userResolver: UserResolver
    let docsIconManager: DocsIconManager?
    private lazy var disposeBag: DisposeBag = { DisposeBag() }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.docsIconManager = try? userResolver.resolve(assert: DocsIconManager.self)
    }

    private weak var currentFollowDocumentFactory: CCMFollowDocumentFactory?

    private weak var currentNotesDocumentFactory: NotesDocumentFactory?

    /// FollowAPIFactory是container scope的
    private var followAPIFactory: FollowAPIFactory? {
        do {
            return try userResolver.resolve(assert: FollowAPIFactory.self)
        } catch {
            Logger.dependency.error("resolve FollowAPIFactory failed, \(error)")
            return nil
        }
    }

    func createFollowDocumentFactory() -> FollowDocumentFactory {
        let factory = CCMFollowDocumentFactory(followAPIFactory)
        currentFollowDocumentFactory = factory
        return factory
    }

    private var notesDocumentFactory: DocComponentSDK? {
        try? userResolver.resolve(assert: DocComponentSDK.self)
    }

    func createNotesDocumentFactory() -> NotesDocumentFactory {
        let factory = CCMNotesDocumentFactory(notesDocumentFactory)
        currentNotesDocumentFactory = factory
        return factory
    }

    private var templateAPI: TemplateAPI? {
        try? userResolver.resolve(assert: TemplateAPI.self)
    }

    func createBVTemplate() -> BVTemplate? {
        if let api = templateAPI {
            return CCMTemplate(api)
        }
        return nil
    }

    func isDocsURL(_ urlString: String) -> Bool {
        guard let factory = currentFollowDocumentFactory?.factory ?? followAPIFactory else {
            return false
        }
        return type(of: factory).isDocsURL(urlString)
    }

    func downloadThumbnail(url: String, thumbnailInfo: [String: Any], imageSize: CGSize?,
                           completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let factory = currentFollowDocumentFactory?.factory ?? followAPIFactory else {
            completion(.failure(CCMError.apiNotFound))
            return
        }
        _ = type(of: factory).getThumbnail(url: url, thumbnailInfo: thumbnailInfo, imageSize: imageSize).subscribe {
            switch $0 {
            case .next(let image):
                completion(.success(image))
            case .error(let error):
                completion(.failure(error))
            default:
                break
            }
        }
    }

    func createLkNavigationController() -> UINavigationController {
        return LkNavigationController()
    }

    func setDocsIcon(iconInfo: String, url: String, completion: ((UIImage) -> Void)?) {
        if let docsIconManager = self.docsIconManager {
            docsIconManager.getDocsIconImageAsync(iconInfo: iconInfo, url: url, shape: .SQUARE).subscribe { image in
                completion?(image)
            }.disposed(by: disposeBag)
        }
    }

    func getDocsAPIDomain() -> String {
        guard let domain = DomainSettingManager.shared.currentSetting[.docsApi]?.first else {
            Logger.dependency.error("getDocsAPIDomain failed, return empty string")
            return ""
        }
        return domain
    }
}

// MARK: - Magic Share

private enum CCMError: Error {
    case apiNotFound
}

private class CCMFollowDocumentFactory: FollowDocumentFactory {
    let factory: FollowAPIFactory?
    init(_ factory: FollowAPIFactory?) {
        self.factory = factory
    }

    func startMeeting() {
        factory?.startMeeting()
    }

    func stopMeeting() {
        factory?.stopMeeting()
    }

    func open(url: String) -> FollowDocument? {
        if let api = factory?.open(url: url, events: supportedFollowEvent) {
            return CCMFollowDocument(api)
        }
        return nil
    }

    func openGoogleDrive(url: String, injectScript: String?) -> FollowDocument? {
        if let api = factory?.openGoogleDrive(url: url, events: supportedFollowEvent, injectScript: injectScript) {
            return CCMFollowDocument(api)
        }
        return nil
    }

    /// 支持的回调事件，创建followAPI时注入
    var supportedFollowEvent: [SpaceInterface.FollowEvent] {
        return [
            .newAction,
            .newPatches,
            .presenterFollowerLocation,
            .relativePositionChange,
            .track,
            .firstPositionChangeAfterFollow,
            .magicShareInfo
        ]
    }
}

private class CCMFollowDocument: FollowDocument {
    private let api: FollowAPI
    private var delegateWrapper: DelegateWrapper?
    init(_ api: FollowAPI) {
        self.api = api
    }

    var followUrl: String {
        api.followUrl
    }

    var followTitle: String {
        api.followTitle
    }

    var followVC: UIViewController {
        api.followVC
    }

    var canBackToLastPosition: Bool {
        api.canBackToLastPosition
    }

    var isEditing: Bool {
        api.isEditingStatus
    }

    var scrollView: UIScrollView? {
        api.scrollView
    }

    func setDelegate(_ delegate: FollowDocumentDelegate) {
        let wrapper = DelegateWrapper(self, delegate)
        delegateWrapper = wrapper
        api.setDelegate(wrapper)
    }

    func startRecord() {
        api.startRecord()
    }

    func stopRecord() {
        api.stopRecord()
    }

    func startFollow() {
        api.startFollow()
    }

    func stopFollow() {
        api.stopFollow()
    }

    func setState(states: [String], meta: String?) {
        api.setState(states: states.map({ DefaultFollowState($0) }), meta: meta)
    }

    func getState(callBack: @escaping ([String], String?) -> Void) {
        api.getState {
            callBack($0.map({ $0.toJSONString() }), $1)
        }
    }

    func reload() {
        api.reload()
    }

    func injectJS(_ script: String) {
        api.injectJS(script)
    }

    func backToLastPosition() {
        api.callFollowAPI(type: .backToLastPosition)
    }

    func clearLastPosition(_ token: String?) {
        api.callFollowAPI(type: .clearLastPosition(token))
    }

    func keepCurrentPosition() {
        api.callFollowAPI(type: .keepCurrentPosition)
    }

    func updateOptions(_ options: String?) {
        api.callFollowAPI(type: .updateOptions(options))
    }

    func willSetFloatingWindow() {
        api.willSetFloatingWindow()
    }

    func finishFullScreenWindow() {
        api.finishFullScreenWindow()
    }

    func updateContext(_ context: String?) {
        api.callFollowAPI(type: .updateContext(context))
    }

    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?) {
        api.invoke(funcName: funcName,
                   paramJson: paramJson,
                   metaJson: metaJson,
                   callBack: nil)
    }

    private class DelegateWrapper: FollowAPIDelegate {
        private weak var document: FollowDocument?
        private weak var delegate: FollowDocumentDelegate?
        init(_ document: FollowDocument, _ delegate: FollowDocumentDelegate) {
            self.document = document
            self.delegate = delegate
        }

        func follow(_ follow: FollowAPI, on event: SpaceInterface.FollowEvent, with states: [FollowState], metaJson: String?) {
            if let doc = document, let delegate = delegate {
                delegate.follow(doc, on: event.vcEvent, with: states.map { $0.toJSONString() }, metaJson: metaJson)
            }
        }

        func follow(_ follow: FollowAPI, onOperate operation: SpaceInterface.FollowOperation) {
            if let doc = document, let delegate = delegate {
                delegate.follow(doc, onOperate: operation.vcOperation)
            }
        }

        func follow(_ follow: FollowAPI, onJsInvoke invocation: [String: Any]?) {
            if let doc = document, let delegate = delegate {
                delegate.follow(doc, onJsInvoke: invocation)
            }
        }

        func followDidReady(_ follow: FollowAPI) {
            if let doc = document, let delegate = delegate {
                delegate.followDidReady(doc)
            }
        }

        func followDidRenderFinish(_ follow: FollowAPI) {
            if let doc = document, let delegate = delegate {
                delegate.followDidRenderFinish(doc)
            }
        }

        func followWillBack(_ follow: FollowAPI) {
            if let doc = document, let delegate = delegate {
                delegate.followWillBack(doc)
            }
        }
    }
}

private extension SpaceInterface.FollowEvent {
    var vcEvent: ByteView.FollowEvent {
        switch self {
        case .newAction:
            return .newAction
        case .newPatches:
            return .newPatches
        case .titleChange:
            return .titleChange
        case .followLog:
            return .followLog
        case .positionChange:
            return .positionChange
        case .touchPositionChange:
            return .touchPositionChange
        case .presenterFollowerLocation:
            return .presenterFollowerLocation
        case .versionLag:
            return .versionLag
        case .track:
            return .track
        case .lifeCycleChange:
            return .lifeCycleChange
        case .actionChangeList:
            return .actionChangeList
        case .firstPositionChangeAfterFollow:
            return .firstPositionChangeAfterFollow
        case .relativePositionChange:
            return .relativePositionChange
        case .magicShareInfo:
            return .magicShareInfo
        default:
            return .unknown
        }
    }
}

private extension SpaceInterface.FollowOperation {
    var vcOperation: ByteView.FollowOperation {
        switch self {
        case let .openUrl(url):
            return .openUrl(url: url)
        case let .openMoveToWikiUrl(wikiUrl, originUrl):
            return .openMoveToWikiUrl(wikiUrl: wikiUrl, originUrl: originUrl)
        case let .openUrlWithHandlerBeforeOpen(url: url, handler: handler):
            return .openUrlWithHandlerBeforeOpen(url: url, handler: handler)
        case let .openPic(url):
            return .openPic(url: url)
        case let .selectComments(info):
            return .selectComments(info: info)
        case let .rotateScreen(orientation):
            return .rotateScreen(orientation: orientation)
        case let .onTitleChange(title):
            return .onTitleChange(title: title)
        case let .showUserProfile(userId):
            return .showUserProfile(userId: userId)
        case let .setFloatingWindow(getFromVCHandler: handler):
            return .setFloatingWindow(getFromVCHandler: handler)
        case let .openOrCloseAttachFile(isOpen: isOpen):
            return .openOrCloseAttachFile(isOpen: isOpen)
        default:
            return .unknown
        }
    }
}

private class DefaultFollowState: FollowState {
    let payload: String
    init(_ payload: String) {
        self.payload = payload
    }

    func toJSONString() -> String {
        payload
    }
}

// MARK: - Notes

private class CCMNotesDocumentFactory: NotesDocumentFactory {

    let factory: DocComponentSDK?

    init(_ factory: DocComponentSDK?) {
        self.factory = factory
    }

    func create(url: URL, config: NotesAPIConfig) -> NotesDocument? {
        let ccmConfig = DocComponentConfig(module: config.module, sceneID: config.sceneID, pageConfig: DocComponentPageConfig(showCloseButton: true))
        if let api = factory?.create(url: url, config: ccmConfig) {
            return CCMNotesDocument(api)
        }
        return nil
    }

}

private class CCMNotesDocument: NotesDocument {
    private let api: DocComponentAPI
    private var delegateWrapper: DelegateWrapper?
    init(_ api: DocComponentAPI) {
        self.api = api
    }

    /// 文档组件的ViewController
    var docVC: UIViewController {
        api.docVC
    }

    /// 文档组件状态
    var status: NotesDocumentStatus {
        api.status.vcStatus
    }

    /// 设置纪要文档回调Delgate
    func setDelegate(_ delegate: NotesDocumentDelegate) {
        let wrapper = DelegateWrapper(self, delegate)
        delegateWrapper = wrapper
        api.setDelegate(wrapper)
    }

    func updateSettingConfig(_ settingConfig: [String: Any]) {
        api.updateSettingConfig(settingConfig)
    }

    /// 通用调用方法
    /// - Parameters:
    ///   - command: 调用命令
    ///   - payload: 参数
    ///   - callback: 回调（暂未实现）
    func invoke(command: String, payload: [String: Any]?, callback: NotesInvokeCallBack?) {
        api.invoke(command: command, payload: payload, callback: callback)
    }

    private class DelegateWrapper: DocComponentAPIDelegate {

        private weak var document: NotesDocument?

        private weak var delegate: NotesDocumentDelegate?

        init(_ document: NotesDocument, _ delegate: NotesDocumentDelegate) {
            self.document = document
            self.delegate = delegate
        }

        func docComponent(_ doc: DocComponentAPI, onInvoke data: [String: Any]?, callback: DocComponentInvokeCallBack?) {
            if let document = document, let delegate = delegate {
                let returnCallback: (([String: Any], Error?) -> Void)? = { (callbackData, error) in
                    callback?(callbackData, error)
                }
                delegate.docComponent(document, onInvoke: data, callback: returnCallback)
            }
        }

        func docComponent(_ doc: SpaceInterface.DocComponentAPI, onEvent event: SpaceInterface.DocComponentEvent) {
            if let document = document, let delegate = delegate {
                delegate.docComponent(document, onEvent: event.vcEvent)
            }
        }

        func docComponent(_ doc: SpaceInterface.DocComponentAPI, onOperation operation: SpaceInterface.DocComponentOperation) -> Bool {
            if let document = document, let delegate = delegate {
                return delegate.docComponent(document, onOperation: operation.vcOperation)
            }
            return false
        }
    }
}

private extension SpaceInterface.DocComponentEvent {

    var vcEvent: NotesDocumentEvent {
        switch self {
        case .statusChange(status: let status):
            return .statusChange(status: status.vcStatus)
        case .onTitleChange(title: let title):
            return .onTitleChange(title: title)
        case .willClose:
            return .willClose
        case .onNavigationItemClick(item: let item):
            return .onNavigationItemClick(item: item)
        }
    }
}

private extension SpaceInterface.DocComponentOperation {

    var vcOperation: NotesDocumentOperation {
        switch self {
        case .openUrl(url: let url):
            return .openUrl(url: url)
        case .openUrlWithHandlerBeforeOpen(url: let url, handler: let handler):
            return .openUrlWithHandlerBeforeOpen(url: url, handler: handler)
        case .openPic(url: let url):
            return .openPic(url: url)
        case .showUserProfile(userId: let userId):
            return .showUserProfile(userId: userId)
        }
    }
}

private extension DocComponentStatus {

    var vcStatus: NotesDocumentStatus {
        switch self {
        case .start:
            return .start
        case .loading:
            return .loading
        case .success:
            return .success
        case .fail(error: let error):
            return .fail(error: error)
        }
    }
}

// MARK: - Notes Template

extension TemplatePageType {

    var vcType: BVTemplatePageType {
        switch self {
        case .select: return .select
        case .preview: return .preview
        }
    }
}

extension TemplateItem {

    var vcItem: BVTemplateItem {
        return BVTemplateItem(id: id,
                              name: name,
                              objToken: objToken,
                              objType: objType)
    }
}

extension TemplatePageEvent {

    var vcEvent: BVTemplatePageEvent {
        switch self {
        case .willClose(type: let type):
            return .willClose(type: type.vcType)
        case .onNavigationItemClick(item: let item):
            return.onNavigationItemClick(item: item)
        }
    }
}

extension DocsType {

    var vcType: BVDocsType {
        switch self {
        case .folder: return .folder
        case .trash: return .trash
        case .doc: return .doc
        case .sheet: return .sheet
        case .myFolder: return .myFolder
        case .bitable, .baseAdd: return .bitable
        case .mindnote: return .mindnote
        case .file: return .file
        case .slides: return .slides
        case .wiki: return .wiki
        case .mediaFile: return .mediaFile
        case .imMsgFile: return .imMsgFile
        case .docX: return .docX
        case .wikiCatalog: return .wikiCatalog
        case .minutes: return .minutes
        case .whiteboard: return .whiteboard
        case .sync: return .sync
        case .unknown(let value): return .unknown(value)
        }
    }
}

private class CCMTemplate: BVTemplate {
    private let api: TemplateAPI
    private var delegateWrapper: DelegateWrapper?

    init(_ api: TemplateAPI) {
        self.api = api
    }

    func createTemplateViewController(with delegate: BVTemplateSelectedDelegate, categoryId: String, fromVC: UIViewController) -> UIViewController? {
        let templatePageConfig = TemplatePageConfig(useTemplateType: UseTemplateType.template,
                                                    autoDismiss: false,
                                                    enableShare: false,
                                                    showCloseButton: true,
                                                    clickTemplateItemType: .select)
        let createTemplatePageParams = CreateTemplatePageParam(categoryId: categoryId,
                                                               templateSource: "vc_detail",
                                                               templatePageConfig: templatePageConfig,
                                                               dcSceneId: "101")
        let wrapper = DelegateWrapper(self, delegate)
        delegateWrapper = wrapper
        return api.createTemplateSelectedPage(param: createTemplatePageParams, fromVC: fromVC, delegate: delegateWrapper)
    }

    private class DelegateWrapper: TemplateSelectedDelegate {
        private weak var template: BVTemplate?
        private weak var delegate: BVTemplateSelectedDelegate?
        init(_ template: BVTemplate, _ delegate: BVTemplateSelectedDelegate) {
            self.template = template
            self.delegate = delegate
        }

        func templateOnItemSelected(_ viewController: UIViewController, item: TemplateItem) {
            if let template = template, let delegate = delegate {
                delegate.templateOnItemSelected(viewController, item: item.vcItem)
            }
        }

        func templateOnCreateDoc(url: String?, token: String?, type: DocsType?, error: Error?) {} // VC未使用无需实现

        func templateOnEvent(onEvent event: TemplatePageEvent) {
            if let template = template, let delegate = delegate {
                delegate.templateOnEvent(onEvent: event.vcEvent)
            }
        }
    }

}
