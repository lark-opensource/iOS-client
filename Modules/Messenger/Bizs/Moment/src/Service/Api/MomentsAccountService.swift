//
//  MomentsAccountService.swift
//  Moment
//
//  Created by ByteDance on 2022/12/7.
//

import Foundation
import RxSwift
import RustPB
import ServerPB
import LarkContainer
import LarkAccountInterface
import LarkSDKInterface
import LarkFeatureGating
import EENavigator
import UniverseDesignToast
import UniverseDesignDialog
import LarkRustClient
import LarkTab
import LarkNavigation
import ThreadSafeDataStructure
import LarkSetting
import RxCocoa
import LKCommonsLogging

protocol MomentsAccountService {
    var rxCurrentAccount: BehaviorRelay<String?> { get } //当前身份信息改变时会发出信号（用于重新拉数据等）
    var rxAnyAccountInfoChanged: PublishSubject<Void> { get }                            //账号信息发生任何改变（头像、昵称、切换身份）都会发出信号(用户刷navBar等)
    func fetchMyOfficialUsers(forceRemote: Bool, completion: @escaping ([MomentUser]?) -> Void)
    func fetchCurrentOperatorUserId(completion: @escaping ((userID: String, isOfficialUser: Bool)?) -> Void)
    func setCurrentOperatorUserId(userID: String, isOfficialUser: Bool, from: NavigatorFrom?, completion: @escaping (_ success: Bool) -> Void)
    func handleOfficialAccountErrorIfNeed(error: Error, from: NavigatorFrom?) -> Bool //当返回true时，代表 确实是官方号错误，业务上可能需要中止后续逻辑
    func getCurrentOfficialUser() -> MomentUser? //返回nil时表示是个人身份
    func getCurrentUserId() -> String
    func getCurrentUserAvatarKey() -> String
    func getCurrentUserDisplayName() -> String
    func getPersonalUserDisplayName() -> String
    func getCurrentUserIsOfficialUser() -> Bool
    func getMyOfficialUsers() -> [MomentUser]
}

class MomentsAccountServiceImp: MomentsAccountService, UserResolverWrapper {
    private static var logger = Logger.log(MomentsAccountServiceImp.self, category: "Module.Moments.MomentsAccountService")
    let userResolver: UserResolver

    private var _myOfficialUsers: SafeAtomic<[MomentUser]?> = nil + .readWriteLock
    private var myOfficialUsers: [MomentUser]? {
        get {
            _myOfficialUsers.value
        }
        set {
            let oldValue = _myOfficialUsers.value
            _myOfficialUsers.value = newValue
            //didSet
            guard let currentOperatorUserInfo = currentOperatorUserInfo,
                  let myOfficialUsers = newValue,
                  !myOfficialUsers.isEqualForOfficialUserInfo(with: oldValue) else { return }
            Self.logger.info("myOfficialUsers changed, ids: \(myOfficialUsers.compactMap { $0.userID })")
            rxAnyAccountInfoChanged.onNext(())
        }
    }
    private var _currentOperatorUserInfo: SafeAtomic<(userID: String, isOfficialUser: Bool)?> = nil + .readWriteLock
    private var currentOperatorUserInfo: (userID: String, isOfficialUser: Bool)? {
        get {
            _currentOperatorUserInfo.value
        }
        set {
            let oldValue = _currentOperatorUserInfo.value
            _currentOperatorUserInfo.value = newValue
            //didSet
            guard let currentOperatorUserInfo = newValue,
                  currentOperatorUserInfo.userID != oldValue?.userID else { return }
            let userID = getCurrentUserId()
            Self.logger.info("currentOperatorUserInfo changed, userId: \(userID)")
            rxCurrentAccount.accept(userID)
        }
    }
    var rxCurrentAccount: BehaviorRelay<String?> = .init(value: nil)
    var rxAnyAccountInfoChanged: PublishSubject<Void> = .init()

