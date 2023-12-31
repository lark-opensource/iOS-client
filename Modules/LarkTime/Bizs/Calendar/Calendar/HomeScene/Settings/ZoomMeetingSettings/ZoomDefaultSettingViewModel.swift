//
//  ZoomDefaultSettingViewModel.swift
//  Calendar
//
//  Created by pluto on 2022/10/27.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignIcon
import CalendarFoundation
import LKCommonsLogging
import LarkContainer
import ServerPB

protocol ZoomDefaultSettingViewModelDelegate: AnyObject {
    func updateSecurityNoticeTips(needShow: Bool)
    func updateErrorNoticeTips(errorState: Server.UpdateZoomSettingsResponse.State, passTips: [String], hostTip: String)
    func zoomSettingDismissCallBack()
    func updateErrorTipsStatus(type: Server.UpdateZoomSettingsResponse.State)
}

class ZoomDefaultSettingViewModel: UserResolverWrapper {

    private let logger = Logger.log(ZoomDefaultSettingViewModel.self, category: "calendar.ZoomDefaultSettingViewModel")
    private let disposeBag = DisposeBag()
    weak var delegate: ZoomDefaultSettingViewModelDelegate?

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    let userResolver: UserResolver

    let rxViewData = BehaviorRelay<ZoomSettingListViewDataType?>(value: nil)
    let rxToast = PublishRelay<ToastStatus>()
    let rxRoute = PublishRelay<Route>()

    // 设置placeHolderPage状态
    var setPlaceHolderStatus: ((ZoomDefaultSettingController.PlaceholderStatus) -> Void)?
    var onSaveCallBack: ((Int64, String, String) -> Void)?

    // 最原始Setting，保存时对比用，拉到后不再更新
    var originalZoomSettings: Server.ZoomSetting?
    // 用于变更性对比Setting，每次点保存时会更新
    var comparableZoomSettings: Server.ZoomSetting?
    var passCodeErrroTips: [String] = []
    var hasSecurityError: Bool = false
    var hasInputError: Bool = false
    let meetingID: Int64

    init(meetingID: Int64, userResolver: UserResolver) {
        self.meetingID = meetingID
        self.userResolver = userResolver
        loadZoomSetting()
    }

