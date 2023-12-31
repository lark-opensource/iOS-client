//
//  BTViewContainerService.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/9/6.
//

import UIKit
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import UniverseDesignIcon
import UniverseDesignColor
import HandyJSON
import WebBrowser
import SKResource
import SKInfra
import LarkUIKit

struct BTViewPanelModel: HandyJSON, Equatable {
    var name: String?
    var items: [BTCommonItem]?
    var bottomAction: SimpleItem?
    var sortAction: String?
    var canSort: Bool?
    var theme: String?
    var callback: String?
}

final class BTViewContainerService: BaseJSService {
    private var currentPanelModel: BTViewPanelModel? = nil
    private var currentPanel: BTCommonPannel? = nil
}

extension BTViewContainerService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.showViewPanel]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.btInfo("BTViewContainerService handle \(serviceName) params: \(String(describing: params.jsonString?.encryptToShort))")
        switch serviceName {
        case DocsJSService.showViewPanel.rawValue:
            showViewPanel(params)
            break
        default:
            DocsLogger.btError("unsupport serviceName \(serviceName)(\(params))")
        }
    }

    private func showViewPanel(_ params: [String: Any]) {
        if params.isEmpty {
            clearPanel(from: "showViewPanel params is empty")
            DocsLogger.btInfo("[BTViewContainerService] showViewPanel params is empty")
            return
        }
        if currentPanelModel != nil, currentPanel != nil {
            clearPanel(from: "currentPanelModel is not nil")
        }
        guard let model = BTViewPanelModel.deserialize(from: params) else {
            DocsLogger.btError("[BTViewContainerService] deserialize BTViewPanelModel fail")
            return
        }
        guard let registeredVC = registeredVC else {
            DocsLogger.btError("[BTViewContainerService] registeredVC is nil")
            return
        }
        let permissionObj = BasePermissionObj.parse(params)
        let baseToken = params["baseId"] as? String ?? ""
        let baseContext = BaseContextImpl(baseToken: baseToken, service: self, permissionObj: permissionObj, from: "showViewPanel")
        currentPanelModel = model

        let config = BTCommonPannelConfig(
            dragable: true,
            sortable: model.canSort ?? false,
            showBottomButton: model.bottomAction != nil,
            title: model.name ?? "",
            bottomTitle: model.bottomAction?.text ?? ""
        )
        let callback = model.callback
        let panel = BTCommonPannel(config: config, baseContext: baseContext)
        panel.hideRightIconWhenLandscape = Display.phone
        currentPanel = panel

        let selectedIndex = model.items?.firstIndex(where: { model in
            return model.isSelected
        })

        if let items = model.items?.map({ raw in
            let selected = raw.isSelected
            let showMore = raw.rightIcon != nil
            let icon = raw.leftIconImage
            let title = raw.leftText
            let viewId = raw.id
            let clickAction = raw.clickAction ?? ""
            let moreAction = raw.rightIcon?.clickAction ?? ""

            let leftIcon: BTCommonDataItemIconInfo?
            if icon != nil || raw.leftIcon?.url != nil {
                leftIcon = BTCommonDataItemIconInfo(
                    image: icon?.ud.withTintColor(selected ? UDColor.primaryPri500 : UDColor.iconN2),
                    url: raw.leftIcon?.url,
                    size: CGSizeMake(18.0, 18.0),
                    alignment: .top(offset: 0.5),
                    customRender: nil
                )
            } else {
                leftIcon = nil
            }

            return BTCommonDataItem(
                id: viewId,
                selectCallback: { [weak self] _, _, _ in
                    guard let self = self else {
                        return
                    }
                    self.clearPanel(from: "selectCallback")
                    guard let callback = callback else {
                        DocsLogger.btError("[BTViewContainerService] callback is nil")
                        return
                    }
                    let params = [
                        "id": viewId ,
                        "action": clickAction,
                    ]
                    self.model?.jsEngine.callFunction(
                        DocsJSCallBack(callback),
                        params: params, completion: nil
                    )
                },
                background: BTCommonDataItemBackground(color: selected ? UDColor.fillSelected.withAlphaComponent(0.1) : .clear, selectedColor: selected ? UDColor.fillSelected.withAlphaComponent(0.2) : nil),
                leftIcon: leftIcon,
                mainTitle: BTCommonDataItemTextInfo(text: title,
                                                    color: selected ? UDColor.primaryPri500 : UDColor.textTitle,
                                                    font: UIFont.systemFont(ofSize: 16),
                                                    lineNumber: 2,
                                                    lineSpacing: 6),
                rightIcon: showMore ? BTCommonDataItemIconInfo(image: UDIcon.moreOutlined.ud.withTintColor(UDColor.iconN3), size: CGSizeMake(18, 18.0), alignment: .top(offset: 1.5), customRender: nil, clickCallback: { [weak self] view in
                    guard let self = self else { return }
                    if !SKDisplay.pad {
                        self.clearPanel(from: "rightIcon")
                    }
                    guard let callback = callback else {
                        DocsLogger.btError("[BTViewContainerService] callback is nil")
                        return
                    }
                    var params = ["id": viewId ,
                                  "action": moreAction]
                    if self.shouldPopoverDisplay() == true {
                        params["sourceViewID"] = BTPanelService.weakBindSourceView(view: view)
                    }
                    self.model?.jsEngine.callFunction(
                        DocsJSCallBack(callback),
                        params: params, completion: nil
                    )
                }) : nil,
                edgeInset: UIEdgeInsets(top: 13, left: 10, bottom: 13, right: 4)
            )
        }) {
            panel.delegate = self

            let group = BTCommonDataGroup(
                groupName: "",
                items: items,
                showSeparatorLine: false,
                cornersMode: .always,
                leftIconTitleSpacing: 10
            )
            panel.setData(data: BTCommonDataModel(groups: [group]))
            if let selectedIndex = selectedIndex {
                panel.initIndexPath = IndexPath(row: selectedIndex, section: 0)
            }
            panel.open(from: registeredVC, animated: true)
        }
    }

    private func clearPanel(from: String) {
        currentPanelModel = nil
        currentPanel?.close()
        currentPanel = nil
        DocsLogger.btError("[BTViewContainerService] clearPanel \(from)")
    }
}

