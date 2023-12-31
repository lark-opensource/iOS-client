//
//  MultiTaskService.swift
//  SpaceKit
//
//  Created by nine on 2019/3/1.
//

import Foundation
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignIcon
import SpaceInterface

class MultiTaskService: BaseJSService {
    static var docsScrollRecords = [String: DocsScrollPos]()
    var currentTitle: String?
    weak var currentVC: UIViewController?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension MultiTaskService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.saveScrollPos, .navSetName]
    }

    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.saveScrollPos.rawValue:
            guard let x = params["x"] as? Float,
                let y = params["y"] as? Float,
                let token = params["token"] as? String else { DocsLogger.error("【多任务】 接口数据解析失败"); return }
            MultiTaskService.docsScrollRecords[token] = DocsScrollPos(x, y)
        case DocsJSService.navSetName.rawValue:
            guard let title = params["title"] as? String, currentTitle != title else { return }
            // 如果前端的title与currentTitle不同，则更新currentTitle并更新历史记录
            currentTitle = title
            insertHistory(needScreenShot: false)
        default:
            break
        }
    }
}

extension MultiTaskService: BrowserViewLifeCycleEvent {
    public func browserDidUpdateDocsInfo() {
        currentVC = navigator?.currentBrowserVC
        insertHistory(needScreenShot: false)
    }

    public func browserDidDismiss() {
        insertHistory(needScreenShot: true)
    }
}

private extension MultiTaskService {
    /// 插入多任务历史记录，needScreenShot代表是否需要截图，为false不自动截图。换出摇一摇窗口时，如果当前vc没有截图会自定截图
    /// 同一篇文档多次插入，以最后一次为准，token标识唯一
    func insertHistory(needScreenShot: Bool) {
        guard !DocsSDK.isInDocsApp else { DocsLogger.info("【多任务】Docs App中不支持多任务"); return }
        guard model?.vcFollowDelegate == nil else { DocsLogger.error("多任务-vc Follow不记录多任务"); return }
        guard let token = model?.browserInfo.token else { DocsLogger.error("【多任务】 无法获取该类型的token"); return }
        guard !isDocOpenByOpenSDK() else { DocsLogger.info("【多任务】 从群公告进入不记录"); return }
        guard let url = getCurrentWebUrl() else { DocsLogger.error("【多任务】 无法获取该类型的url"); return }

        guard let type = model?.browserInfo.docsInfo?.type else { DocsLogger.error("【多任务】 无法获取该类型的type"); return }
        guard let icon = getCurrentIcon(with: type) else { DocsLogger.error("【多任务】 无法获取该类型的ico"); return }
        guard let vc = currentVC else { DocsLogger.error("【多任务】 无法获取到截图所需的VC"); return }
        navigator?.sendLarkOpenEvent(.record(DocsTracker.encrypt(id: token), url: url,
                                             title: getCurrentTitle(with: type), iconImageSource: icon,
                                             vc: vc, needAutoScreenShot: needScreenShot, info: ["type": type.name]))
        currentTitle = getCurrentTitle(with: type)
    }
    /// 获取当前文档的标题
    func getCurrentTitle(with type: DocsType) -> String {
        if let title = currentTitle, !title.isEmpty { //由前端设置的title
            return title
        } else if let title = model?.browserInfo.docsInfo?.title, !title.isEmpty { //docsInfo中的title
            return title
        } else { // 为空时的默认title
            return type.untitledString
        }
    }
    /// 获取当前文档的icon
    func getCurrentIcon(with type: DocsType) -> UIImage? {
        let imagekey: UDIconType
        switch type {
        case .doc:
            imagekey = .fileRoundDocColorful
        case .sheet:
            imagekey = .fileRoundSheetColorful
        case .bitable:
            imagekey = .fileRoundBitableColorful
        case .mindnote:
            imagekey = .fileRoundMindnoteColorful
        default:
            imagekey = .fileRoundUnknowColorful
        }
        return UDIcon.getIconByKey(imagekey, size: CGSize(width: 48, height: 48))
    }
    /// 获取当前文档的url
    func getCurrentWebUrl() -> URL? {
        guard let type = model?.browserInfo.docsInfo?.type,
            let token = model?.browserInfo.token else { return nil }
        return  DocsUrlUtil.url(type: type, token: token, originUrl: model?.browserInfo.currentURL).docs.addQuery(parameters: ["from": "multiTask"])
    }

    /// 判断是否是群公告打开了文档
    func isDocOpenByOpenSDK() -> Bool {
        guard let url = model?.requestAgent.currentUrl, let from = url.docs.queryParams?["from"] else {
            return false
        }
        return from == "group_tab_notice"
    }
}
