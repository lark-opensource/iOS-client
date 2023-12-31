//
//  MeetingAccountManageViewModel.swift
//  Calendar
//
//  Created by pluto on 2022-10-19.
//

import UIKit
import Foundation
import RxSwift
import RxRelay
import LarkContainer
import LKCommonsLogging

struct MeetingAccountCellData {
    var type: CalendarMeetingAccountType
    var name: String

    init(type: CalendarMeetingAccountType, name: String) {
        self.type = type
        self.name = name
    }
}

protocol MeetingAccountManageViewModelDelegate: AnyObject {
    func updateExpiredTips(needShow: Bool)
}

final class MeetingAccountManageViewModel: UserResolverWrapper {

    private let logger = Logger.log(MeetingAccountManageViewModel.self, category: "calendar.MeetingAccountManageViewModel")
    private let disposeBag = DisposeBag()
    private let normalCellHeight: CGFloat = 48
    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    let userResolver: UserResolver

    var zoomAccount: String?
    var zoomAuthUrl: String?
    var cellHeight: CGFloat?
    var refreshAccountCallBack: (() -> Void)?
    weak var delegate: MeetingAccountManageViewModelDelegate?

    let rxRoute = PublishRelay<Route>()
    let rxToast = PublishRelay<ToastStatus>()

    var zoomMeetingAccount: MeetingAccountCellData {
        if let account = zoomAccount, !account.isEmpty {
            return MeetingAccountCellData(type: .zoom, name: account)
        }
        return MeetingAccountCellData(type: .add, name: I18n.Calendar_Settings_BindMeetAccount)
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private func resetZoomAccount() {
        zoomAccount = nil
        zoomAuthUrl = nil
    }

    func loadZoomAccount() {
        guard let rustApi = self.calendarAPI else {
            logger.error("loadZoomAccount failed, can not get rustapi from larkcontainer")
            return
        }
        rustApi.getZoomAccountRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else {
                    return
                }
                self.logger.info("loadZoomAccount request success with \(response.status)")
                switch response.status {
                case .normal:
                    self.zoomAccount = response.account
                    self.delegate?.updateExpiredTips(needShow: false)
                    self.cellHeight = self.normalCellHeight
                case .unbind:
                    self.zoomAuthUrl = response.zoomAuthURL
                    self.delegate?.updateExpiredTips(needShow: false)
                    self.cellHeight = self.normalCellHeight
                case .expired:
                    self.zoomAccount = response.account
                    self.zoomAuthUrl = response.zoomAuthURL
                    self.delegate?.updateExpiredTips(needShow: true)
                    self.cellHeight = self.normalCellHeight + 24
                @unknown default:
                    break
                }
                self.refreshAccountCallBack?()
            }, onError: {[weak self] error in
                guard let `self` = self else {
                    return
                }
                self.logger.error("loadZoomAccount failed: \(error)")
                self.refreshAccountCallBack?()
                self.rxToast.accept(.failure(I18n.Calendar_Zoom_FailLoadData))
            }).disposed(by: disposeBag)
    }

    func removeZoomAccount() {
        guard let rustApi = self.calendarAPI else {
            logger.error("removeZoomAccount failed, can not get rustapi from larkcontainer")
            return
        }
        rustApi.revokeZoomAccountRequest(account: zoomAccount ?? "")
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else {
                    return
                }

                switch response.respState {
                case .revokeSuccess:
                    self.logger.info("removeZoomAccount success")
                    self.resetZoomAccount()
                    self.refreshAccountCallBack?()
                    self.cellHeight = self.normalCellHeight
                case .revokeFailed:
                    self.logger.info("removeZoomAccount  failed")
                @unknown default:
                    break
                }
            }, onError: {[weak self] error in
                guard let `self` = self else {
                    return
                }
                self.logger.error("remove ZoomAccount failed: \(error)")
                self.rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
            }).disposed(by: disposeBag)
    }

    // url跳转oauth认证，若无url则请求拉取url再跳转
    func importZoomAccount() {
        logger.info("jump to oauth web")
        guard let authUrl = zoomAuthUrl else {
            guard let rustApi = self.calendarAPI else {
                logger.error("getZoomAccountRequest failed, can not get rustapi from larkcontainer")
                return
            }
            rustApi.getZoomAccountRequest()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (response) in
                    guard let `self` = self else {
                        return
                    }
                    self.logger.info("loadZoomAccount request success")
                    if !response.zoomAuthURL.isEmpty {
                        self.goOauthVerify(authUrl: response.zoomAuthURL)
                    } else {
                        self.rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
                    }
                }, onError: {[weak self] error in
                    guard let `self` = self else {
                        return
                    }
                    self.logger.error("loadZoomAccountStatus failed: \(error)")
                    self.rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
                }).disposed(by: disposeBag)
            return
        }
        goOauthVerify(authUrl: authUrl)
    }

    private func goOauthVerify(authUrl: String) {
        if let url = URL(string: authUrl), !authUrl.isEmpty {
            self.logger.info("jump ZoomAccount auth page")
            rxRoute.accept(.url(url: url))
        } else {
            rxToast.accept(.failure(BundleI18n.Calendar.Calendar_GoogleCal_TryLater))
        }
    }
}

extension MeetingAccountManageViewModel {
    enum Route {
        case url(url: URL)
    }
}
