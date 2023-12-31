//
//  MailMessageListController+RenderProcess.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/3/12.
//

import Foundation
import Homeric
import UniverseDesignTheme

protocol MailMessageListRenderProcess: AnyObject {
    /// init时调用
    func onInit(_ threadId: String)
    /// viewDidLoad 时调用
    func onLoad(_ threadId: String)
    /// 开始解析模板
    func onParseHtmlStart(_ threadId: String)
    /// 结束解析模板
    /// - Parameter bodyHtmlLength: 产出的 bodyHtml 大小
    func onParseHtmlEnd(_ mailItem: MailItem, parseResult: MailMessageListTemplateRender.RenderResult, lazyLoadMessage: Bool)
    /// 开始获取 Rust 数据
    func onGetRustDataStart(_ threadId: String)
    /// 获取 Rust 数据结束
    func onGetRustDataEnd(_ threadId: String, messageCount: Int, hasBigMessage: Bool, isFromNet: Bool, isRead: Bool)
    /// 开始渲染 webView
    func onRenderPageStart(_ threadId: String)
    /// JS domReady
    func onDomReady(threadId: String)
    /// webView 完成加载，包括：外部资源下载，如，图片
    func onWebViewFinishNavigation(_ threadId: String)
}

extension MailMessageListController: MailMessageListRenderProcess {

