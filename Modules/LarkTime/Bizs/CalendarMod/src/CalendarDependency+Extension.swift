//
//  CalendarDependency+Extension.swift
//  CalendarMod
//
//  Created by Supeng on 2021/9/16.
//

import UIKit
import Calendar
import LarkModel
import LarkAvatar
import EENavigator
import LarkImageEditor
import RxSwift
import LarkAccountInterface
import CalendarFoundation
#if MessengerMod
import LarkMessengerInterface
#endif
import LarkContainer
#if CCMMod
import SpaceInterface
#endif
import SnapKit

// 实现了部分CalendarDependency中定义的，可以直接依赖平台层实现的接口
class BaseCalendarDependencyImpl {
    let resolver: UserResolver

    let userService: PassportUserService

    init(resolver: UserResolver) throws {
        self.resolver = resolver
        // 为了能拿到不可空的 user 填充 LoginUser，这里单独 resolve 了不可空的 PassportUserService
        self.userService = try resolver.resolve(assert: PassportUserService.self)
    }

    /// 选择+上传图片
    func jumpToSelectAndUploadImage(from: UIViewController,
                                    anchorView: UIView,
                                    uploadSuccess: @escaping (_ key: String, _ image: UIImage) -> Void) {
        let vc = UploadImageViewController(multiple: false,
                                           max: 1,
                                           imageUploader: CalendarImageUploader(userResolver: self.resolver),
                                           userResolver: resolver,
                                           crop: true) { _, keys, imageProvider in
            if let key = keys.first,
               let image = imageProvider.first?() {
                uploadSuccess(key, image)
            }
        }
        vc.sourceView = anchorView
        vc.isNavigationBarHidden = false
        vc.navigationController?.setNavigationBarHidden(false, animated: false)
        from.view.insertSubview(vc.view, at: 0)
    }
}

extension LarkModel.Chatter: CurrentUserInfo {}

extension LarkModel.Chat: CalendarChat {
    public var isMember: Bool {
        return self.role == .member
    }
}

final class CalendarImageUploader: PreviewImageUploader, UserResolverWrapper {

    enum UploadError: Error {
        case noData
        case selfNil
    }

    private lazy var imageUploader = ImageUploader(userResolver: self.userResolver)

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    let imageEditAction: ((ImageEditEvent) -> Void)? = { _ in }

    func upload(_ imageSources: [ImageSourceProvider], isOrigin: Bool) -> Observable<[String]> {
        return Observable<Data>.create { (observer) -> Disposable in
            if let imageData = imageSources
                .first?()
                .flatMap({ $0.pngData() }) {
                observer.onNext(imageData)
                observer.onCompleted()
            } else {
                observer.onError(UploadError.noData)
            }
            return Disposables.create()
        }
        .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
        .flatMap({ [weak self] (data) -> Observable<[String]> in
            guard let self = self else {
                return Observable.error(UploadError.selfNil)
            }
            return self.imageUploader.uploadImage(data: data).map({ (key) -> [String] in
                return [key]
            })
        })
        .observeOn(MainScheduler.instance)
    }
}

struct LoginUser: CurrentUserInfo {
    var isChatter: Bool = true

    var id: String {
        user.userID
    }

    var displayName: String {
        return user.displayName ?? user.name
    }

    var avatarKey: String {
        user.avatarKey
    }

    var tenantId: String {
        user.tenant.tenantID
    }

    var accessToken: String? {
        user.sessionKey ?? ""
    }

    var isCustomer: Bool {
        let tenant = Tenant(currentTenantId:user.tenant.tenantID)
        return tenant.isCustomerTenant()
    }

    var nameWithAnotherName: String {
        return displayName
    }

    private let user: User

    init(user: User) {
        self.user = user
    }
}

class CalendarTemplateHorizontalListView: UIView, CalendarTemplateHorizontalListViewProtocol {
    weak var delegate: CalendarTemplateHorizontalListViewDelegate?

    #if CCMMod
    var templateView: TemplateHorizontalListViewProtocol? {
        didSet {
            guard let view = templateView else { return }
            self.addSubview(view)
            view.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        }
    }
    #endif

    /// 开始加载模板
    func start() {
        #if CCMMod
        templateView?.start()
        #endif
    }
}
#if CCMMod
extension CalendarTemplateHorizontalListView: TemplateHorizontalListViewDelegate {

    func templateHorizontalListView(_ listView: SpaceInterface.TemplateHorizontalListViewProtocol, onFailedStatus: Bool) {
        delegate?.templateHorizontalListView(self, onFailedStatus: onFailedStatus)
    }

    /// 点击模板回调
    func templateHorizontalListView(_ listView: TemplateHorizontalListViewProtocol, didClick templateId: String) -> Bool {
        return delegate?.templateHorizontalListView(self, didClick: templateId) ?? false
    }