    private var disposeBag = DisposeBag()
    @ScopedInjectedLazy private var officialAccountAPI: OfficialAccountAPI?
    @ScopedInjectedLazy private var momentsAccountNoti: MomentsAccountNotification?
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy private var navigationService: NavigationService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        loadAccountInfoIfNeed()
        momentsAccountNoti?.rxOfficialAccountChanged
            .subscribe { [weak self] _ in
                self?.onOfficialAccountChanged()
            }.disposed(by: disposeBag)
        self.rxCurrentAccount
            .subscribe { [weak self] _ in
                self?.rxAnyAccountInfoChanged.onNext(())
            }.disposed(by: disposeBag)
    }

    private func onOfficialAccountChanged() {
        fetchMyOfficialUsers(forceRemote: true, completion: { [weak self] users in
            if let users = users,
               let currentOperatorUserInfo = self?.currentOperatorUserInfo,
               currentOperatorUserInfo.isOfficialUser,
               !users.contains(where: { user in
                   user.userID == currentOperatorUserInfo.userID
               }) {
                //成功从远端拉到了新的官方号列表，且新的官方号列表不包含当前登录的官方号，则说明官方号身份失效
                self?.showAccountInvalidDialog(from: nil)
            }
        })
    }

    func getCurrentOfficialUser() -> MomentUser? {
        guard let currentOperatorUserInfo = currentOperatorUserInfo,
              let myOfficialUsers = myOfficialUsers else {
            self.loadAccountInfoIfNeed()
            return nil
        }
        guard currentOperatorUserInfo.isOfficialUser else { return nil }
        for user in myOfficialUsers where user.userID == currentOperatorUserInfo.userID {
            return user
        }
        return nil
    }

    func getCurrentUserId() -> String {
        return getCurrentOfficialUser()?.userID ?? userResolver.userID
    }

    func getCurrentUserAvatarKey() -> String {
        return getCurrentOfficialUser()?.avatarKey ?? (try? userResolver.resolve(type: PassportUserService.self).user.avatarKey) ?? ""
    }

    //当前（官方号或个人号）身份的名字
    func getCurrentUserDisplayName() -> String {
        if let officialUser = getCurrentOfficialUser() {
            return officialUser.displayName
        }

        //个人身份
        return getPersonalUserDisplayName()
    }

    //个人身份的名字
    func getPersonalUserDisplayName() -> String {
        let fgValue = (try? userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "lark.chatter.name_with_another_name_p2") ?? false

        if fgValue {
            return chatterManager?.currentChatter.displayWithAnotherName ?? "" //别名
        } else {
            return chatterManager?.currentChatter.localizedName ?? "" //当前语言名字
        }
    }

    func getCurrentUserIsOfficialUser() -> Bool {
        guard let currentOperatorUserInfo = currentOperatorUserInfo else {
            self.loadAccountInfoIfNeed()
            return false
        }
        return currentOperatorUserInfo.isOfficialUser
    }

    func getMyOfficialUsers() -> [MomentUser] {
        guard let myOfficialUsers = myOfficialUsers else {
            self.loadAccountInfoIfNeed()
            return []
        }
        return myOfficialUsers
    }

    func fetchMyOfficialUsers(forceRemote: Bool, completion: @escaping ([MomentUser]?) -> Void) {
        let needRemote = forceRemote ? true : myOfficialUsers == nil
        completion(myOfficialUsers) //先用缓存数据
        if needRemote {
            self.officialAccountAPI?.listMyOfficialUser()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] users in
                    self?.myOfficialUsers = users
                    completion(users)
                }, onError: { (_) in
                }).disposed(by: self.disposeBag)
        }
    }

    func fetchCurrentOperatorUserId(completion: @escaping ((userID: String, isOfficialUser: Bool)?) -> Void) {
        let needRemote = currentOperatorUserInfo == nil
        if needRemote {
            self.officialAccountAPI?.fetchCurrentOperatorUserId()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] response in
                    self?.currentOperatorUserInfo = (response.userID, response.isOfficialUser)
                    completion((response.userID, response.isOfficialUser))
                }, onError: { [weak self] (_) in
                    //如果没有setCurrentOperatorUserId过，get会失败，此时需要默认set成个人账号
                    self?.setDefaultOperatorUserId(completion: completion)
                }).disposed(by: self.disposeBag)
        } else {
            completion(currentOperatorUserInfo)
        }
    }

    func setCurrentOperatorUserId(userID: String, isOfficialUser: Bool, from: NavigatorFrom?, completion: @escaping (_ success: Bool) -> Void) {
        self.officialAccountAPI?.setCurrentOperatorUserId(userID: userID, isOfficialUser: isOfficialUser)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.currentOperatorUserInfo = (userID, isOfficialUser)
                completion(true)
                Self.logger.info("setCurrentOperatorUserId, userId: \(userID), isOfficialUser: \(isOfficialUser)")
            }, onError: { [weak self] error in
                completion(false)
                Self.logger.error("setCurrentOperatorUserId fail", error: error)
                if let error = error as? RCError {
                    switch error {
                    case .businessFailure(errorInfo: let info):
                        switch info.code {
                        case 330_301:
                            //没有官方号权限
                            self?.showSwitchAccountFailDialog(from: from)
                            return
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
                if let mainSceneWindow = self?.userResolver.navigator.mainSceneWindow {
                    UDToast.showFailureIfNeeded(on: mainSceneWindow, error: error)
                }
            }).disposed(by: self.disposeBag)
    }

    private func loadAccountInfoIfNeed() {
        if currentOperatorUserInfo == nil {
            fetchCurrentOperatorUserId(completion: { _ in })
        }
        if myOfficialUsers == nil {
            getMyOfficialUsers(completion: { _ in })
        }
    }

    func handleOfficialAccountErrorIfNeed(error: Error, from: NavigatorFrom?) -> Bool {
        if let error = error as? RCError {
            switch error {
            case .businessFailure(errorInfo: let info):
                switch info.code {
                case 330_301:
                    //没有官方号权限
                    self.showAccountInvalidDialog(from: from)
                    return true
                default:
                    return false
                }
            default:
                return false
            }
        }
        return false
    }

    private func showAccountInvalidDialog(from: NavigatorFrom?) {
        DispatchQueue.main.async { [weak from] in
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.Moment.Moments_IdentityExpired_Title)
            dialog.setContent(text: BundleI18n.Moment.Moments_OfficialAccount_AdminRoleExpired_Toast(MomentTab.tabTitle(), MomentTab.tabTitle()))
            dialog.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_Confirm, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.setDefaultOperatorUserId(completion: nil)
                guard let from = from ?? self.userResolver.navigator.mainSceneTopMost else { return }
                self.goBackToMomentsHome(from: from)
            })
            guard let from = from ?? self.userResolver.navigator.mainSceneTopMost else { return }
            self.userResolver.navigator.present(dialog, from: from.fromViewController?.currentWindow() ?? from)
        }
    }

    private func goBackToMomentsHome(from: NavigatorFrom) {
        guard let navigationService else { return }
        let allTabs = navigationService.mainTabs + navigationService.quickTabs
        let url = Tab.moment.url
        guard allTabs.map({ $0.url }).contains(url) else { return }
        userResolver.navigator.switchTab(url, from: from, animated: false) { [weak from] _ in
            if let container = from?.fromViewController?.animatedTabBarController?.viewController(for: Tab.moment)?.tabRootViewController as? MomentsFeedContainerViewController {
                container.toRecommendTabAndRefresh()
            }
        }
    }

    private func showSwitchAccountFailDialog(from: NavigatorFrom?) {
        DispatchQueue.main.async { [weak from] in
            let dialog = UDDialog()
            dialog.setTitle(text: BundleI18n.Moment.Moments_IdentityExpired_Title)
            dialog.setContent(text: BundleI18n.Moment.Moments_OfficialAccount_UnableSwitchAccount_Toast)
            dialog.addPrimaryButton(text: BundleI18n.Moment.Lark_Community_Confirm, dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.setDefaultOperatorUserId(completion: nil)
                guard let from = from ?? self.userResolver.navigator.mainSceneTopMost else { return }
                self.goBackToMomentsHome(from: from)
            })
            if let from = from {
                self.userResolver.navigator.present(dialog, from: from)
            } else if let mainSceneTopMost = self.userResolver.navigator.mainSceneTopMost {
                if mainSceneTopMost.isBeingDismissed,
                   let presentingVC = mainSceneTopMost.presentingViewController {
                    self.userResolver.navigator.present(dialog, from: presentingVC)
                } else {
                    self.userResolver.navigator.present(dialog, from: mainSceneTopMost)
                }
            }
        }
    }

    private func setDefaultOperatorUserId(completion: (((userID: String, isOfficialUser: Bool)?) -> Void)?) {
        let userID = userResolver.userID
        self.setCurrentOperatorUserId(userID: userID,
                                      isOfficialUser: false, from: nil, completion: { success in
            if !success {
                //这是个本地接口，通常来说当设置为个人身份时永远不会报错
                Self.logger.error("setDefaultOperatorUserId fail")
            }
            if let completion = completion {
                completion((userID, false))
            }
        })
    }
}

