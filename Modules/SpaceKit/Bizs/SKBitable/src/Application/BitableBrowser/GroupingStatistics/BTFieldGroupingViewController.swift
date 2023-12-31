//
//  BTFieldGroupingViewController.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import Foundation
import SKCommon
import SKBrowser
import LarkUIKit
import SKUIKit
import UniverseDesignColor
import EENavigator
import BDXServiceCenter
import BDXBridgeKit
import UIKit

protocol BTFieldGroupingViewControllerDelegate: AnyObject {
    func didClickClosePage()
}

private extension BTGroupStatPanelType {
    var pageType: BTFieldGroupingViewType {
        switch self {
        case .group:
            return .GROUP_RESULT_VIEW
        case .total:
            return .TOTAL_STATISTICS_VIEW
        }
    }
}

final class BTFieldGroupingViewController: LynxBaseViewController {

    private var lastSendSize: CGSize?
    private var groupingStatisticsModel: BTGroupingStatisticsModel
    private weak var hostVC: UIViewController?
    weak var delegate: BTFieldGroupingViewControllerDelegate?
    private var reportCommonParams: [String: Any]
    weak var dataService: BTDataService?
    var openPanelAction: BTGroupingActionTask?

    init(groupingStatisticsModel: BTGroupingStatisticsModel,
         openPanelAction: BTGroupingActionTask,
         reportCommonParams: [String: Any],
         hostVC: UIViewController?,
         delegate: BTFieldGroupingViewControllerDelegate?,
         dataService: BTDataService?) {
        self.hostVC = hostVC
        self.delegate = delegate
        self.openPanelAction = openPanelAction
        self.reportCommonParams = reportCommonParams
        self.groupingStatisticsModel = groupingStatisticsModel
        self.dataService = dataService
        super.init(nibName: nil, bundle: nil)

        initialProperties = getLynxParam()
        templateRelativePath = "pages/bitable-groupingStatistics-view-page/template.js"

        registerHandlers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let preSize = lastSendSize ?? .zero
        let size = calculateSizeForLynxView()
        if abs(preSize.width - size.width) > 0.1 {
            let event = GlobalEventEmiter.Event(
                name: "ccm-pagesize-change",
                params: ["pageWidth": size.width, "pageHeight": size.height]
            )
            self.globalEventEmiter.send(event: event, needCache: true)
            lynxView?.triggerLayout()
            lastSendSize = size
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
    
    override func viewDidFirstScreen(_ view: BDXKitViewProtocol) {
        super.viewDidFirstScreen(view)
        openPanelAction?.completedBlock()
        openPanelAction = nil
    }

    private func calculateSizeForLynxView() -> CGSize {
        var size = self.view.bounds.size
        size.height -= self.statusBar.frame.size.height
        return size
    }

    private func registerHandlers() {
        //获取分组数据
        guard let browserVC = hostVC as? BrowserViewController else { return }
        let handler = LynxJSCallbackHandler(model: browserVC.editor)
        let containerHandler = BTFieldGroupingViewEventHandler(delegate: delegate)
        self.customHandlers = [handler, containerHandler]
    }

    func updateGroupData(data: BTGroupingStatisticsModel) {
        self.groupingStatisticsModel = data
        self.updateData(data: getLynxParam())
        if groupingStatisticsModel.type == .destory, let model = groupingStatisticsModel.data as? BTStatGroupData {
            sentEvent(event: "ccm-send-updatetExpandState", params: ["focusId": model.focusId])
        }
    }
    
    private func getLynxParam() -> [String: Any] {
        let ctx = groupingStatisticsModel
        var lynxData: [String: Any] = [
            "pageType": ctx.panelType.pageType.rawValue,
            "reportCommonParams": reportCommonParams
        ]
        if let data = ctx.data as? BTStatGroupData {
            // 分组统计面板
            lynxData["groupingStatisticsCountViewData"] = [
                "type": ctx.type.rawValue,
                "callbackId": ctx.callback,
                "focusId": data.focusId,
                "focusStatType": data.focusStatType,
                "data": data.groupData.toJSON(),
                "hasMoreData": data.hasMoreData,
                "maxRecordSize": data.maxRecordSize
            ]
        }
        if let data = groupingStatisticsModel.data as? [BTStatGlobalData] {
            // 全局统计面板
            lynxData["totalStatisticsData"] = [
                "type":  ctx.type.rawValue,
                "statDataList": data.map({ $0.toJSONString() ?? "" })
            ]
        }
        return lynxData
    }

    func sentEvent(event: String, params: [String: Any]?) {
        let event = GlobalEventEmiter.Event(
            name: event,
            params: params ?? [:]
        )
        self.globalEventEmiter.send(event: event, needCache: true)
    }
}

final class BTFieldGroupingViewEventHandler: BridgeHandler {
    public let methodName = "ccm.sendContainerEvent"

    public let handler: BDXLynxBridgeHandler

    public init(delegate: BTFieldGroupingViewControllerDelegate?) {
        handler = { [weak delegate] (container, name, params, callback) in
            guard let eventName = params?["eventName"] as? String else {
                callback(BDXBridgeStatusCode.failed.rawValue, nil)
                return
            }

            switch eventName {
            case "closeContainer":
                delegate?.didClickClosePage()
            default:
                break
            }
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
        }
    }
}
