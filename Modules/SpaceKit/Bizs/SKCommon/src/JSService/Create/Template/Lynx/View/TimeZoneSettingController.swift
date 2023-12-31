//
//  TimeZoneSettingController.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/5/31.
//  


import SKUIKit
import SKFoundation
import EENavigator
import BDXLynxKit
import BDXServiceCenter
import BDXBridgeKit
import SwiftyJSON
import SKResource
import UniverseDesignColor
import UniverseDesignToast


public final class TimeZoneSettingController: LynxBaseViewController {
    
    public var commonTrackParamsSetByOutsite: [String: String] = [:]
    
    public override var commonTrackParams: [String: String] {
        return commonTrackParamsSetByOutsite
    }
    
    private var timeZone: String
    
    private var isIpadAndNoSplit: Bool
    
    private var handler: BDXLynxBridgeHandler?
    
    private var model: BrowserModelConfig
    
    public init(timeZone: String, isIpadAndNoSplit: Bool = false, model: BrowserModelConfig) {
        self.timeZone = timeZone
        self.model = model
        self.isIpadAndNoSplit = isIpadAndNoSplit
        super.init(nibName: nil, bundle: nil)
        initialProperties = [
            "timeZone": timeZone,
            "timeZoneAbbr": TimeZone.docs.formatedAbbreviation(id: timeZone) ?? "",
            "isIPad": isIpadAndNoSplit
        ]
        templateRelativePath = "pages/bitable-time-zone-select-page/template.js"
        registerCustomHandler()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.statusBar.backgroundColor = UDColor.bgFloatBase
        self.view.backgroundColor = UDColor.bgFloatBase
        self.trackEvent()
    }
    
    private func registerCustomHandler() {
        let handler = DragPanelHandler {[weak self] (type, params) in
            guard let self = self else { return }
            switch type {
            case .show:
                DocsLogger.info("show timeZone select list timeZone: \(self.timeZone)")
                let timeZoneListVC = TimeZoneSelectListViewController(timeZone: self.timeZone,
                                                                      timeZoneList: self.formateTimeZoneList(params: params),
                                                                      model: self.model)
                timeZoneListVC.commonTrackParams = self.commonTrackParams
                if self.isIpadAndNoSplit {
                    timeZoneListVC.didFinishSelect = {[weak self] in
                        guard let self = self else { return }
                        self.navigationController?.dismiss(animated: true)
                        UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_Timezone_TimezoneChanged_Mobile, on: self.view.window ?? self.view)
                    }
                    timeZoneListVC.isIpadAndNoSplit = true
                    Navigator.shared.push(timeZoneListVC, from: self)
                } else {
                    timeZoneListVC.didFinishSelect = {[weak self] in
                        guard let self = self else { return }
                        self.navigationController?.popViewController(animated: false)
                        UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_Timezone_TimezoneChanged_Mobile, on: self.view.window ?? self.view)
                    }
                    timeZoneListVC.transitioningDelegate = timeZoneListVC
                    timeZoneListVC.modalPresentationStyle = .custom
                    self.present(timeZoneListVC, animated: true, completion: nil)
                }
            case .close:
                DocsLogger.info("close timeZone select list timeZone: \(self.timeZone)")
            }
        }
        customHandlers.append(handler)
    }
    
    func formateTimeZoneList(params: String) -> [[String: Any]] {
        DocsLogger.info("timeZoneLit: \(params)")
        let paramsJSON = JSON(parseJSON: params)
        let data = paramsJSON["data"].stringValue
        let list = JSON(parseJSON: data)["timeZoneList"].arrayValue
        let timeZoneListData = list.compactMap { item -> [String: Any]? in
            var dict = item.dictionaryObject
            if let itemId = dict?["id"] as? String, let formate = TimeZone.docs.formatedAbbreviation(id: itemId) {
                dict?["formate"] = formate
            } else {
                dict?["formate"] = "undefind"
            }
            return dict
        }
        return timeZoneListData
    }
    
    private func trackEvent() {
        var params = commonTrackParams
        params.updateValue("bitable_app", forKey: "bitable_type")
        params.updateValue("true", forKey: "is_full_screen")
        DocsTracker.newLog(enumEvent: .bitableTimeZoneSettingView, parameters: params)
    }
}