    func loadZoomSetting() {
        setPlaceHolderStatus?(.loading)
        calendarAPI?.getZoomMeetingSettingsRequest(meetingID: meetingID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.error("getZoomMeetingSettingsRequest success.")

                var zoomSettings = res.zoomSettings
                self.originalZoomSettings = zoomSettings
                // 个人会议号 需要表现和下发不同，类型强制转一下
                if zoomSettings.isPersonMeetingNoSelected { zoomSettings.joinBeforeHost.jbhType = .anytime }
                self.comparableZoomSettings = zoomSettings
                self.rxViewData.accept(ViewData(zoomSetting: zoomSettings))

                self.setPlaceHolderStatus?(.normal)
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.logger.error("getZoomMeetingSettingsRequest failed:\(error)")
                if error.errorType() == .calendarZoomAuthenticationFailed {
                    self.setPlaceHolderStatus?(.accountRebind)
                } else {
                    self.rxToast.accept(.tips(I18n.Calendar_G_SomethingWentWrong))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.delegate?.zoomSettingDismissCallBack()
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func onSaveSettings() {
        if rxViewData.value?.zoomSetting ?? Server.ZoomSetting() == originalZoomSettings {
            self.delegate?.zoomSettingDismissCallBack()
            return
        }

        /// 存储保存前状态，用于设置页各种提示的更新判断
        self.comparableZoomSettings = rxViewData.value?.zoomSetting
        calendarAPI?.updateZoomMeetingSettingsRequest(meetingID: meetingID, zoomSetting: rxViewData.value?.zoomSetting ?? Server.ZoomSetting())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                self.logger.info("saveZoomMeetingSettingsRequest success with:\(res.respState)")
                switch res.respState {
                case .success:
                    self.delegate?.zoomSettingDismissCallBack()
                    self.onSaveCallBack?(res.meetingNo, res.password, res.meetingURL)
                case .alternativeHostsIllegal, .passwordIllegal:
                    // 这的zoom接口，尽管有可能同时错了两种，但一次最多只会返回一种错误
                    self.delegate?.updateErrorNoticeTips(errorState: res.respState, passTips: res.passwordErr, hostTip: res.alternativeHostsErr)
                    self.passCodeErrroTips = res.passwordErr
                    self.hasInputError = true
                case .fail:
                    self.rxToast.accept(.tips(I18n.Calendar_Zoom_EditFailRetry))
                @unknown default:
                    break
                }
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.logger.error("saveZoomMeetingSettingsRequest failed:\(error)")
                self.rxToast.accept(.tips(I18n.Calendar_Zoom_EditFailRetry))
            })
            .disposed(by: disposeBag)
    }

    func securityOptionsCheck() {
        // 安全检查
        let needShow = !checkReachMinSecurityOptionNum()
        hasSecurityError = needShow
        self.delegate?.updateSecurityNoticeTips(needShow: needShow)
    }

    // 是否开启 会议密码 会议室 身份验证
    func checkReachMinSecurityOptionNum() -> Bool {
        guard let zoomSetting = rxViewData.value?.zoomSetting else { return false }

        let passCodeOption: Bool = zoomSetting.isPassCodeOptionOpen
        let waitingRoomOption: Bool = zoomSetting.isWaitingRoomOptionOpen
        let authenticationOption: Bool = zoomSetting.isAuthenticationOptionOpen

        return passCodeOption || waitingRoomOption || authenticationOption
    }

    func getZoomPassCodeInfo() -> Server.ZoomSetting.Password {
        guard let zoomSetting = rxViewData.value?.zoomSetting else {
            return Server.ZoomSetting.Password()
        }

        if zoomSetting.isPersonMeetingNoSelected {
            return zoomSetting.personalMeetingNoPassword.passwordInfo
        } else {
            return zoomSetting.autogenMeetingNoPassword.passwordInfo
        }
    }

    func getAuthenticationInfo() -> Server.ZoomMeetingSettings.Authentication {
        guard let zoomSetting = rxViewData.value?.zoomSetting else {
            return Server.ZoomMeetingSettings.Authentication()
        }
        return zoomSetting.authentication
    }

    func getAlternativeHosts() -> [String] {
        guard let zoomSetting = rxViewData.value?.zoomSetting else {
            return []
        }
        return zoomSetting.alternativeHosts
    }

    func getLimitTimeInfo() -> Server.ZoomMeetingSettings.BeforeHost {
        guard let zoomSetting = rxViewData.value?.zoomSetting else {
            return Server.ZoomMeetingSettings.BeforeHost()
        }
        return zoomSetting.joinBeforeHost
    }

    func loadZoomOauthUrlAndBind() {
        self.setPlaceHolderStatus?(.loading)
        calendarAPI?.getZoomAccountRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else {
                    return
                }
                self.logger.info("loadZoomAccount request success with \(response.status)")
                self.goOauthVerify(authUrl: response.zoomAuthURL)
            }, onError: {[weak self] error in
                guard let `self` = self else {
                    return
                }
                self.logger.error("loadZoomAccount failed: \(error)")
                self.setPlaceHolderStatus?(.accountRebind)
                self.rxToast.accept(.failure(I18n.Calendar_Zoom_FailLoadData))
            }).disposed(by: disposeBag)
    }

    private func goOauthVerify(authUrl: String) {
        if let url = URL(string: authUrl), !authUrl.isEmpty {
            self.logger.info("jump ZoomAccount auth page")
            rxRoute.accept(.url(url: url))
        } else {
            self.logger.info("jump ZoomAccount auth page failed ： error with wrong url")
            rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
            self.setPlaceHolderStatus?(.accountRebind)
        }
    }
}

extension ZoomDefaultSettingViewModel {
    struct ViewData: ZoomSettingListViewDataType {
        var zoomSetting: Server.ZoomSetting
    }

    enum Route {
        case url(url: URL)
    }
}
