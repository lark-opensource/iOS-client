//
//  BTFieldGroupingViewController.swift
//  SKBitable
//
//  Created by zoujie on 2022/3/15.
//  


import SKFoundation
import SKCommon
import SKBrowser
import LarkUIKit
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import BDXServiceCenter
import BDXBridgeKit
import EENavigator
import UIKit

protocol BTFieldGroupingSetViewControllerDelegate: AnyObject {
    func didClickClosePage()
}

final class BTFieldGroupingSetViewController: LynxBaseViewController {

    private var lastSendSize: CGSize?
    private var groupingStatisticsSetItems: [BTGroupingStatisticsSetItem]
    private var selectedItemId: String
    private var callbackString: String
    private var fieldId: String
    private weak var hostVC: UIViewController?
    weak var delegate: BTFieldGroupingSetViewControllerDelegate?
    private var reportCommonParams: [String: Any]

    init(groupingStatisticsSetItems: [BTGroupingStatisticsSetItem],
         delegate: BTFieldGroupingSetViewControllerDelegate?,
         selectedItemId: String,
         fieldId: String,
         callbackString: String,
         hostVC: UIViewController?,
         reportCommonParams: [String: Any]) {
        self.hostVC = hostVC
        self.fieldId = fieldId
        self.delegate = delegate
        self.callbackString = callbackString
        self.selectedItemId = selectedItemId
        self.reportCommonParams = reportCommonParams
        self.groupingStatisticsSetItems = groupingStatisticsSetItems
        super.init(nibName: nil, bundle: nil)

        initialProperties = [
            "pageType": BTFieldGroupingViewType.TYPE_SET_VIEW.rawValue,
            "groupingStatisticsCountTypeData": ["fieldId": self.fieldId,
                                                "optionList": self.groupingStatisticsSetItems.toJSON(),
                                                "statTypeId": self.selectedItemId,
                                                "callbackId": callbackString],
            "reportCommonParams": reportCommonParams
        ]
        templateRelativePath = "pages/bitable-groupingStatistics-view-page/template.js"

        registerHandlers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let hostVC = hostVC else {
            return
        }

        let isRegularSizeInPad = self.isMyWindowRegularSizeInPad
        let preSize = lastSendSize ?? .zero
        let size = isRegularSizeInPad ? self.view.bounds.size : hostVC.view.bounds.size
        if abs(preSize.width - size.width) > 0.1 ||
            abs(preSize.height - size.height) > 0.1 {
            let event = GlobalEventEmiter.Event(
                name: "ccm-pagesize-change",
                params: ["pageWidth": size.width, "pageHeight": isRegularSizeInPad ? size.height / 0.8 : size.height]
            )
            self.globalEventEmiter.send(event: event, needCache: true)
            lynxView?.triggerLayout()
            lastSendSize = size
        }
    }

    private func registerHandlers() {
        guard let browserVC = hostVC as? BrowserViewController else { return }
        let handler = LynxJSCallbackHandler(model: browserVC.editor)
        let containerHandler = BTFieldGroupingSetViewEventHandler(delegate: delegate)
        self.customHandlers = [handler, containerHandler]
    }
}

final class BTFieldGroupingSetViewEventHandler: BridgeHandler {
    public let methodName = "ccm.sendContainerEvent"

    public let handler: BDXLynxBridgeHandler

    public init(delegate: BTFieldGroupingSetViewControllerDelegate?) {
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
