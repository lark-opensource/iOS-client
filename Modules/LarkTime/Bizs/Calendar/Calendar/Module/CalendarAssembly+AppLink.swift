//
//  CalendarAppLinkAssembly.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/8.
//

import UIKit
import Swinject
import LarkContainer
import AnimatedTabBar
import EENavigator
import LarkNavigation
import LarkRustClient
import RxSwift
import RxCocoa
import LarkTab
import LarkUIKit
import LarkAppLinkSDK
import LKCommonsTracker
import UniverseDesignToast

extension CalendarAssembly {
    static let AppLinkUniqueFields = "uniqueFields"
    static let AppLinkFromApproval = "from_approval"

    public func registLarkAppLink(container: Container) {
        // 跳转视图页
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/open") { appLink in
            guard let from = appLink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            container.getCurrentUserResolver().navigator.switchTab(Tab.calendar.url, from: from, animated: true) { _ in
                guard let calendarHome = try? container.getCurrentUserResolver().resolve(assert: CalendarHome.self) else {
                    assertionFailure("UserResolver resolve CalendarHome failed")
                    return
                }
                calendarHome.jumpToCalendarWithDateAndType(date: nil, type: nil, toTargetTime: false)
            }
        }

        // 跳转视图页，带参数，参数可选
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/view") { [weak self] (applink: AppLink) in
            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            let queryParameters = applink.url.queryParameters
            let type = queryParameters["type"]
            let date = self?.unixStringToDate(unixString: queryParameters["date"])
            let toTargetTime = Bool(queryParameters["to_target_time"] ?? "") ?? false

