//
//  MailMessageListController+Apm.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/10/12.
//

import Foundation

extension MailMessageListPageViewModel {
    private static var messageEventKey: Void?
    private static var messageTimeEventKey: Void?

    var messageEvent: MailAPMEvent.MessageListLoaded? {
        get {
            if let temp = objc_getAssociatedObject(self, &MailMessageListPageViewModel.messageEventKey) as? MailAPMEvent.MessageListLoaded {
                if temp.status == .isInvalid {
                    return nil
                } else {
                    return temp
                }
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &MailMessageListPageViewModel.messageEventKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var newMessageTimeEvent: MailAPMEvent.NewMessageListLoaded? {
        get {
            if let temp = objc_getAssociatedObject(self, &MailMessageListPageViewModel.messageTimeEventKey) as? MailAPMEvent.NewMessageListLoaded {
                if temp.status == .isInvalid {
                    return nil
                } else {
                    return temp
                }
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &MailMessageListPageViewModel.messageTimeEventKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: apm
extension MailMessageListController {
    private typealias CommonParam = MailAPMEvent.MessageListLoaded.CommonParam
    private typealias TimeCommonParam = MailAPMEvent.NewMessageListLoaded.CommonParam

    func markAPMStart(threadID: String) {
        let event = realViewModel[threadId: threadID]?.messageEvent ?? MailAPMEvent.MessageListLoaded()
        let timeEvent = realViewModel[threadId: threadID]?.newMessageTimeEvent ?? MailAPMEvent.NewMessageListLoaded()
        let source: CommonParam
        if let fromString = statInfo.fromString {
            source = CommonParam.sence_other(fromString)
        } else {
            switch statInfo.from {
            case .notification:
                source = CommonParam.sence_notification
            case .search:
                source = CommonParam.sence_search
            case .chat:
                source = CommonParam.sence_forward
            case .threadList:
                source = CommonParam.sence_select_thread
            case .chatSideBar, .imColla, .emlPreview, .emailReview, .imFile, .bot, .deleteMail, .unknown:
                source = CommonParam.sence_other(statInfo.from.rawValue)
            case .feed:
                source = CommonParam.sence_other(statInfo.from.rawValue)
            case .other:
                source = CommonParam.sence_other(statInfo.from.rawValue)
                mailAssertionFailure("readMail from not found")
            }
        }

        let time = (Date().timeIntervalSince1970 - statInfo.startTime) * 1000
        event.actualStartTime = statInfo.startTime
        event.commonParams.appendOrUpdate(CommonParam.clickToInitTime(time))
        timeEvent.actualStartTime = statInfo.startTime

        event.commonParams.append(source)
        event.isFirstScreen = true
        event.markPostStart()
        apmHolder[MailAPMEvent.MessageListLoaded.self] = event

        timeEvent.commonParams.append(TimeCommonParam.isFirstIndex(true))
        timeEvent.commonParams.append(MailAPMEventConstant.CommonParam.customKeyValue(key: "from", value: source.value))
        timeEvent.markPostStart()
        apmHolder[MailAPMEvent.NewMessageListLoaded.self] = timeEvent

        // 未读预加载的已完成了rustData拉取，需要补上打点值
        if unreadPreloadedMailMessageListView != nil, let preloadResult = accountContext.messageListPreloader.getResultFor(threadID: threadID) {
            event.commonParams.appendOrUpdate(CommonParam.from_db(preloadResult.fromDB))
            timeEvent.commonParams.appendOrUpdate(TimeCommonParam.isThreadInfoReady((preloadResult.fromDB != 0)))
        }

        /// 处理首屏加载事件
        if let initViewModel = realViewModel[threadId: threadID] {
            initViewModel.messageEvent = event
            initViewModel.newMessageTimeEvent = timeEvent
            // new event
            var mailShowType = ""
            if self.isFeedCard {
                mailShowType = "im_feed"
            } else if statInfo.from == .bot {
                mailShowType = "mail_bot_window"
            }
            let newEvent = NewCoreEvent(event: .email_message_list_view)
            newEvent.params = ["label_item": statInfo.newCoreEventLabelItem,
                               "mail_display_type": Store.settingData.threadDisplayType(),
                               "thread_id": initViewModel.threadId,
                               "mail_service_type": Store.settingData.getMailAccountListType(),
                               "mail_show_type": mailShowType,
                               "is_trash_or_spam_list": statInfo.isTrashOrSpamList]
            newEvent.post()
            if fromLabel == Mail_LabelId_Stranger {
                MailTracker.log(event: "email_stranger_message_list_view", params: ["label_item": Mail_LabelId_Stranger])
            }
        }
    }

    func viewModelMailItemDidChange(viewModel: MailMessageListPageViewModel) {
        if let event = viewModel.messageEvent {
            updateMessageLoadParam(viewModel: viewModel, event: event, timeEvent: viewModel.newMessageTimeEvent)
        }
    }

    func updateMessageLoadParam(viewModel: MailMessageListPageViewModel?, event: MailAPMEvent.MessageListLoaded, timeEvent: MailAPMEvent.NewMessageListLoaded?) {
        let isFirstRead = Self.isFirstRead ? 1 : 0
        event.commonParams.appendOrUpdate(CommonParam.isFirstRead(isFirstRead))
        /// 现在读信预加载仅点击那封会使用，后续使用的是左右滑预加载
        event.commonParams.appendOrUpdate(CommonParam.isUnreadPreload(0))
        let isRead = viewModel?.mailItem?.isRead == true
        event.commonParams.appendOrUpdate(CommonParam.isRead(isRead ? 1 : 0))
        let messageCount = viewModel?.mailItem?.messageItems.count ?? 0
        event.commonParams.appendOrUpdate(CommonParam.messageCount(messageCount))
        timeEvent?.commonParams.appendOrUpdate(TimeCommonParam.messageCount(messageCount))
        let msgIds = viewModel?.mailItem?.messageItems.reduce(into: "") { (result, item) in
            result += item.message.id + ";"
        } ?? ""
        let isFirstIndex = realViewModel[initIndex]?.threadId == viewModel?.threadId
        event.commonParams.appendOrUpdate(CommonParam.messageIDs(msgIds))
        timeEvent?.commonParams.append(TimeCommonParam.isFirstIndex(isFirstIndex))
        timeEvent?.commonParams.appendOrUpdate(TimeCommonParam.threadID(viewModel?.mailItem?.threadId ?? ""))
        timeEvent?.commonParams.appendOrUpdate(TimeCommonParam.isLargeMail(viewModel?.isFullReadMessage == true))
        let isConversationMode = Store.settingData.getCachedCurrentSetting()?.enableConversationMode == true ? 1 : 0
        event.commonParams.appendOrUpdate(CommonParam.isConversation(isConversationMode))
        let isNewAtBottom = Store.settingData.getCachedCurrentSetting()?.mobileMessageDisplayRankMode == true ? 0 : 1
        event.commonParams.appendOrUpdate(CommonParam.isNewAtBottom(isNewAtBottom))
        event.commonParams.appendOrUpdate(CommonParam.logVersion(1))
    }
}

extension MailMessageListController {
    func checkBlank() {
        // 读信的准确性判断还有待进一步研究
        func judgeAccuracy(isBlank: Int,
                           domReady: Int,
                           fcpTime: Int) {
            // 对异常数据添加风神上报，方便拉日志oncall
            if isBlank == 1 && domReady == 1 {
                let event = MailAPMEventSingle.BlankCheck()
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.page_key("read"))
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.is_blank(isBlank))
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.dom_ready(domReady))
                event.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
                event.endParams.append(MailAPMEventSingle.BlankCheck.EndParam.fcp_time(fcpTime))
                event.markPostStart()
                event.postEnd()
            }
        }

        guard accountContext.featureManager.open(.mailCheckBlank) else { return }
        guard let window = self.view.window else { return }
        guard let webView = self.webView else { return }
        let stayTime = Int(Date().timeIntervalSince(self.initDate ?? Date()) * 1000)
        var param = BlankCheckParam(backgroundColors: [UIColor.ud.bgBase, UIColor.ud.bgBody])
        if viewModel.enableFirstScreenOptimize &&
            webView.scrollView.contentOffset.y < 1 &&
            webView.scrollView.contentOffset.y > -1 {
            if let titleView = self.currentPageCell?.mailMessageListView?.titleView,
               let pageCell = self.currentPageCell,
                let rect = titleView.superview?.convert(titleView.frame, to: pageCell) {
                param.offsetY = Int(rect.origin.y + rect.size.height) + 1
            }
        }
        let dom_ready = self.currentPageCell?.mailMessageListView?.isDomReady ?? false
        let threadId = self.viewModel.threadId
        webView.mailCheckBlank(param: param, completionHandler: { res in
            ///不支持 PerformancePaintTiming 接口返回 -2；没有paint回调，返回-1
            let checkFCPScript = "if (typeof PerformancePaintTiming !== 'undefined') { (window.performance.getEntriesByType('paint').length > 0 ? window.performance.getEntriesByType('paint')[0].startTime : -1) } else { -2 }"
            webView.evaluateJavaScript(checkFCPScript) { value, error in
                let dummyFcpTime = -999
                let fcpTime = (value as? Int) ?? dummyFcpTime
                if let error = error {
                    MailLogger.error("getFCP error \(error)")
                }
                let domReady = dom_ready ? 1 : 0
                var logParams: [String: Any] = ["page_key": "read",
                                                "thread_id": threadId,
                                                "stay_time": stayTime,
                                                "dom_ready": domReady,
                                                "fcp_time": fcpTime]
                let isBlank: Int

                switch res {
                case .failure(let err) :
                    guard let err:BlankCheckError  = err as? BlankCheckError else {
                        return
                    }
                    isBlank = (err == BlankCheckError.ImageSizeInvaild) ? 1 : 0
                    logParams.merge(other: ["error_des": err.description,
                                            "is_blank": isBlank])
                case .success(let res):
                    isBlank = res.is_blank
                    logParams.merge(other: ["error_des": "",
                                            "cut_screen_time": res.cut_screen_time,
                                            "total_time": res.total_time,
                                            "is_blank": res.is_blank,
                                            "blank_rate": res.blank_rate,
                                            "clear_rate": res.clear_rate])
                }
                judgeAccuracy(isBlank: isBlank, domReady: domReady, fcpTime: fcpTime)
                MailTracker.log(event: "email_blank_check_dev", params: logParams)
                MailLogger.info("email_blank_check_dev \(logParams)")

            }
        })
    }
}
