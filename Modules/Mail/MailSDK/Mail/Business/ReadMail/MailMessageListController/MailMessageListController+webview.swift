//
//  MailMessageListController+webview.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/3/19.
//

import Foundation
import UIKit
import WebKit
import Homeric
import LarkLocalizations
import EENavigator
import LarkAppLinkSDK
import RustPB
import RxSwift

// MARK: - WKNavigationDelegate
extension MailMessageListController {
    func _webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        MailMessageListController.logger.info("message list webcontent_process_terminate")
        if let mailMessageListView = webView.superview as? MailMessageListView,
           let webView = webView as? (WKWebView & MailBaseWebViewAble) {
            var reloadIndexPath: IndexPath?
            var t_id: String?
            // identifier 等于空，证明是pool里面预加载的webview
            var isPreload = webView.identifier == nil
            if !isPreload, let threadId = webView.identifier {
                t_id = threadId
                // 有id的场景，若该cell不存在，仍然是预加载的webview
                isPreload = getPageCellOf(threadId: threadId) == nil
                if !isPreload {
                    reloadIndexPath = getIndexPathOf(threadId: threadId)
                }
            }
            mailMessageListView.trackWebViewProcessTerminate(isPreload: isPreload)

            webView.identifier = nil

            if let reloadIndexPath = reloadIndexPath, let t_id = t_id {
                let terminatedCount = (MailMessageListViewsPool.threadTerminatedCountDict[t_id] ?? 0) + 1
                MailMessageListViewsPool.threadTerminatedCountDict[t_id] = terminatedCount

                MailMessageListController.logger.info("message list webcontent_process_terminate reload \(t_id ?? "") all: \(terminatedRetryThreads)")
                terminatedRetryThreads.insert(t_id)
                // 只对不是预加载的进行reload
                // 避免预加载的重新加载后，还是会被杀掉
                collectionView?.reloadItems(at: [reloadIndexPath])
            } else {
                MailMessageListController.logger.info("message list webcontent_process_terminate not reload")
            }
        }
    }

    func _webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MailMessageListController.logger.info("message list render template start")
    }
    func _webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let pageWebView = webView as? (WKWebView & MailBaseWebViewAble),
              let pageCell = pageWebView.weakRef.superContainer as? MailMessageListPageCell,
              let threadId = pageWebView.identifier else {
            // 预加载的webView加载完成，会找不到当前cell
            return
        }
        onWebViewFinishNavigation(threadId)
        MailMessageListController.logger.info("message list render template finish \(mailItem.threadId)")

        pageCell.webViewLoadComplete()
        if threadId == viewModel.threadId {
            currentWebViewDidLoadFinish()
        }
        loadingView.isHidden = true
    }

    func _webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //        MailMessageListController.logger.info("navigationAction = \(navigationAction), request = \(String(describing: navigationAction.request.url))")

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        var param:[String: Any] = [:]
        if MailMessageListViewsPool.fpsOpt {
            param = MailMessageListViewsPool.decidePolicyParamDic[url.absoluteString] ?? [:]
            if param.isEmpty {
                param = accountContext.navigator.response(for: url, context: [:], test: true).parameters
                MailMessageListViewsPool.decidePolicyParamDic[url.absoluteString] = param
            }
        } else {
            param = accountContext.navigator.response(for: url, context: [:], test: true).parameters
        }
        let canOpenInDocs = param["_canOpenInDocs"] as? Bool
        let canOpenInMicroApp: Bool = {
            return ((param["_canOpenInMicroApp"] as? Bool == true) ||
                        (param[AppLinkAssembly.KEY_CAN_OPEN_APP_LINK] as? Bool == true))
        }()
        // 如果是welcomeletter中的链接， 另外打点
        if url.absoluteString.hasSuffix(MailTracker.WelcomeLetterLinkSuffix) {
            MailTracker.log(event: Homeric.EMAIL_WELCOMELETTER_LINK_CLICK, params: nil)
        }
        if canOpenInDocs == true {
            resetToPortrait()
            DispatchQueue.main.async {
                self.navigator?.push(url, from: self)
                decisionHandler(.cancel)
            }
        } else if canOpenInMicroApp {
            navigator?.push(url, context: ["from": "mail"], from: self)
            decisionHandler(.cancel)
        } else if url.absoluteString.hasPrefix("file://") {
            // swiftlint:disable line_length
            // 譬如www.baidu.com这种场景
            // file:///Users/tanzhiyuan/Library/Developer/CoreSimulator/Devices/E7D6B9D3-7069-4083-A550-9C2FA74784D3/data/Containers/Bundle/Application/141D0A3B-51E0-438D-B3AE-EBA9A650FD29/Lark.app/MailSDK.bundle/www.baidu.com
            // swiftlint:enable line_length
            let urlstring = url.absoluteString as NSString
            let components = urlstring.components(separatedBy: "/")
            let baseURLLastComponent = realViewModel.templateRender.template.baseURL?.path.components(separatedBy: "/").last
            if components.count > 1
                && components[components.count - 2] == baseURLLastComponent
                && !components[components.count - 1].isEmpty
                // 页面内 hash 跳转，不用 native 跳转
                && !components[components.count - 1].starts(with: "#") {
                decisionHandler(.cancel)
                if let url = try? URL.forceCreateURL(string: "http://\(components.last ?? "")") {
                    UIApplication.shared.open(url)
                }
            } else {
                decisionHandler(.allow)
            }
        } else if url.absoluteString.contains("?source=larkmail_largefile") {
            if UIApplication.shared.canOpenURL(url) {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
            } else {
                decisionHandler(.allow)
            }
        } else if url.absoluteString.hasPrefix("http://") || url.absoluteString.hasPrefix("https://") {
            MailTracker.log(event: Homeric.LINK_CLICKED, params: ["scene": "email", "location": "email_body"])
            navigator?.push(url, from: self)
            decisionHandler(.cancel)
        } else if url.absoluteString.hasPrefix("mailto:") && url.absoluteString.contains("?source=larkmail_at") && !Store.settingData.mailClient {
            // @人
            decisionHandler(.cancel)
            let atInfos = url.absoluteString.replacingOccurrences(of: "?source=larkmail_at", with: "")
                .replacingOccurrences(of: "mailto:", with: "")
                .split(separator: "?")
            let emailAddress = atInfos.first
            let name = String(atInfos.last ?? emailAddress ?? "").removingPercentEncoding ?? ""
            var urlComponents: NSURLComponents?
            urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: false)

            // url中参数的key value
            var parameter: [AnyHashable: Any] = [:]
            for item in urlComponents?.queryItems ?? [] {
                let item = item as NSURLQueryItem
                parameter[item.name] = item.value
            }
            handleAtNavigate(name: name, emailAddress: String(emailAddress ?? ""))
        } else if url.absoluteString.hasPrefix("mailto:"), let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: accountContext,
                                                                                                                          action: .fromAddress,
                                                                                                                          labelId: Mail_LabelId_Inbox,
                                                                                                                          statInfo: MailSendStatInfo(from: .routerPullUp, newCoreEventLabelItem: statInfo.newCoreEventLabelItem),
                                                                                                                          trackerSourceType: .mailTo,
                                                                                                                          sendToAddress: url.absoluteString) {
            // 发信，确保有mailTab

            navigator?.present(vc, from: self)
            decisionHandler(.cancel)
        } else {
            if UIApplication.shared.canOpenURL(url) {
                decisionHandler(.cancel)
                UIApplication.shared.open(url)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    /// 处理点击@的跳转
    private func handleAtNavigate(name: String, emailAddress: String) {
        guard !Store.settingData.mailClient else { return }
        if self.addressNameFg {
            newToProfile(name: name, emailAddress: emailAddress)
        } else {
            oldToProfile(name: name, emailAddress: emailAddress)
        }
    }
    private func newToProfile(name: String, emailAddress: String) {
        MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
        
        var item = AddressRequestItem()
        item.address = emailAddress
        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
            guard let `self` = self else { return }
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Normal_Success, on: self.view)
            if let respItem = MailAddressNameResponse.addressNameList.first,
               !respItem.larkEntityID.isEmpty,
                respItem.larkEntityID != "0",
                !respItem.tenantID.isEmpty,
                respItem.tenantID != "0" {
                self.accountContext.provider.routerProvider?.openUserProfile(userId: respItem.larkEntityID, fromVC: self)
            } else {
                let accountId = Store.settingData.currentAccount.value?.mailAccountID ?? ""
                self.accountContext.provider.routerProvider?.openNameCard(accountId: accountId, address: emailAddress, name: name, fromVC: self, callBack: { _ in })
            }
            }, onError: { (error) in
                MailLogger.error("token getAddressNames resp error \(error)")
            }).disposed(by: disposeBag)
    }
    private func oldToProfile(name: String, emailAddress: String) {
            MailRoundedHUD.showLoading(with: BundleI18n.MailSDK.Mail_Normal_Loading, on: self.view, disableUserInteraction: false)
            searchProvider = MailSendDataSource()
            searchProvider.searchBegin = 0
            searchProvider.searchKey = name
            searchProvider.searchSession.renewSession()
            _ = searchProvider.atRecommandListWith(key: name, begin: searchProvider.searchBegin, end: searchProvider.searchBegin + searchProvider.searchPageSize)
                .observeOn(MainScheduler.instance).subscribe(
                    onNext: { [weak self] (list, _) in
                        guard let self = self else {
                            return
                        }
                        guard let target = list.first(where: { $0.address == emailAddress }), target.larkID != nil else {
                            // 没找到对应联系人，跳转到发信页
                            if let vc = MailSendController.checkMailTab_makeSendNavController(accountContext: self.accountContext,
                                  action: .fromAddress,
                                  labelId: Mail_LabelId_Inbox,
                                  statInfo: MailSendStatInfo(from: .messageHandleAt, newCoreEventLabelItem: "none"),
                                  trackerSourceType: .mailTo,
                                  sendToAddress: emailAddress) {
                                self.navigator?.present(vc, from: self)
                            } else {
                                var urlString = emailAddress
                                if !urlString.hasPrefix("mailto:") {
                                    urlString = "mailto:" + emailAddress
                                }
                                guard let url = URL.init(string: urlString) else { return }
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                            return
                        }
                        let array = list.map { (item) -> MailSendAddressModel in
                            var newItem = MailSendAddressModel(avatar: item.avatar,
                                                               name: item.name, searchName: item.searchName, address: item.address, subtitle: item.subtitle,
                                                               titleHitTerms: item.titleHitTerms, emailHitTerms: item.emailHitTerms, departmentHitTerms: item.departmentHitTerms)
                            newItem.type = item.type
                            newItem.larkID = item.larkID
                            newItem.tenantID = item.tenantID
                            newItem.displayName = item.displayName
                            return newItem
                        }
                        if let targetUserID = array.first(where: { $0.address == emailAddress })?.larkID {
                            // 跳转Podfile
                            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Normal_Success, on: self.view)
                            self.accountContext.provider.routerProvider?.openUserProfile(userId: targetUserID, fromVC: self)
                        }
                    },
                    onError: { (_) in
                        MailRoundedHUD.remove(on: self.view)
                    },
                    onCompleted: { [weak self] in
                        guard let `self` = self else { return }
                        MailRoundedHUD.remove(on: self.view)
                    }).disposed(by: disposeBag)
        }
}

// MARK: - WKUIDelegate
extension MailMessageListController {
    func _webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }

    func _webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        //        guard let url = elementInfo.linkURL else { return UIViewController() }
        //        let web = WebViewController.init(url)
        return nil
    }
    @available(iOS 13.0, *)
    func _webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        completionHandler(nil)
    }
}