protocol OfficialAccountAPI {
    func listMyOfficialUser() -> Observable<[ServerPB.ServerPB_Moments_entities_MomentUser]>
    func setCurrentOperatorUserId(userID: String, isOfficialUser: Bool) -> Observable<Void>
    func fetchCurrentOperatorUserId() -> Observable<RustPB.Moments_V1_GetCurrentOperatorUserIdResponse>
}
extension RustApiService: OfficialAccountAPI {
    func listMyOfficialUser() -> Observable<[ServerPB.ServerPB_Moments_entities_MomentUser]> {
        var request = ServerPB.ServerPB_Moments_ListMyOfficialUsersRequest()
        return client.sendPassThroughAsyncRequest(request, serCommand: .momentsListMyOfficialUsers)
            .map { (response: ServerPB.ServerPB_Moments_ListMyOfficialUsersResponse) -> [ServerPB_Moments_entities_MomentUser] in
                return response.officialUsers
            }
    }

    func setCurrentOperatorUserId(userID: String, isOfficialUser: Bool) -> Observable<Void> {
        var request = RustPB.Moments_V1_SetCurrentOperatorUserIdRequest()
        request.userID = userID
        request.isOfficialUser = isOfficialUser
        return client.sendAsyncRequest(request)
    }

    func fetchCurrentOperatorUserId() -> Observable<RustPB.Moments_V1_GetCurrentOperatorUserIdResponse> {
        var request = RustPB.Moments_V1_GetCurrentOperatorUserIdRequest()
        return client.sendAsyncRequest(request)
    }
}