    func checkUnreadPreload(threadId: String) {
        if !isFullReadMessage, let result = accountContext.messageListPreloader.getResultFor(threadID: threadId), let vm = realViewModel[threadId: threadId] {
            vm.mailItem = result.mailItem
            vm.bodyHtml = result.bodyHtml
            if vm.bodyHtml != nil {
                MailLogger.info("MailUnreadPreload use preload for \(threadId)")
                let mailMessageView = MailMessageListViewsPool.getViewFor(threadId: threadId, isFullReadMessage: false, controller: self, provider: accountContext, isFeed: self.isFeedCard)
                MailMessageListController.logStartTime(name: "UnreadPreload HTML")
                isPreloadRendering = true
                var logParams = result.logParams
                var optimizeFeat = ((logParams[MailTracker.OPTIMIZE_FEAT] as? String) ?? "")
                if vm.enableFirstScreenOptimize {
                    optimizeFeat = optimizeFeat + "firstscreen"
                }
                if vm.messageEvent == nil {
                    vm.messageEvent = MailAPMEvent.MessageListLoaded()
                }
                if vm.newMessageTimeEvent == nil {
                    vm.newMessageTimeEvent = MailAPMEvent.NewMessageListLoaded()
                }
                vm.messageEvent?.endParams.appendOrUpdate(MailAPMEventConstant.CommonParam.optimize_feat(optimizeFeat))
                vm.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.isUnreadPreload(1))
                vm.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.from_db(result.fromDB))
                vm.newMessageTimeEvent?.commonParams.appendOrUpdate(MailAPMEvent.NewMessageListLoaded.CommonParam.isThreadInfoReady((result.fromDB != 0)))
                mailMessageView.render(by: vm,
                                       webDelegate: self,
                                       controller: self,
                                       superContainer: nil,
                                       mailActionItemsBlock: { [weak self] in
                                        if let idx = self?.realViewModel.indexOf(threadId: threadId) {
                                            return self?.bottomActionItemsFor(idx) ?? []
                                        }
                                        return []
                                       },
                                       baseURL: self.realViewModel.templateRender.template.baseURL,
                                       delegate: nil)
                unreadPreloadedMailMessageListView = mailMessageView
            } else {
                MailLogger.error("MailUnreadPreload preloaded result html is nil, threadId: \(threadId)")
            }
            _ = accountContext.messageListPreloader.clear(threadID: threadId)
        }
    }

    func onInit(_ threadId: String) {
        MailLogger.info("MailMessageList onInit \(threadId)")
        MailTracker.startRecordMemory(event: Homeric.MAIL_DEV_MESSAGE_LIST_MEMORY_DIFF, params: nil)
        /// apm metric
        markAPMStart(threadID: threadId)

        realViewModel.delegate = self
        messageNavBar.delegate = self
        accountContext.readReceiptManager.delegate = self
        realViewModel.allMailViewModels.forEach { model in
            model.delegate = self
        }

        checkUnreadPreload(threadId: viewModel.threadId)
        if !isPreloadRendering && accountContext.featureManager.open(FeatureKey(fgKey: .preloadMail, openInMailClient: true)) && self.feedCardId.isEmpty {
            isPreloadMail = true
            realViewModel.startLoadBodyHtml(threadID: threadId)
        }
    }

    func onLoad(_ threadId: String) {
        MailLogger.info("MailMessageList onLoad \(threadId)")
        switch UIApplication.shared.applicationState {
        case .background, .inactive:
            viewModel.messageEvent?.endParams.append(MailAPMEventConstant.CommonParam.status_user_leave)
            viewModel.messageEvent?.postEnd()
        @unknown default:
            break
        }
    }

    static func logStartTime(name: String, timeStamp: Int? = nil) {
        #if DEBUG
        let current = timeStamp ?? MailTracker.getCurrentTime()
        if let startTime = MailMessageListController.startClickTime {
            print("debug_mail_init cost \(current - startTime)ms: \(name) , current \(current)")
//            print("debug_mail_init threadInfo \(name) ⚡️: \(Thread.current)" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")")
        } else {
            print("debug_mail_init start name \(name) before startClick, current \(current)")
        }
        #endif
    }

    func onGetRustDataStart(_ threadId: String) {
        MailMessageListController.logStartTime(name: "rust_start")
        MailLogger.info("MailMessageList onGetRustDataStart \(threadId)")
        if let viewModel = realViewModel[threadId: threadId] {
            viewModel.messageEvent?.fetchDataStartTime = Date().timeIntervalSince1970
            viewModel.newMessageTimeEvent?.fetchDataStartTime = Date().timeIntervalSince1970
            viewModel.newMessageTimeEvent?.stage = .get_thread_info
            if let userVisible = viewModel.newMessageTimeEvent?.userVisibleTime {
                let cost = Int(Date().timeIntervalSince1970 - userVisible) * 1000
                viewModel.newMessageTimeEvent?.commonParams.append(MailAPMEvent.NewMessageListLoaded.CommonParam.initUICost(cost))
            }
        }
    }

    func onGetRustDataEnd(_ threadId: String, messageCount: Int, hasBigMessage: Bool, isFromNet: Bool, isRead: Bool) {
        MailMessageListController.logStartTime(name: "rust_end")
        MailLogger.info("MailMessageList onGetRustDataEnd \(threadId)")
        if let viewModel = realViewModel[threadId: threadId] {
            viewModel.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.from_db(isFromNet ? 0 : 1))
            if let lastStageTime = viewModel.messageEvent?.fetchDataStartTime {
                let time = (Date().timeIntervalSince1970 - lastStageTime) * 1000
                viewModel.messageEvent?.commonParams.appendOrUpdate(MailAPMEvent.MessageListLoaded.CommonParam.fetchDataTime(time))
            }
            
            viewModel.newMessageTimeEvent?.stage = .generate_html
            viewModel.newMessageTimeEvent?.commonParams.appendOrUpdate(MailAPMEvent.NewMessageListLoaded.CommonParam.isThreadInfoReady(!isFromNet))
            if let lastStageTime = viewModel.newMessageTimeEvent?.fetchDataStartTime {
                let time = (Date().timeIntervalSince1970 - lastStageTime) * 1000
                viewModel.newMessageTimeEvent?.commonParams.appendOrUpdate(MailAPMEvent.NewMessageListLoaded.CommonParam.getThreadInfoCost(Int(time)))
            }
        }
    }

    func onParseHtmlStart(_ threadId: String) {
        MailMessageListController.logStartTime(name: "onParseHtmlStart")
        MailLogger.info("MailMessageList onParseHtmlStart \(threadId)")
    }

    func onParseHtmlEnd(_ mailItem: MailItem, parseResult: MailMessageListTemplateRender.RenderResult, lazyLoadMessage: Bool) {
        MailMessageListController.logStartTime(name: "onParseHtmlEnd")
        let bodyHtmlLength = parseResult.html.utf8.count / 1024
        let threadId = mailItem.threadId
        MailLogger.info("MailMessageList onParseHtmlEnd \(threadId)")
        threadBodyHtmlLengthMap[mailItem.threadId] = bodyHtmlLength

        var logParams: [String: Any] = [MailTracker.THREAD_BODY_LENGTH: bodyHtmlLength]

        if let index = self.getIndexOf(threadId: threadId) {
            let viewModel = self.dataSource[index]

            var optimizeFeat = ""
            if lazyLoadMessage {
                optimizeFeat += "lazyloadmessage"
            }
            if isPreloadMail {
                optimizeFeat += "preloadmail"
            }
            if viewModel.enableFirstScreenOptimize {
                optimizeFeat += "firstscreen"
            }
            if accountContext.featureManager.open(.scaleOptimize, openInMailClient: true) {
                optimizeFeat += "scaleoptimize"
            }
            if accountContext.featureManager.open(.scalePerformance, openInMailClient: true) {
                optimizeFeat += "scalePerformance"
            }
            let kvStore = MailKVStore(space: .global, mSpace: .global)
            let isContentAlwaysLight = kvStore.value(forKey: "mail_contentSwitch_isLight") ?? false
            if accountContext.featureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)),
                #available(iOS 13.0, *),
               UDThemeManager.getRealUserInterfaceStyle() == .dark,
               !isContentAlwaysLight {
                optimizeFeat += "darkmode"
            }
            logParams[MailTracker.OPTIMIZE_FEAT] = optimizeFeat

            if viewModel.threadId == threadId {
                viewModel.bodyHtml = parseResult.html
                MailTracker.endRecordTimeConsuming(event: Homeric.EMAIL_THREAD_DISPLAY, params: nil, useNewKey: true)
                MailTracker.startRecordTimeConsuming(event: Homeric.EMAIL_THREAD_DISPLAY, params: ["threadid": mailItem.threadId])
                DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { // 这里的只有首次加载会走这里，重复加载不走，与didScroll冲突，只能延时更新标记位
                    self.didRenderDic.updateValue(true, forKey: mailItem.threadId)
                }
            }
        }
        if let optimizeFeat = logParams[MailTracker.OPTIMIZE_FEAT] as? String {
            viewModel.messageEvent?.endParams.appendOrUpdate(MailAPMEventConstant.CommonParam.optimize_feat(optimizeFeat))
        }
    }

    func onRenderPageStart(_ threadId: String) {
        MailMessageListController.logStartTime(name: "onRenderPageStart")
        MailLogger.info("MailMessageList onRenderPageStart \(threadId)")
    }

    /// 渲染时若已经domReady会再次直接调用，不等webView回调。
    /// 同一封邮件可能会被多次调用
    func onDomReady(threadId: String) {
        MailMessageListController.logStartTime(name: "onDomReady")
        unreadPreloadedMailMessageListView = nil
        setupMessageContentView()
        MailLogger.info("MailMessageList onDomReady \(threadId)")
        handleLogOnWebViewLoaded(threadID: threadId)

        asyncRunInMainThread { [weak self] in
            guard let self = self else { return }
            if self.isFullReadMessage {
                self.hideLoading()
            }

            if threadId == self.viewModel.threadId {
                self.currentWebViewDidDomReady()
                if let mailItem = self.viewModel.mailItem {
                    self.setupThreadActions(mailItem: mailItem)
                }
            }
        }
    }

    func onWebViewFinishNavigation(_ threadId: String) {
        MailMessageListController.logStartTime(name: "onWebViewFinishNavigation")
        MailLogger.info("MailMessageList onWebViewFinishNavigation \(threadId)")
        handleLogOnWebViewLoaded(threadID: threadId)

        if isFullReadMessage {
            hideLoading()
        }
    }

    /// domReady 和 webViewFinishNavigation 时都会被调用，处理打点逻辑
    /// 里面的调用请做好被多次调用的处理
    private func handleLogOnWebViewLoaded(threadID: String) {
        domReadyMonitor.onDomReady(threadID: threadID)
        MailTracker.endRecordMemory(event: Homeric.MAIL_DEV_MESSAGE_LIST_MEMORY_DIFF, params: nil)
        if let pageViewModel = realViewModel[threadId: threadID], let messageEvent = pageViewModel.messageEvent {
            messageEvent.endParams.append(MailAPMEventConstant.CommonParam.status_success)
            messageEvent.postEnd()
        }
    }
}
