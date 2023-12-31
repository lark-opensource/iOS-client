//
//  OPBlockWebRender.swift
//  OPBlock
//
//  Created by lixiaorui on 2022/3/28.
//

import Foundation
import WebBrowser
import OPSDK
import SwiftUI
import TTMicroApp
import LarkOPInterface
import OPBlockInterface
import LarkContainer

// block web 渲染层：负责加载webview，处理webview生命周期
final class OPBlockWebRender: OPNode, OPRenderProtocol {

    private let userResolver: UserResolver
    private let offlineUtil: OPBlockOfflineUtil

    public private(set) lazy var webBrowser: WebBrowser = {
        // web配置，目前走默认配置
        var config = WebBrowserConfiguration()
        config.resourceInterceptConfiguration = self.offlineUtil.resourceInterceptConfiguration(
            appID: self.context.uniqueID.appID,
            delegate: self
        )
        // 在render方法中获取url进行load，初始化无url
        let webBrowser = WebBrowser(url: nil, configuration: config)
        return webBrowser
    }()

    // contentsize监听者，用于处理业务内容大小变化后通知宿主
    private var contentSizeObserver: NSKeyValueObservation?

    private var contentHeight: CGFloat = -1

    // 复用component的context，内部可取meta等信息
    let context: OPComponentContext

    // 文件资源读取器，用于读取包文件内容以供webview加载
    let packageReader: OPPackageReaderProtocol

    /// render生命周期，注意实现的时候使用weak
    weak var delegate: OPRenderLifeCycleProtocol?

    init(
        userResolver: UserResolver,
        fileReader: OPPackageReaderProtocol,
        context: OPComponentContext
    ) {
        self.userResolver = userResolver
        self.context = context
        self.packageReader = fileReader
        self.offlineUtil = OPBlockOfflineUtil(userResolver: userResolver)
    }

    deinit {
        contentSizeObserver?.invalidate()
        contentSizeObserver = nil
    }

    /// 内部会转 data 的类型，如果转换失败会抛出错误
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws {
        guard let slotView = slot.view else {
            context.containerContext.trace?.error("web render error: nil slot view",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString])
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid slot view")
        }
        guard let data = data as? OPBlockComponentData else {
            context.containerContext.trace?.error("web render error: invalid data",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString])
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid data")
        }
        // 只有web block才可以使用web render渲染
        guard let blockMeta = context.containerContext.meta as? OPBlockMeta,
                blockMeta.extConfig.pkgType == .offlineWeb else {
            context.containerContext.trace?.error("web render error: invalid block meta",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString])
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid block meta")
        }
        let mainPath = data.templateFilePath
        // 使用标准URL的appendingPathComponent解决mainPath可能配置不规范的问题
        guard var url = URL(string: offlineUtil.fixedVHost(blockMeta.extConfig.vHost))?.appendingPathComponent(mainPath) else {
            context.containerContext.trace?.error("web render error: invalid url",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString,
                                                                   "vhost": blockMeta.extConfig.vHost])
            throw OPError.error(monitorCode: OPBlockitMonitorCodeMountLaunchComponent.component_fail, message: "invalid url")
        }
        slotView.addSubview(webBrowser.view)
        webBrowser.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        // fallback 逻辑
        if offlineUtil.offlineType(appID: context.uniqueID.appID) == .fallbackURL,
            let fallbackPathList = blockMeta.extConfig.fallbackPathList {
            var fallbackUrls = offlineUtil.fallbackUrls(fallbackPathList: fallbackPathList, mainPath: mainPath)
            if !fallbackUrls.isEmpty {
                // 降级加载 fallback URL
                url = fallbackUrls.removeFirst()
                if webBrowser.resolve(FallbackExtensionItem.self) == nil {
                    // 注册多URL的自动轮询插件
                    try? webBrowser.register(item: FallbackExtensionItem(fallbackUrls: fallbackUrls))
                }
            }
        }
        webBrowser.loadURL(url)
    }

    /// 内部会转 initData 的类型，如果转换失败会抛出错误
    func update(data: OPComponentTemplateDataProtocol) throws {

    }

    func reRender() {
        webBrowser.reload()
    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 show 事件，component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onShow() {

    }

    /// Container 在合适的时机调用，告诉 Component Slot 发生了 hide 事件，component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onHide() {

    }

    /// Container 在 destroy 时，告诉 Component 要 destroy 了, component 通知 render
    /// render 按需对view进行操作， 如layout等
    func onDestroy() {

    }

}

extension OPBlockWebRender {

    /// 注册web  item，处理api 及 lifecycle事件
    func registerWebItem(with item: OPBlockComponentWebBrowserItem) {
        do {
            try webBrowser.register(item: item)
            try webBrowser.register(singleItem: item)
            if offlineUtil.offlineType(appID: context.uniqueID.appID) == .urlProtocol {
                try webBrowser.register(item: OfflineResourceExtensionItem(appID: context.uniqueID.appID,
                                                                           browser: webBrowser,
                                                                           delegate: self))
            }
        } catch {
            context.containerContext.trace?.error("web render register web item fail",
                                                  additionalData: ["uniqueID": context.containerContext.uniqueID.fullString],
                                                  error: error)
        }
    }
}

