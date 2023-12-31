//
//  V3SelectUserViewModel.swift
//  LarkAccount
//
//  Created by dengbo on 2021/6/2.
//

import Foundation
import LarkLocalizations
import RxSwift
import RxRelay
import Homeric
import LKCommonsLogging
import LarkPerf
import LarkContainer
import LarkEnv
import ECOProbeMeta

class V3SelectUserViewModel: V3ViewModel {

    @Provider var api: LoginAPI
    var selectUserInfo: V4SelectUserInfo
    let disposeBag: DisposeBag = DisposeBag()
    
    /// 当用户存在未加入身份时：选择加入/拒绝身份的页面不能返回；加入多个身份后的选择页面可以返回
    /// 其他情况都可以返回
    var needSkipWhilePop: Bool {
        return selectUserInfo.refuseItem != nil
    }

    let logger = Logger.log(V3SelectUserViewModel.self, category: "SuiteLogin.V3SelectUserViewModel")

    var stopLoadingBlock:(() -> Void)?

    let isEditing = BehaviorRelay<Bool>(value: false)
    let dataSource = BehaviorRelay<[(name: String?, data: [SelectUserCellData])]>(value: [])
    let joinButtonInfo = BehaviorRelay<V4ButtonInfo?>(value: nil)
    private(set) var cellDataList = [(name: String?, data: [SelectUserCellData])]()

    init(
        step: String,
        stepInfo: V4SelectUserInfo,
        context: UniContextProtocol
    ) {
        self.selectUserInfo = stepInfo
        super.init(step: step, stepInfo: selectUserInfo, context: context)
        makeDataSource()
        joinButtonInfo.accept(stepInfo.joinButton)
    }

    func choose(userIndex: IndexPath) -> Observable<Void>? {
        let data = getData(of: userIndex)
        logger.info("choose user_id: \(data.userId), tenant_id: \(data.tenantId)")
        SuiteLoginTracker.track(Homeric.REGISTER_CLICK_SELECTED_USER)
        if data.type == .normal {
            return enterApp(cellData: data)
        } else {
            return enterEmailCreate(cellData: data)
        }
    }

    func getData(of index: IndexPath) -> SelectUserCellData {
        guard index.section < cellDataList.count && index.row < cellDataList[index.section].data.count else {
            return .placeholder()
        }
        return cellDataList[index.section].data[index.row]
    }
}

extension V3SelectUserViewModel {

    var title: String {
        return selectUserInfo.title ?? ""
    }

    func makeDataSource() {
        var result = [(String?, [SelectUserCellData])]()
        let canEdit = selectUserInfo.refuseItem != nil
        selectUserInfo.groupList?.forEach({ group in
            if let userList = group.userList {
                result.append((group.subtitle, userList.map({ (userItem: V4UserItem) -> SelectUserCellData in
                    var cellData = userItem.toCellData()
                    cellData.canEdit = canEdit
                    return cellData
                })))
            }
        })
        cellDataList = result
        dataSource.accept(cellDataList)
    }
}

extension V3SelectUserViewModel {
    func createTenant() -> Observable<Void>? {
        Self.logger.info("click to v4 create tenant")
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            self.service.v4CreateTenant(serverInfo: self.selectUserInfo, success: {
                observer.onNext(())
                observer.onCompleted()
            }, error: { (error) in
                observer.onError(error)
            }, context: self.context)

            return Disposables.create()
        }
    }

    func enterApp(cellData: SelectUserCellData) -> Observable<Void> {
        Self.logger.info("click to v4 enter app")
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            self.service.v4EnterApp(serverInfo: self.selectUserInfo, userId: cellData.userId, success: {
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.login_user_list_app_request_succ, categoryValueMap: ["type": "enterApp"], context: self.context)
                observer.onNext(())
                observer.onCompleted()
            }, error: { (error) in
                observer.onError(error)
            }, context: self.context)
            
            return Disposables.create()
        }
    }

    func enterEmailCreate(cellData: SelectUserCellData) -> Observable<Void> {
        Self.logger.info("click to v4 enter email create")
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            self.service.v4EnterEmailCreate(serverInfo: self.selectUserInfo, tenantId: cellData.tenantId, success: {
                PassportMonitor.flush(EPMClientPassportMonitorLoginCode.login_user_list_app_request_succ,
                                      categoryValueMap: ["type": "enterEmailCreate"],
                                      context: self.context)
                observer.onNext(())
                observer.onCompleted()
            }, error: { (error) in
                observer.onError(error)
            }, context: self.context)

            return Disposables.create()
        }
    }
}

extension V3SelectUserViewModel {
    enum BottomStyle {
        case none
        case doubleButton
        case singleButton
        case singleTips
        case refuseButton
    }

    func bottomStyle() -> BottomStyle {
        if selectUserInfo.refuseItem != nil {
            return .refuseButton
        } else if selectUserInfo.joinButton != nil {
            return selectUserInfo.registerButton == nil ? .singleTips : .doubleButton
        }
        return selectUserInfo.registerButton == nil ? .none : .singleButton
    }
}

