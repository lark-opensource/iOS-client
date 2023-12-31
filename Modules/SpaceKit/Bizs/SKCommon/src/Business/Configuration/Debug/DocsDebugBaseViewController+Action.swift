//
//  DocsDebugBaseViewController+Action.swift
//  Docs
//
//  Created by nine on 2018/11/7.
//  Copyright © 2018 Bytedance. All rights reserved.
//

import Foundation
import SSZipArchive
import SwiftyJSON
import SKUIKit
import EENavigator
import UniverseDesignToast
import UniverseDesignTheme
import UniverseDesignActionPanel
import SKFoundation
import SKInfra
import WebKit

public extension DocsDebugBaseViewController {

    func showCustomOfflineResourceAlert(_ sender: UISwitch) {
        let isOpen = sender.isOn
        if !isOpen {
            SpecialVersionResourceService.updateVersion(nil, type: .webInfo)
            let alert = UIAlertController(title: "已恢复为原版本\(GeckoPackageManager.shared.insideBundleVersion(type: .webInfo))", message: "请重新打开app", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { (_) in
                // 这里不用 SpaceAssertionFailure 是因为必须要退出
                assertionFailure() // 让app退出，不用exit()是因为exit会产生异常记录，且此功能只在debug模式下生效
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        let curVersion: String = DocsSDK.offlineResourceVersion() ?? ""
        let alert = UIAlertController(title: "指定Docs资源包版本", message: "当前资源包版本：\(curVersion)", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .default, handler: { [weak alert](_) in
            alert?.dismiss(animated: true, completion: nil)
        }))

        alert.addTextField { textField -> Void in
            textField.text = curVersion
            textField.keyboardType = .numbersAndPunctuation
            textField.accessibilityIdentifier = "textField_资源版本"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { [weak alert, weak self] (_) in
            guard let self = self else { return }
            guard let version = alert?.textFields?.first?.text, !version.isEmpty else {
                UDToast.docs.showMessage("输入版本号为空, 或不能为当前正在使用的版本号", on: self.view, msgType: .failure)
                return
            }
            SpecialVersionResourceService.setCustomResource(.webInfo, version: "\(version)", msgOnView: self.view) { success in
                sender.isOn = success
                if success == true {
                    // 这里不用 SpaceAssertionFailure 是因为必须要退出
                    assertionFailure() // 让app退出，不用exit()是因为exit会产生异常记录，且此功能只在debug模式下生效
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }

#if BETA || ALPHA || DEBUG
    func showCustomJavascriptResourceAlert(_ sender: UISwitch) {
        let isOpen = sender.isOn
        if !isOpen {
            
            // 关闭操作
            let alert = UIAlertController(title: "已关闭指定js", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { (_) in
                
            }))
            CCMKeyValue.globalUserDefault.set(false, forKey: "UseThirdPartyJavascript")
            present(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "指定要注入的javascript的url", message: nil, preferredStyle: .alert)
        alert.addTextField { textField -> Void in
            textField.placeholder = "请输入"
            textField.keyboardType = .default
            textField.accessibilityIdentifier = "javascript_url"
        }
        alert.addAction(UIAlertAction(title: "确定", style: .destructive, handler: { [weak alert] (_) in
            if let urlString = alert?.textFields?.first?.text {
                // 下载js
                if let url = URL(string: urlString) {
                    UDToast.showLoading(with: "正在下载要注入的js", on: self.view, disableUserInteraction: false)
                    do {
                        UDToast.removeToast(on: self.view.window ?? self.view)
                        let data = try Data.read(from: SKFilePath(absUrl: url))
                        let path = SKFilePath.globalSandboxWithDocument.appendingRelativePath("inject_javascript.js")
                        try data.write(to: path)
                        UDToast.showSuccess(with: "下载js成功", on: self.view.window ?? self.view)
                        CCMKeyValue.globalUserDefault.set(true, forKey: "UseThirdPartyJavascript")
                        CCMKeyValue.globalUserDefault.set(path.pathString, forKey: "JavascriptPath")
                    } catch {
                        UDToast.removeToast(on: self.view.window ?? self.view)
                        UDToast.showFailure(with: "下载js失败", on: self.view.window ?? self.view)
                        sender.isOn = false
                        print("failed")
                    }
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func showAgentToFrontendAlert() {
        let alert = UIAlertController(title: "前端代理", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = OpenAPI.docs.frontendHost
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            if let agent = alert?.textFields?.first?.text {
                OpenAPI.docs.isSetAgentToFrontend = true
                OpenAPI.docs.frontendHost = agent
            } else {
                OpenAPI.docs.isSetAgentToFrontend = false
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    func showRemoteRNAddressAlert() {
        let alert = UIAlertController(title: "RN代理", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = OpenAPI.docs.frontendHost
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            if let agent = alert?.textFields?.first?.text {
                OpenAPI.docs.remoteRNAddress = true
                OpenAPI.docs.RNHost = agent
            } else {
                OpenAPI.docs.remoteRNAddress = false
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    func showCleanDriveCacheAlert() {
        let alert = UIAlertController(title: "清除 Drive 缓存", message: "确认清除所有 Drive 文件缓存？", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .destructive) { (_) in
            DocsContainer.shared.resolve(DriveCacheServiceBase.self)?.deleteAll(completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    func showCleanWikiDBAlert() {
        let alert = UIAlertController(title: "清除 Wiki 数据库", message: "确认清除当前账号的 Wiki 数据库？", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "OK", style: .destructive) { (_) in
            DocsContainer.shared.resolve(SKCommonDependency.self)!.resetWikiDB()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showRemoteFileAddressAlert() {
#if DEBUG
        let alert = UIAlertController(title: "文件地址", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            if let url = ClippingDocDebug.url {
                textField.text = url.absoluteString
            }
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            if let path = alert?.textFields?.first?.text, let url = URL(string: path) {
                ClippingDocDebug.save(url)
            }
        }))
        present(alert, animated: true, completion: nil)
#endif
    }

    func autoTestOpenDrive(isOn: Bool) {
        #if DEBUG
        if isOn {
            UDToast.showSuccess(with: "开始测试...", on: self.view.window ?? self.view)
            driveAutoPerformanceTest.start()
        } else {
            driveAutoPerformanceTest.stop()
        }
        #endif
    }

    func clearLocalDomainConfig() {
        DomainConfig.clearLocalGlobalConfig()
    }
    
    func makeWebViewUnresponsive() {
        NotificationCenter.default.post(name: NSNotification.Name.SimulateWebViewUnresponsive, object: nil)
    }

#endif
}
#if BETA || ALPHA || DEBUG
//处理重复打开文档事件
extension DocsDebugBaseViewController {
    func didSelectAutoOpenDocsTypeList(indexPath: IndexPath) {
        let docsTypePicker = DocsDebugDocsTypePickerController(autoOpenDocsManager: autoOpenDocsMgr)
        docsTypePicker.preferredContentSize = CGSize(width: 200, height: 150)
        docsTypePicker.modalPresentationStyle = .popover
        let popoverController = docsTypePicker.popoverPresentationController
        popoverController?.sourceView = debugTableView.cellForRow(at: indexPath)?.detailTextLabel
        popoverController?.delegate = self
        present(docsTypePicker, animated: true, completion: nil)
    }

    func beginAutoOpenDocs() {
//        #if DEBUG
        autoOpenDocsMgr.beginAutoOpenDocs()
//        #endif
    }

    func showLynxPreloadServerAlert() {
        let alert = UIAlertController(title: "Lynx preload JS URL", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = CCMKeyValue.globalUserDefault.string(forKey: "Debug-LynxPreloadServer")
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            if let agent = alert?.textFields?.first?.text {
                CCMKeyValue.globalUserDefault.set(agent, forKey: "Debug-LynxPreloadServer")
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    func showLynxSheetServerAlert() {
        let alert = UIAlertController(title: "Lynx sheet JS URL", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = CCMKeyValue.globalUserDefault.string(forKey: "Debug-LynxSheetServer")
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            if let agent = alert?.textFields?.first?.text {
                CCMKeyValue.globalUserDefault.set(agent, forKey: "Debug-LynxSheetServer")
            }
        }))
        present(alert, animated: true, completion: nil)
    }
}
extension DocsDebugBaseViewController {
    func showLynxSourceURLAlert() {
        func isValid(_ str: String) -> Bool {
            do {
                let pattern = """
^(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])\
\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])\
\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])\
\\.(\\d|[1-9]\\d|1\\d{2}|2[0-4]\\d|25[0-5])\
:([0-9]|[1-9]\\d|[1-9]\\d{2}|[1-9]\\d{3}|[1-5]\
\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5])$
"""
                let regex = try NSRegularExpression(
                    pattern: pattern
                )
                let matches = regex.matches(in: str, options: [], range: NSRange(location: 0, length: str.count))
                return matches.count == 1
            } catch {
                return false
            }
        }
        if let proxyStr = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lynxTemplateSourceURL), !isValid(proxyStr) {
            CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.lynxTemplateSourceURL)
        }
        let alert = UIAlertController(title: "Lynx Proxy", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "ip:port"
            textField.text = CCMKeyValue.globalUserDefault.string(forKey: UserDefaultKeys.lynxTemplateSourceURL)
        }
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert] (_) in
            guard let proxyStr = alert?.textFields?.first?.text, !proxyStr.isEmpty else {
                CCMKeyValue.globalUserDefault.set(nil, forKey: UserDefaultKeys.lynxTemplateSourceURL)
                return
            }
            guard isValid(proxyStr) else {
                UDToast.showFailure(with: "格式有误", on: self.view.window ?? self.view)
                return
            }
            CCMKeyValue.globalUserDefault.set(proxyStr, forKey: UserDefaultKeys.lynxTemplateSourceURL)
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension DocsDebugBaseViewController {
    func deleteDocsCipher() {
//        UDToast.showLoading(with: "请求中...", on: self.view, disableUserInteraction: false)
//        UDToast.removeToast(on: self.view.window ?? self.view)
//        UDToast.showFailure(with: "删除失败", on: self.view)
        DispatchQueue.global().async {
            NotificationCenter.default.post(name: .Docs.cipherChanged, object: nil)
        }
        UDToast.showSuccess(with: "删除成功", on: self.view)
    }
}
extension DocsDebugBaseViewController {
    func showLynxDevToolAlert() {
        let alert = UIAlertController(title: "Lynx Dev", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "👌ok", style: .destructive, handler: { [weak alert, weak self] (_) in
            guard let self = self else { return }
            guard let text = alert?.textFields?.first?.text else { return }
            guard let url = self.extractLynxDevtoolURL(from: text) else {
                UDToast.showFailure(with: "格式有误", on: self.view.window ?? self.view)
                return
            }
            Navigator.shared.open(url, from: self)
        }))
        present(alert, animated: true, completion: nil)
    }
    func extractLynxDevtoolURL(from text: String) -> URL? {
        do {
            let pattern = "\".*\""
            let regex = try NSRegularExpression(pattern: pattern)
            guard let match = regex.matches(
                in: text, options: [],
                range: NSRange(text.startIndex..., in: text)
            ).first, match.range.length > 3 else {
                return nil
            }
            guard let range = Range(NSRange(
                location: match.range.location + 1,
                length: match.range.length - 2
            ), in: text) else {
                return nil
            }
            let urlStr = String(text[range])
            return URL(string: urlStr)
        } catch {
            return nil
        }
    }
    func showCustomLynxPkgAlert(_ sender: UISwitch) {
        let isOpen = sender.isOn
        if !isOpen {
            LynxCustomPkgManager.shared.shouldUseCustomPkg = false
            askExit()
            return
        }
        let alert = UIAlertController(title: nil, message: "Enter Version Of Docs Lynx Pkg", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "cancel", style: .default, handler: { [weak alert](_) in
            sender.isOn = false
            alert?.dismiss(animated: true, completion: nil)
        }))

        alert.addTextField { textField -> Void in
            textField.keyboardType = .numbersAndPunctuation
            textField.accessibilityIdentifier = "textField_lynx_pkg_version"
            textField.text = LynxCustomPkgManager.shared.versionOfCurrentSavedCustomPkg(with: LynxEnvManager.channel)
        }
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { [weak alert, weak self] (_) in
            guard let self = self else { return }
            guard let version = alert?.textFields?.first?.text, !version.isEmpty else {
                UDToast.docs.showMessage("version is empty", on: self.view, msgType: .failure)
                return
            }
            let loading = UDToast.showLoading(with: "downloading", on: self.view)
            LynxCustomPkgManager.shared.downloadCustomPkg("\(version)") { [weak self] (success, error) in
                guard let self = self else { return }
                loading.remove()
                sender.isOn = success
                if success {
                    LynxCustomPkgManager.shared.shouldUseCustomPkg = true
                    self.askExit()
                } else if let error = error {
                    UDToast.docs.showMessage(error, on: self.view, msgType: .failure)
                }
            }
        }))
        present(alert, animated: true, completion: nil)
    }
    private func askExit() {
        let alert = UIAlertController(title: nil, message: "Need Reopen App", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: { (_) in
            // 这里不用 SpaceAssertionFailure 是因为必须要退出
            assertionFailure() // 让app退出，不用exit()是因为exit会产生异常记录，且此功能只在debug模式下生效
        }))
        present(alert, animated: true, completion: nil)
    }
    func showLynxPkgInfo() {
        let info = SKTemplateInfoRecorder.shared.currentUsingResourceInfo()
        let alert = UIAlertController(title: nil, message: info, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    func killAllWebViewProcess() {
        guard let webview =  DocsContainer.shared.resolve(SKCommonDependency.self)?.allDocsWebViews.first else {
            return
        }
        let hasKillNet = webview.killNetworkProcess()
        let hasKillAll = webview.killAllContentProcess()
        if hasKillAll && hasKillNet {
            UDToast.docs.showMessage("killAllWebViewProcess success", on: self.view, msgType: .success)
        }
        DocsLogger.info("killAllWebViewProcess:\(hasKillNet), \(hasKillAll)")
    }
    
    func clearWKWebViewCache() {
        DocsWebViewV2.clearWKCache() { count in
            UDToast.docs.showMessage("clear finish: \(count) items", on: self.view, msgType: .success)
        }
    }
}
#endif