            container.getCurrentUserResolver().navigator.switchTab(Tab.calendar.url, from: from, animated: true) { _ in
                guard let calendarHome = try? container.getCurrentUserResolver().resolve(assert: CalendarHome.self) else {
                    assertionFailure("UserResolver resolve CalendarHome failed")
                    return
                }
                calendarHome.jumpToCalendarWithDateAndType(date: date ?? Date(), type: type, toTargetTime: toTargetTime)
            }
        }

        // 跳转新建日程页面
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/event/create") { [weak self] (applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            let startTime = self?.unixStringToDate(unixString: queryParameters["startTime"])
            let endTime = self?.unixStringToDate(unixString: queryParameters["endTime"])
            let summary = queryParameters["summary"]
            guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
                assertionFailure("UserResolver resolve CalendarInterface failed")
                return
            }
            let controller = interface.appLinkNewEventController(startTime: startTime,
                                           endTime: endTime,
                                           summary: summary)

            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false

            guard !disableEncrypt else {
                UDToast().showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: from.fromViewController?.view ?? UIView())
                return
            }

            if Display.pad {
                container.getCurrentUserResolver().navigator.present(controller, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
                return
            }

            container.getCurrentUserResolver().navigator.present(controller, from: from)
        }

        // 跳转编辑日程页面
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/event/edit") { (applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            if let linkSource = queryParameters["source"], linkSource == "myai" {
                self.applinkToEventEditForAI(queryParameters: queryParameters, from: from, container: container)
            } else {
                self.applinkToEventEdit(queryParameters: queryParameters, from: from, container: container)
            }

        }

        // 跳转日程详情页
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/event/detail") { (applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            // widget临时埋点，等applink sdk支持统一统计自定义来源时去掉此点
            if let from = queryParameters["from"], from == "widget" {
                Tracker.post(TeaEvent("smart_widget_click"))
            }

            guard let navigatorFrom = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            let calendarId = queryParameters["calendarId"] ?? ""
            let key = queryParameters["key"] ?? ""
            let originalTime = Int64(queryParameters["originalTime"] ?? "") ?? 0
            let token = queryParameters["token"]

            let source: String
            if let tempSource = queryParameters["source"] {
                source = tempSource
            } else {
                if token == nil {
                    source = CalendarAssembly.AppLinkUniqueFields
                } else {
                    source = "share"
                }
            }
            let startTimeStr = queryParameters["startTime"]
            let startTime = Int64(startTimeStr ?? "")

            let endTimeStr = queryParameters["endTime"]
            let endTime: Int64? = Int64(endTimeStr ?? "")

            let isFromAPNS = queryParameters["isFromAPNS"].flatMap { Bool($0) } ?? false

            guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
                assertionFailure("UserResolver resolve CalendarInterface failed")
                return
            }
            let controller = interface.applinkEventDetailController(key: key,
                                              calendarId: calendarId,
                                              source: source,
                                              token: token,
                                              originalTime: originalTime,
                                              startTime: startTime,
                                              endTime: endTime,
                                              isFromAPNS: isFromAPNS)
            let nav = LkNavigationController(rootViewController: controller)
            let from = navigatorFrom.fromViewController?.navigationController ??
            container.getCurrentUserResolver().navigator.mainSceneWindow ?? navigatorFrom
            if Display.pad {
                container.getCurrentUserResolver().navigator.present(nav, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
                return
            }
            if queryParameters["navigateStyle"] == "push" {
                container.getCurrentUserResolver().navigator.push(controller, from: from)
                return
            }
            container.getCurrentUserResolver().navigator.present(nav, from: from, prepare: { $0.modalPresentationStyle = .fullScreen })
        }

        // 跳转新建日历页面
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/create") { (applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            let summary = queryParameters["summary"]
            guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
                assertionFailure("UserResolver resolve CalendarInterface failed")
                return
            }

            let controller = interface.appLinkNewCalendarController(summary: summary) {}

            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            container.getCurrentUserResolver().navigator.present(controller, from: from)
        }

        // 跳转编辑日历页面
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/edit") { (applink: AppLink) in
            let queryParameters = applink.url.queryParameters

            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
                assertionFailure("UserResolver resolve CalendarInterface failed")
                return
            }

            guard let calendarId = queryParameters["calendarId"],
                let controller = interface.appLinkCalendarSettingController(calendarId: calendarId) else {
                let controller = interface.appLinkNewCalendarController(summary: nil) {}
                    container.getCurrentUserResolver().navigator.present(controller, from: from)
                return
            }
            container.getCurrentUserResolver().navigator.present(controller, from: from)
        }

        // 跳转第三方日历管理页
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/account") { (applink: AppLink) in
            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
                assertionFailure("UserResolver resolve CalendarInterface failed")
                return
            }

            let controller = interface.appLinkExternalAccountManageController()
            container.getCurrentUserResolver().navigator.present(controller, from: from)
        }

        // 跳转到日历详情页
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/detail") { (applink: AppLink) in
            let queryParameters = applink.url.queryParameters
            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            let calendarID = queryParameters["calendarId"]
            let shareToken = queryParameters["shareToken"]
            guard calendarID != nil || shareToken != nil else { return }

            let vc: UIViewController
            if FG.optimizeCalendar {
                let vm: CalendarDetailCardViewModel
                let userResolver = container.getCurrentUserResolver()
                if let cid = calendarID {
                    vm = .init(with: cid, userResolver: userResolver)
                    vc = CalendarDetailCardViewController(viewModel: vm)
                } else if let shareToken = shareToken {
                    vm = .init(withToken: shareToken, userResolver: userResolver)
                    vc = CalendarDetailCardViewController(viewModel: vm)
                } else {
                    return
                }
                vc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
                container.getCurrentUserResolver().navigator.present(vc, from: from)
                return
            } else {
                let userResolver = container.getCurrentUserResolver()
                if let cid = calendarID {
                    let viewModel = LegacyCalendarDetailViewModel(param: .calendarID(cid), userResolver: userResolver)
                    vc = LegacyCalendarDetailController(viewModel: viewModel, userResolver: userResolver)
                } else if let shareToken = shareToken {
                    let viewModel = LegacyCalendarDetailViewModel(param: .token(shareToken), userResolver: userResolver)
                    vc = LegacyCalendarDetailController(viewModel: viewModel, userResolver: userResolver)
                } else {
                    return
                }
            }

            let naviVC = LkNavigationController(rootViewController: vc)
            naviVC.update(style: .default)
            naviVC.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
            container.getCurrentUserResolver().navigator.present(naviVC, from: from)
        }

        // 跳转日历tab打开侧边栏，高亮选中日历
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/sidebar") { appLink in
            guard let from = appLink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            let queryParameters = appLink.url.queryParameters
            let calendarId = queryParameters["calendarId"]
            let source = queryParameters["source"]
            container.getCurrentUserResolver().navigator.switchTab(Tab.calendar.url, from: from, animated: true) { _ in
                guard let calendarHome = try? container.getCurrentUserResolver().resolve(assert: CalendarHome.self) else {
                    assertionFailure("UserResolver resolve CalendarHome failed")
                    return
                }
                calendarHome.jumpToSlideView(calendarID: calendarId, source: source)
            }

            CalendarTracerV2.CalendarSubscribeInviteCard.traceClick { params in
                params.calendar_id = calendarId ?? ""
                params.click("open_cal_check").target(.cal_calendar_main_view)
            }
        }

        // 跳转大人数日程审批页面
        LarkAppLinkSDK.registerHandler(path: "client/calendar/event/approval") { appLink in
            guard let from = appLink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            let queryParameters = appLink.url.queryParameters
            guard let calendarId = queryParameters["calendarId"],
                  let key = queryParameters["key"],
                  let originalTimeStr = queryParameters["originalTime"],
                  let originalTime = Int64(originalTimeStr) else {
                assertionFailure("Missing queryParameter")
                return
            }

            CalendarTracerV2.BotMessage.traceClick {
                $0.click("apply_access").target("none")
                $0.content = "add_attendee_fail"
                $0.mergeEventCommonParams(commonParam: CommonParamData(originalTime: originalTimeStr, uid: key))
            }

            let vm = EventAttendeeLimitApproveViewModel(userResolver: container.getCurrentUserResolver(), calendarId: calendarId, key: key, originalTime: originalTime)
            let vc = EventAttendeeLimitApproveViewController(viewModel: vm)
            let navi = LkNavigationController(rootViewController: vc)
            container.getCurrentUserResolver().navigator.present(navi, from: from)

        }

        // 跳转日程签到详情页面
        LarkAppLinkSDK.registerHandler(path: "client/calendar/event/checkin") { applink in
            guard let from = applink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }
            let queryParameters = applink.url.queryParameters
            guard let calendarId = queryParameters["calendarId"],
                  let key = queryParameters["key"],
                  let originalTime = queryParameters["originalTime"],
                  let startTime = queryParameters["startTime"],
                  let tab = queryParameters["tab"] else {
                assertionFailure("Missing queryParameter")
                return
            }

            var defaultTab: EventCheckInInfoViewModel.Tab?
            if tab == "link" { defaultTab = .link } else if tab == "qrcode" { defaultTab = .qrcode } else if tab == "stats" { defaultTab = .stats }

            if let calendarIdInt = Int64(calendarId),
               let originalTimeInt = Int64(originalTime),
               let startTimeInt = Int64(startTime),
               let tabType = defaultTab {

                CalendarTracerV2.NoticeBotCard.traceClick {
                    $0.conf_id = "100001"
                    $0.timestamp = Int64(Date().timeIntervalSince1970)
                    $0.button_num = 1
                }

                let vm = EventCheckInInfoViewModel(userResolver: container.getCurrentUserResolver(), calendarID: calendarIdInt, key: key, originalTime: originalTimeInt, startTime: startTimeInt, defaultTab: tabType)
                let vc = EventCheckInInfoViewController(viewModel: vm, userResolver: container.getCurrentUserResolver())
                let navi = LkNavigationController(rootViewController: vc)
                navi.modalPresentationStyle = .formSheet
                container.getCurrentUserResolver().navigator.present(navi, from: from)
            } else {
                assertionFailure("queryParameter error")
            }

        }

        // 跳转第三方会议帐号管理页面
        LarkAppLinkSDK.registerHandler(path: "/client/calendar/setting/meeting") { appLink in
            guard let from = appLink.context?.from() else {
                assertionFailure("Missing appLink.context.from")
                return
            }

            let userResolver = container.getCurrentUserResolver()
            let viewModel = MeetingAccountManageViewModel(userResolver: userResolver)
            let viewController = MeetingAccountManageViewController(viewModel: viewModel, userResolver: userResolver)

            if Display.pad {
                let naviVC = LkNavigationController(rootViewController: viewController)
                naviVC.update(style: .default)
                naviVC.modalPresentationStyle = .formSheet
                container.getCurrentUserResolver().navigator.present(naviVC, from: from)
            } else {
                container.getCurrentUserResolver().navigator.push(viewController, from: from)
            }
        }
    }

    private func appLinkEditEventErrorHandle(userResolver: UserResolver, from: NavigatorFrom) {
        guard let interface = try? userResolver.resolve(assert: CalendarInterface.self) else {
            assertionFailure("UserResolver resolve CalendarInterface failed")
            return
        }
        let controller = interface.appLinkNewEventController(startTime: nil,
                                                       endTime: nil,
                                                       summary: nil)
        if Display.pad {
            userResolver.navigator.present(controller, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
            return
        }
        userResolver.navigator.present(controller, from: from)
    }

    private func unixStringToDate(unixString: String?) -> Date? {
        guard let unixString = unixString else {
            return nil
        }
        let unixInDouble = Double(unixString)
        guard let unix = unixInDouble else {
            return nil
        }
        return Date(timeIntervalSince1970: unix)
    }
    
    private func applinkToEventEditForAI(queryParameters: [String: String], from: NavigatorFrom, container: Container) {
        guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
            assertionFailure("UserResolver resolve CalendarInterface failed")
            return
        }
        logger.info("deal with applink: eventedit from myai")
        guard let eventToken = queryParameters["token"] else {
            logger.error("applink: eventedit from myai, invaild token")
            UDToast.showFailure(with: I18n.Calendar_G_OopsWrongRetry, on: from.fromViewController?.view ?? UIView())
            return
        }
        
        var isCanceled: Bool = false
        let operation = UDToastOperationConfig(text: I18n.Calendar_Common_Cancel, displayType: .horizontal)
        let config = UDToastConfig(toastType: .loading, text: I18n.Calendar_AI_LoadingEventInfoDots, operation: operation)
        
        from.fromViewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        UDToast.showToast(with: config, on: from.fromViewController?.view ?? UIView(), disableUserInteraction: true, operationCallBack: {_ in
            from.fromViewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            isCanceled = true
        })
        
        interface.appLinkEventEditController(token: eventToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (controller) in
                self?.logger.info("loadEventInfoByKeyForMyAIRequest sucess.")
                if isCanceled { return }
                from.fromViewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                UDToast.removeToast(on: from.fromViewController?.view ?? UIView())
                
                let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
                
                if disableEncrypt {
                    UDToast().showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: from.fromViewController?.view ?? UIView())
                    return
                }
                
                guard let controller = controller else { return }
                container.getCurrentUserResolver().navigator.present(controller, from: from)
                
            }, onError: {[ weak self] (errorCode) in
                self?.logger.error("loadEventInfoByKeyForMyAIRequest error with \(errorCode).")
                if isCanceled { return }
                from.fromViewController?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                UDToast.removeToast(on: from.fromViewController?.view ?? UIView())
                let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
                
                if disableEncrypt {
                    UDToast().showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: from.fromViewController?.view ?? UIView())
                    return
                }
                
                switch errorCode.errorType() {
                case .cachedMyAIEventInfoNotFoundErr:
                    UDToast.showFailure(with: I18n.Calendar_AI_FailLoadEventRetry, on: from.fromViewController?.view ?? UIView())
                case .cachedMyAIEventInfoCreatedErr:
                    UDToast.showWarning(with: I18n.Calendar_AI_EventCreatedNoRepeat, on: from.fromViewController?.view ?? UIView())
                default:
                    UDToast.showFailure(with: I18n.Calendar_G_OopsWrongRetry, on: from.fromViewController?.view ?? UIView())
                    break
                }
            }).disposed(by: self.disposeBag)
    }
    
    private func applinkToEventEdit(queryParameters: [String: String], from: NavigatorFrom, container: Container) {
        guard let interface = try? container.getCurrentUserResolver().resolve(assert: CalendarInterface.self) else {
            assertionFailure("UserResolver resolve CalendarInterface failed")
            return
        }
        
        guard
            let calendarId = queryParameters["calendarId"],
            let key = queryParameters["key"],
            let originalTimeStr = queryParameters["originalTime"],
            let originalTime = Int64(originalTimeStr) else {
                self.appLinkEditEventErrorHandle(userResolver: container.getCurrentUserResolver(), from: from)
                return
        }
        
        let startTimeStr = queryParameters["startTime"]
        let startTime = Int64(startTimeStr ?? "")


        let observable = interface.appLinkEventEditController(calendarId: calendarId,
                                        key: key,
                                        originalTime: originalTime,
                                        startTime: startTime)
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (controller, disableEncrypt) in
                guard let controller = controller else {
                    self?.appLinkEditEventErrorHandle(userResolver: container.getCurrentUserResolver(), from: from)
                    return
                }

                if disableEncrypt {
                    UDToast().showTips(with: I18n.Calendar_NoKeyNoOperate_Toast, on: from.fromViewController?.view ?? UIView())
                } else {
                    container.getCurrentUserResolver().navigator.present(controller, from: from)
                }
            }, onError: { [weak self] (_) in
                let disableEncrypt = SettingService.shared().tenantSetting?.disableEncrypt ?? false
                if disableEncrypt {
                    UDToast().showTips(with: I18n.Calendar_NoKeyNoCreate_Toast, on: from.fromViewController?.view ?? UIView())
                } else {
                    self?.appLinkEditEventErrorHandle(userResolver: container.getCurrentUserResolver(), from: from)
                }
            }).disposed(by: self.disposeBag)
    }

}
