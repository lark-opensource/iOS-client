//
//  CallRequest.swift
//  LarkCore
//
//  Created by 李勇 on 2019/6/19.
//

import Foundation
import LarkFoundation
import EENavigator
import LarkUIKit
import UniverseDesignToast
import RxSwift
import Swinject
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LarkRustClient
import ServerPB

/// 获取电话号码返回状态
public enum QueryQuotaStatus: Int32 {
    /// 有权限
    case normal = 1
    /// 被限制拨号
    case completeLimit = 0
    /// 达到单日上限
    case todayLimit = -2
    /// 还剩两次
    case todayLaveTwo = 2
    /// 第161次获取
    case maxNumber = -3
    /// 高管模式限制
    case highManagerLimit = -4
    /// 单聊电话限制，进行阻断
    case forbidTelPermission = -5
}

public final class CallRequest: CallRequestService, UserResolverWrapper {
    public let userResolver: UserResolver
    private let disposeBag: DisposeBag = DisposeBag()
    private let userAPI: ChatterAPI
    @ScopedInjectedLazy private var rustService: RustService?

    public init(userResolver: UserResolver, userAPI: ChatterAPI) {
        self.userResolver = userResolver
        self.userAPI = userAPI
    }

    public func callChatter(chatterId: String, chatId: String, deniedAlertDisplayName: String, from: NavigatorFrom, errorBlock: ((Error?) -> Void)?, actionBlock: ((String) -> Void)?) {
        guard let window = from.fromViewController?.view.window else {
            assertionFailure("缺少Window")
            return
        }
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkCore.Lark_Legacy_ChatViewGettingPhoneNumber, on: window)
        /// 调取新接口获取电话号码
        let id = Int64(chatterId) ?? 0
        let checkRequest = userAPI.checkUserPhoneNumber(userId: id)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
        let fetchRequest = fetchNoticePhoneSetting(by: id)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .catchErrorJustReturn(false)
        Observable.combineLatest(checkRequest, fetchRequest)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self, weak window] (response, needNotice) in
                guard let self, let window = window else { return }
                hud.remove()
                /// 如果服务器返回了错误的status，直接以错误处理
                guard let queryQuotaStatus = QueryQuotaStatus(rawValue: response.status) else {
                    hud.showFailure(with: BundleI18n.LarkCore.Lark_IM_UnableToGetPhoneNum_NetworkErrorRetry, on: window)
                    return
                }
                switch queryQuotaStatus {
                /// 高管模式限制
                case .highManagerLimit:
                    UDToast.showTips(with: response.announcement, on: window)
                /// 可以直接拨打
                case .normal:
                    if response.phoneNumber.isEmpty || LarkFoundation.Utils.isSimulator {
                        UDToast.showTips(with: BundleI18n.LarkCore.Lark_IM_UnableToGetPhoneNum_NoPhoneNum, on: window)
                        return
                    }
                    if let actionBlock = actionBlock {
                        actionBlock(response.phoneNumber)
                    } else {
                        if needNotice {
                            UDToast.showTips(with: BundleI18n.LarkCore.Lark_Legacy_ChatViewNotifyOtherCall, on: window)
                        }
                        let number = response.phoneNumber.replacingOccurrences(of: "-", with: "")
                        LarkFoundation.Utils.telecall(phoneNumber: number)
                    }
                /// 跳转到号码查询限制界面
                default:
                    let body = PhoneQueryLimitBody(queryQuota: response, chatterId: chatterId, chatId: chatId, deniedAlertDisplayName: deniedAlertDisplayName)
                    self.userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .fullScreen })
                }
            }, onError: { [weak window] error in
                guard let window = window else { return }
                errorBlock?(error)
                hud.showFailure(with: BundleI18n.LarkCore.Lark_IM_UnableToGetPhoneNum_NetworkErrorRetry, on: window, error: error)
            }, onCompleted: {
                hud.remove()
            }).disposed(by: self.disposeBag)
    }

    public func callByPhone(chatterId: String, from: NavigatorFrom, callBack: @escaping (String) -> Void) {
        self.callChatter(chatterId: chatterId, chatId: "", deniedAlertDisplayName: "", from: from, errorBlock: nil) { (phoneNumber) in
            guard let window = from.fromViewController?.view.window else { return }
            /// 服务器会发送一条消息，我们只需要弹一个toast即可
            UDToast.showTips(with: BundleI18n.LarkCore.Lark_Legacy_ChatViewNotifyOtherCall, on: window)
            let number = phoneNumber.replacingOccurrences(of: "-", with: "")
            LarkFoundation.Utils.telecall(phoneNumber: number)
            callBack(phoneNumber)
        }
    }

    public func showPhoneNumber(chatterId: String, from: NavigatorFrom, callBack: @escaping (String) -> Void) {
        self.callChatter(chatterId: chatterId, chatId: "", deniedAlertDisplayName: "", from: from, errorBlock: nil) { (phoneNumber) in
            callBack(phoneNumber)
        }
    }

    private func fetchNoticePhoneSetting(by id: Int64) -> Observable<Bool> {
        let key = "CHECK_PHONE_NOTIFY"
        var request = ServerPB_Settings_PullOtherUniversalUserSettingRequest()
        request.key = [key]
        request.userID = id
        return rustService?.sendPassThroughAsyncRequest(request, serCommand: .pullOtherUniversalUserSetting).map { (res: ServerPB_Settings_PullOtherUniversalUserSettingResponse) in
            if let setting = res.settings[key] {
                return setting.boolValue
            }
            return false
        } ?? .error(RCError.cancel)
    }
}
