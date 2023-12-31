//
//  UtilShowTimePickerService.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/17.
//

import SKFoundation
import SKCommon
import SKInfra
import SwiftyJSON
import LarkWebViewContainer

public final class UtilShowTimePickerService: BaseJSService {
    private var callback: APICallbackProtocol?
    private weak var pickerVC: TimePickerViewController?
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension UtilShowTimePickerService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        return [.showTimePicker]
    }

    public func handle(params: [String : Any], serviceName: String) {
        spaceAssertionFailure()
    }
    
    public func handle(params: [String: Any], serviceName: String, callback: APICallbackProtocol?) {
        self.callback = callback
        if let pickerVC = self.pickerVC {
            pickerVC.dismiss(animated: false) //避免重复弹出
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: [])
            let timeModel = try JSONDecoder().decode(TimePickerModel.self, from: data)
            let timePickerVC = TimePickerViewController(timeBlockId: timeModel.timeBlockId,
                                                        hour: timeModel.hour ?? 0,
                                                        minute: timeModel.minute ?? 0)
            if self.navigator?.currentBrowserVC?.isMyWindowRegularSizeInPad ?? false {
                timePickerVC.modalPresentationStyle = .formSheet
            } else {
                timePickerVC.modalPresentationStyle = .overCurrentContext
            }
            timePickerVC.delegate = self
            self.pickerVC = timePickerVC
            self.navigator?.presentViewController(timePickerVC, animated: true, completion: nil)
        } catch {
            DocsLogger.error("showTimePickert data is invalid:\(error)")
        }
    }
}

extension UtilShowTimePickerService: TimePickerViewControllerDelegate {
    func onTimePickDone(timeBlockId: String, hour: Int, minute: Int) {
        let params = ["timeBlockId": timeBlockId,
                      "hour": hour,
                      "minute": minute,
                      "action": "update"] as [String : Any]
        self.callback?.callbackSuccess(param: params)
    }
    
    func onTimePickDeleteTime(timeBlockId: String) {
        let params = ["timeBlockId": timeBlockId, "action": "delete"]
        self.callback?.callbackSuccess(param: params)
    }
    
    func onTimePickClose() {
        DocsLogger.info("onTimePickClose")
    }
}

struct TimePickerModel: Decodable {
    
    let timeBlockId: String
    let hour: Int?
    let minute: Int?
    
    init(timeBlockId: String, hour: Int? = nil, minute: Int? = nil) {
        self.timeBlockId = timeBlockId
        self.hour = hour
        self.minute = minute
    }
}