extension BTViewContainerService: BTCommonPannelDelegate {
    func commonPanelBottomClicked(panel: BTCommonPannel, sourceView: UIView) {
        DocsLogger.btError("[BTViewContainerService] commonPanelBottomClicked")
        guard let callback = currentPanelModel?.callback else {
            DocsLogger.btError("[BTViewContainerService] callback is nil")
            return
        }
        var params = ["action": currentPanelModel?.bottomAction?.clickAction ?? ""]
        if shouldPopoverDisplay() {
            params["sourceViewID"] = BTPanelService.weakBindSourceView(view: sourceView)
        }
        model?.jsEngine.callFunction(
            DocsJSCallBack(callback),
            params: params,
            completion: nil
        )
        if !SKDisplay.pad {
            clearPanel(from: "commonPanelBottomClicked")
        }
    }

    func commonPanelSortItem(panel: BTCommonPannel, viewId: String, fromIndex: Int, toIndex: Int) {
        DocsLogger.btInfo("[BTViewContainerService] commonPanelSortItem \(fromIndex) \(toIndex)")
        guard let callback = currentPanelModel?.callback else {
            DocsLogger.btError("[BTViewContainerService] callback is nil")
            return
        }
        guard fromIndex >= 0, fromIndex < currentPanelModel?.items?.count ?? 0 else {
            DocsLogger.btError("[BTViewContainerService] fromIndex is invalid")
            return
        }
        model?.jsEngine.callFunction(
            DocsJSCallBack(callback),
            params: [
                "action": currentPanelModel?.sortAction ?? "",
                "id": viewId,
                "fromIndex": fromIndex,
                "toIndex": toIndex
            ],
            completion: nil
        )
    }

    func commonPanelBottomClosed(panel: BTCommonPannel) {
        currentPanelModel = nil
        currentPanel = nil
        DocsLogger.btInfo("[BTViewContainerService] commonPanelBottomClosed")
    }
}

extension BTViewContainerService: ViewCatalogueService {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }

    func shouldPopoverDisplay() -> Bool {
        guard SKDisplay.pad else {
            return false
        }
        guard let ui = ui else {
            DocsLogger.warning("ui is nil")
            return false
        }
        return ui.hostView.isMyWindowRegularSize()
    }
}

extension BTViewContainerService: BaseContextService {
    
}