extension V3SelectUserViewModel {
    func image(by actionType: ActionIconType?) -> UIImage? {
        guard let type = actionType else {
            return nil
        }
        switch type {
        case .register:
            return BundleResources.LarkAccount.V4.v4_register_new
        case .join:
            return BundleResources.LarkAccount.V4.v4_login_new
        case .createTenant:
            return BundleResources.LarkAccount.V4.v4_create_tenant
        case .createPersonal:
            return BundleResources.LarkAccount.V4.v4_create_user
        default:
            return nil
        }
    }
}


extension V3SelectUserViewModel {
    
    func startEdit() {
        makeAllUser(selected: false)
        isEditing.accept(true)
    }
    
    func cancelEdit() {
        makeAllUser(selected: false)
        isEditing.accept(false)
    }
    
    func selectAll() {
        makeAllUser(selected: true)
        dataSource.accept(cellDataList)
    }
    
    func deselectAll() {
        makeAllUser(selected: false)
        dataSource.accept(cellDataList)
    }
    
    private func makeAllUser(selected: Bool) {
        updateAllCellData { cellData in
            var newCellData = cellData
            newCellData.isSelected = selected
            return newCellData
        }
    }
    
    private func updateAllCellData(with updateBlock: (_ cellData: SelectUserCellData) -> SelectUserCellData) {
        cellDataList = cellDataList.map({ name, data in
            return (name, data.map({ cellData in
                return updateBlock(cellData)
            }))
        })
    }
    
    func toggleSelectionForUser(at indexPath: IndexPath) {
        if isEditing.value {
            if indexPath.section < cellDataList.count
                && indexPath.row < cellDataList[indexPath.section].data.count {
                cellDataList[indexPath.section].data[indexPath.row].isSelected.toggle()
                dataSource.accept(cellDataList)
            }
        }
    }
    
    func joinTenants() -> Observable<Void> {
        var userIds = cellDataList.flatMap { (_, data) in
            return data.map { $0.userId }
        }
        return api.joinTenant(serverInfo: selectUserInfo, userIds: userIds, context: context)
            .post(context: context)
    }
    
    func checkRefuseInvitation() -> Observable<V4ShowDialogStepInfo> {
        // 本地处理 show_dialog，因为没有 next_step，否则流程无法串联
        return api.checkRefuseInvitation(serverInfo: selectUserInfo,
                                         userIds: getSelectedUserIds(),
                                         context: context)
            .map({ [weak self] step in
                guard let data = try? JSONSerialization.data(withJSONObject: step.stepData.stepInfo, options: .prettyPrinted) else {
                    throw V3LoginError.badServerData
                }
                
                do {
                    let serverInfo = try JSONDecoder().decode(V4ShowDialogStepInfo.self, from: data)
                    return serverInfo
                } catch {
                    throw error
                }
            })
    }
    
    func refuseInvitation() -> Observable<String?> {
        
        return api.refuseInvitation(serverInfo: selectUserInfo,
                                    userIds: getSelectedUserIds(),
                                    context: context)
            .flatMap({ [weak self] step -> Observable<String?> in
                guard let `self` = self else { throw V3LoginError.clientError("") }
                
                if let nextStep = PassportStep(rawValue: step.stepData.nextStep),
                   nextStep == .userList,
                   step.stepData.stepInfo[V4SelectUserInfo.CodingKeys.refuseItem.rawValue] != nil {
                    // 当拒绝的结果返回的 step 是 user_list，并且 refuseItem 不为空，说明没有拒绝全部邀请，本地更新列表
                    guard let data = try? JSONSerialization.data(withJSONObject: step.stepData.stepInfo, options: .prettyPrinted) else {
                        throw V3LoginError.badServerData
                    }
                    
                    do {
                        let serverInfo = try JSONDecoder().decode(V4SelectUserInfo.self, from: data)
                        self.selectUserInfo = serverInfo
                        self.makeDataSource()
                        self.joinButtonInfo.accept(serverInfo.joinButton)
                        self.cancelEdit()
                    } catch {
                        throw error
                    }
                    
                    return .just(self.selectUserInfo.toast)
                } else {
                    // 否则执行返回的 step
                    return Observable<String?>.create({ (ob) -> Disposable in
                        LoginPassportEventBus.shared.post(
                            event: step.stepData.nextStep,
                            context: V3RawLoginContext(
                                stepInfo: step.stepData.stepInfo,
                                backFirst: step.stepData.backFirst,
                                context: self.context
                            ),
                            success: {
                                ob.onNext(nil)
                                ob.onCompleted()
                            }, error: { error in
                                ob.onError(error)
                            })
                        return Disposables.create()
                    })
                }
            })
    }
    
    private func getSelectedUserIds() -> [String] {
        var userIds = [String]()
        
        let singleTenant = cellDataList.reduce(0) { $0 + $1.data.count } == 1
        if singleTenant, let userId = cellDataList.first?.data.first?.userId {
            userIds = [userId]
        } else {
            userIds = cellDataList.flatMap({ (_, data) in
                return data
                    .filter { $0.isSelected }
                    .map { $0.userId}
            })
        }
        return userIds
    }
}