extension MomentUser {
    //在展示官方号信息时，是否认为两个user相等
    func isEqualForOfficialUserInfo(with anotherUser: MomentUser) -> Bool {
        guard self.userID == anotherUser.userID else { return false }
        guard self.displayName == anotherUser.displayName else { return false }
        guard self.avatarKey == anotherUser.avatarKey else { return false }
        return true
    }
}
extension Array where Element == MomentUser {
    //在展示官方号信息时，是否认为两个user相等
    func isEqualForOfficialUserInfo(with anotherArray: [MomentUser]?) -> Bool {
        guard let anotherArray = anotherArray else { return false }
        guard self.count == anotherArray.count else { return false }
        for (index, momentUser) in self.enumerated() {
            guard momentUser.isEqualForOfficialUserInfo(with: anotherArray[index]) else {
                return false
            }
        }
        return true
    }
}

extension MomentsAccountService {
    func getMyOfficialUsers(completion: @escaping ([MomentUser]?) -> Void) {
        self.fetchMyOfficialUsers(forceRemote: false, completion: completion)
    }

    //是否由于账号身份而被禁用点赞（官方号禁止给匿名贴点赞）
    func isDisableReactionDueToAccount(user: MomentUser?) -> Bool {
        if user?.momentUserType == .anonymous || user?.momentUserType == .nickname,
           self.getCurrentUserIsOfficialUser() {
            return true
        }
        return false
    }

    // MARK: - MomentsAccountService + Notification
    func getCurrentUserBadge(_ momentsBadgeInfo: MomentsBadgeInfo) -> RawData.MomentsBadgeCount {
        if let officialUserBadgeInfo = momentsBadgeInfo.officialUsersBadge[getCurrentUserId()] {
            return officialUserBadgeInfo
        }
        return momentsBadgeInfo.personalUserBadge
    }

    func getCurrentUserTotalBadgeCount(_ momentsBadgeInfo: MomentsBadgeInfo) -> Int {
        return self.getTotalBadgeCountOf(self.getCurrentUserBadge(momentsBadgeInfo))
    }

    func getAllUsersTotalCount(_ momentsBadgeInfo: MomentsBadgeInfo) -> Int {
        var result = getTotalBadgeCountOf(momentsBadgeInfo.personalUserBadge)
        for (_, officialUserBadge) in momentsBadgeInfo.officialUsersBadge {
            result += getTotalBadgeCountOf(officialUserBadge)
        }
        return result
    }

    //获得除当前身份以外的所有身份的badge总和
    func getOtherUsersTotalBadgeCount(_ momentsBadgeInfo: MomentsBadgeInfo) -> Int {
        return getAllUsersTotalCount(momentsBadgeInfo) - getCurrentUserTotalBadgeCount(momentsBadgeInfo)
    }

    func getTotalBadgeCountOf(_ badge: RawData.MomentsBadgeCount) -> Int {
        return Int(badge.messageCount + badge.reactionCount)
    }

    func updateBadgeOnPutRead(_ currentBadgeInfo: MomentsBadgeInfo, messageCount: Int32, reactionCount: Int32) -> MomentsBadgeInfo {
        var result = currentBadgeInfo
        if let officialUser = self.getCurrentOfficialUser() {
            result.officialUsersBadge[officialUser.userID]?.messageCount = messageCount
            result.officialUsersBadge[officialUser.userID]?.reactionCount = reactionCount
        } else {
            result.personalUserBadge.messageCount = messageCount
            result.personalUserBadge.reactionCount = reactionCount
        }
        return result
    }
}
