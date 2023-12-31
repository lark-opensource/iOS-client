//
//  PrivacySettingViewModel.swift
//  SKCommon
//
//  Created by peilongfei on 2023/12/11.
//  


import SKFoundation
import SKResource
import SwiftyJSON
import RxSwift
import RxCocoa
import RxRelay
import LarkAppConfig
import SKInfra
import LarkContainer

class PrivacySettingViewModel {

    enum UIAction {
        case reloadTableView
        case showLoading(Bool, Bool)
        case showEmpty(Bool)
        case showToast(ToastType)
    }

    enum ToastType {
        case success(String)
        case error(String)
    }

    private static let readRecordSettingKey = "allow_read_list_setting"
    private static let showAvatarSettingKey = "allow_show_collaboration_avatar"

    let docsInfo: DocsInfo
    let uiAction = PublishRelay<UIAction>()
    let cache: CCMKeyValueStorage
    var models: [SwitchSettingModel] = []
    private let api: PrivacySettingAPIType
    private let disposeBag = DisposeBag()

    init(docsInfo: DocsInfo,
         api: PrivacySettingAPIType = PrivacySettingAPI(),
         userResolver: UserResolver = Container.shared.getCurrentUserResolver()) {
        self.docsInfo = docsInfo
        self.api = api                                                                                                                     
        let userId = userResolver.userID
        self.cache = CCMKeyValue.userDefault(userId)
    }
}

extension PrivacySettingViewModel {

    func fetchData() {
        fetchDataFormCache()
        fetchDataFormNetwork()
    }

    func fetchDataFormCache() {
        if let readRecordIsOn: Bool = cache.value(forKey: Self.readRecordSettingKey) {
            let model = SwitchSettingModel(title: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ViewHistory_Title,
                                           detail: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ViewHistory_Descrip,
                                           property: Self.readRecordSettingKey,
                                           order: 1,
                                           openEvent: .readRecordOpen,
                                           closeEvent: .readRecordClose,
                                           isOn: readRecordIsOn)
            models.append(model)
        }
        if let showAvatarIsOn: Bool = cache.value(forKey: Self.showAvatarSettingKey) {
            let model = SwitchSettingModel(title: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ShowIdentity_Title,
                                           detail: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ShowIdentity_Descrip,
                                           property: Self.showAvatarSettingKey,
                                           order: 2,
                                           openEvent: .showVisitorAvatarOpen,
                                           closeEvent: .showVisitorAvatarClose,
                                           isOn: showAvatarIsOn)
            models.append(model)
        }
        uiAction.accept(.reloadTableView)
    }

    func fetchDataFormNetwork() {
        let privacySetting = api.requestPrivacySetting().asObservable().share(replay: 2)

        let adminReadPrivacyStatus = api.requestAdminReadPrivacyStatus(token: docsInfo.token, type: docsInfo.type.rawValue)
            .asObservable()
            .flatMap { [weak self] flag -> Observable<SwitchSettingModel> in
                if flag {
                    let model = SwitchSettingModel(title: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ViewHistory_Title,
                                                   detail: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ViewHistory_Descrip,
                                                   property: Self.readRecordSettingKey,
                                                   order: 1,
                                                   openEvent: .readRecordOpen,
                                                   closeEvent: .readRecordClose,
                                                   isOn: true)
                    return .just(model)
                }
                self?.cache.removeObject(forKey: Self.readRecordSettingKey)
                return .empty()
            }

        let adminAvatarStatus = api.requestAdminAvatarStatus()
            .asObservable()
            .flatMap { [weak self] flag -> Observable<SwitchSettingModel> in
                if flag {
                    let model = SwitchSettingModel(title: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ShowIdentity_Title,
                                                   detail: BundleI18n.SKResource.LarkCCM_Docs_DocDetail_ShowIdentity_Descrip,
                                                   property: Self.showAvatarSettingKey,
                                                   order: 2,
                                                   openEvent: .showVisitorAvatarOpen,
                                                   closeEvent: .showVisitorAvatarClose,
                                                   isOn: true)
                    return .just(model)
                }
                self?.cache.removeObject(forKey: Self.showAvatarSettingKey)
                return .empty()
            }

        let pageAction = Observable.merge(
            adminReadPrivacyStatus,
            adminAvatarStatus
        )
        .flatMap { [weak self] model -> Observable<SwitchSettingModel> in
            return privacySetting.map { [weak self] setting in
                let key = model.property
                if let isOn = setting?[key].bool {
                    model.isOn = isOn
                }
                self?.cache.set(model.isOn, forKey: model.property)
                return model
            }
        }
        .toArray()
        .map { [weak self] models -> UIAction in
            self?.models = models.sorted(by: { lModel, rModel in
                lModel.order < rModel.order
            })
            if models.count > 0 {
                return .reloadTableView
            } else {
                return .showEmpty(true)
            }
        }
        
        let reloadActions: Observable<UIAction>
        if models.count > 0 {
            reloadActions = pageAction.asObservable()
        } else {
            reloadActions = Observable<UIAction>.concat(
                .just(.showLoading(true, true)),
                pageAction.asObservable(),
                .just(.showLoading(false, true))
            )
        }

        reloadActions.bind(to: uiAction).disposed(by: disposeBag)
    }

    func handlerSwitch(_ isOn: Bool, model: SwitchSettingModel) {
        DocsDetailInfoReport.settingClick(action: isOn ? model.openEvent : model.closeEvent).report(docsInfo: docsInfo)
        if !DocsNetStateMonitor.shared.isReachable {
            uiAction.accept(.showToast(.error(BundleI18n.SKResource.Doc_List_OperateFailedNoNet)))
            return
        }
        uiAction.accept(.showLoading(true, false))

        api.requestModifyPrivacySetting(isOn: isOn, model: model).subscribe(onSuccess: { [weak self] isSuccess in
            guard let self = self else { return }
            self.uiAction.accept(.showLoading(false, false))
            if isSuccess {
                model.isOn = isOn
                self.uiAction.accept(.showToast(.success(BundleI18n.SKResource.Doc_Facade_SetSuccess)))
                self.cache.set(model.isOn, forKey: model.property)
            } else {
                model.isOn = !isOn
                self.uiAction.accept(.reloadTableView)
                self.uiAction.accept(.showToast(.error(BundleI18n.SKResource.Doc_Facade_SetFailed)))
            }
        }).disposed(by: disposeBag)
    }
}