    /// 创建文档回调
    func templateHorizontalListView(_ listView: TemplateHorizontalListViewProtocol, onCreateDoc result: DocsTemplateCreateResult?, error: Error?) {
        let createCalendarDocsTemplateCreateResult: () -> CalendarDocsTemplateCreateResult? = {
            guard let result = result else { return nil }
            return CalendarDocsTemplateCreateResult(url: result.url, title: result.title)
        }
        delegate?.templateHorizontalListView(self, onCreateDoc: createCalendarDocsTemplateCreateResult(), error: error)
    }

    func templatePageWillClose(_ type: SpaceInterface.TemplatePageType) {
    }

    func templateOnItemSelected(_ viewController: UIViewController, item: SpaceInterface.TemplateItem) {
        let templateItem = CalendarTemplateItem(id: item.id,
                                                name: item.name,
                                                objToken: item.objToken,
                                                objType: DocsType(rawValue: item.objType).pbRawValue)
        delegate?.templateOnItemSelected(viewController, item: templateItem)
    }

    func templateOnCreateDoc(url: String?, token: String?, type: SpaceInterface.DocsType?, error: Error?) {
    }

    func templateOnEvent(onEvent event: SpaceInterface.TemplatePageEvent) {}
}

class CalendarDocComponentAPI: DocComponentAPIDelegate, CalendarDocComponentAPIProtocol {

    weak var delegate: CalendarDocComponentAPIDelegate?

    var docVC: UIViewController {
        docComponentAPI.docVC
    }

    private let docComponentAPI: DocComponentAPI

    init(docComponentAPI: DocComponentAPI) {
        self.docComponentAPI = docComponentAPI
        self.docComponentAPI.setDelegate(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 传递文档的调用
    func docComponent(_ doc: DocComponentAPI, onInvoke data: [String: Any]?, callback: DocComponentInvokeCallBack?) {
        delegate?.onInvoke(data: data, callback: callback)
    }

    /// 传递文档内的事件
    func docComponent(_ doc: DocComponentAPI, onEvent event: DocComponentEvent) {
        switch event {
        case .onNavigationItemClick(let item) where item == "back":
            delegate?.willClose()
        default: break
        }
    }

    /// 传递文档内的操作
    /// 返回值：true: 业务方如需要拦截处理   false: 业务方忽略，由文档处理
    func docComponent(_ doc: DocComponentAPI, onOperation operation: DocComponentOperation) -> Bool {
        false
    }

}

extension TemplateItem {
    var calendarTemplateItem: CalendarTemplateItem {
        CalendarTemplateItem(id: self.id,
                             name: self.name,
                             objToken: self.objToken,
                             objType: DocsType(rawValue: self.objType).pbRawValue)
    }
}

class CalendarTemplate {
    private let api: TemplateAPI
    private var delegateWrapper: DelegateWrapper?

    init(_ api: TemplateAPI) {
        self.api = api
    }

    func createTemplateSelectedVC(fromVC: UIViewController, categoryId: String, delegate: CalendarTemplateHorizontalListViewDelegate) -> UIViewController? {
        let templatePageConfig = TemplatePageConfig(useTemplateType: .template,
                                                    autoDismiss: false,
                                                    isModalInPresentation: true,
                                                    clickTemplateItemType: .select,
                                                    hideItemSubTitle: true)
        
        let createTemplatePageParams = CreateTemplatePageParam(categoryId: categoryId,
                                                               templateSource: "calendar_create",
                                                               templatePageConfig: templatePageConfig,
                                                               dcSceneId: "301")
        delegateWrapper = DelegateWrapper(delegate)
        return api.createTemplateSelectedPage(param: createTemplatePageParams, fromVC: fromVC, delegate: delegateWrapper)
    }

    private class DelegateWrapper: TemplateSelectedDelegate {
        private weak var delegate: CalendarTemplateHorizontalListViewDelegate?
        init(_ delegate: CalendarTemplateHorizontalListViewDelegate) {
            self.delegate = delegate
        }

        func templateOnItemSelected(_ viewController: UIViewController, item: TemplateItem) {
            if let delegate = delegate {
                delegate.templateOnItemSelected(viewController, item: item.calendarTemplateItem)
            }
        }

        func templateOnCreateDoc(url: String?, token: String?, type: DocsType?, error: Error?) {}

        func templateOnEvent(onEvent event: TemplatePageEvent) {}
    }
}

#endif

#if MessengerMod
final class CalendarForwardAlertContentImp: ForwardAlertContent { }

final class CalendarForwrdAlertProvider: ForwardAlertProvider {
    override var shouldCreateGroup: Bool { false }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig()
        ]
        return includeConfigs
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        let includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(),
            ForwardGroupChatEnabledEntityConfig()
        ]
        return includeConfigs
    }
}
#endif
