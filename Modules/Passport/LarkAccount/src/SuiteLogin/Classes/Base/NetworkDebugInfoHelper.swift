//
//  NetworkDebugInfoHelper.swift
//  LarkAccount
//
//  Created by ZhaoKejie on 2023/3/29.
//

#if DEBUG || BETA || ALPHA

import Foundation
import UniverseDesignToast
import EENavigator
import LarkAccountInterface
import SnapKit

public class NetworkDebugInfoHelper {

    public static var shared = NetworkDebugInfoHelper()

    /// 是否展示顶部debug toast的开关
    var enableToast: Bool {
        UserDefaults.standard.bool(forKey: PassportSwitch.shared.enablePassportNetworkDebugToast)
    }

    var itemList: [NetworkInfoItem] = []

    func appendSuccItem(host: String?,
                               path: String?,
                               httpCode: Int?,
                               xRequestId: String?,
                               xTTLogid: String?,
                               xTTEnv: String?) {

        let newItem = NetworkInfoItem(isSuccess: true, host: host, path: path, httpCode: httpCode, xRequestId: xRequestId, xTTEnv: xTTEnv, errorCode: nil, errorMessage: nil, bizCode: nil, xTTLogid: xTTLogid)
        itemList.insert(newItem, at: 0)
        if itemList.count >= 200 {
            itemList.removeLast()
        }
    }

    func appendErrorItem(host: String?,
                                path: String?,
                                httpCode: Int?,
                                xRequestId: String?,
                                xTTLogid: String?,
                                xTTEnv: String?,
                                errorCode: Int32?,
                                bizCode: Int32?,
                                errorMessage: String?) {


        let newItem = NetworkInfoItem(isSuccess: false, host: host, path: path, httpCode: httpCode, xRequestId: xRequestId, xTTEnv: xTTEnv, errorCode: errorCode, errorMessage: errorMessage, bizCode: bizCode, xTTLogid: xTTLogid)
        itemList.insert(newItem, at: 0)
        if itemList.count > 200 {
            itemList.removeLast()
        }

        // 失败的情况在顶部toast弹窗
        if enableToast, let toastFromView = Navigator.shared.mainSceneWindow { // user:checked (debug)
            let toastMessage = errorMessage ?? I18N.Lark_Passport_BadServerData
            let toastView = UDToast.showTips(with: toastMessage, operationText: "复制",on: toastFromView, operationCallBack: { (str) in
                UIPasteboard.general.string = newItem.desc
            })
            toastView.observeKeyboard = false
            toastView.setCustomBottomMargin(toastFromView.btd_height - 100)
        }
    }

}
#endif
