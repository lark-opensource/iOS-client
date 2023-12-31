//
//  SetTextViewModel.swift
//  LarkMine
//
//  Created by ByteDance on 2023/1/3.
//

import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import LarkContainer
import LKCommonsLogging

class SetTextViewModel {

    private let chatterAPI: ChatterAPI

    // 工位字段对应的key
    static let stationKey = "B-STATION"
    static let logger = Logger.log(SetTextViewModel.self, category: "Module.Mine")

    var key: String
    var pageTitle: String
    var text: String
    var successCallBack: (String) -> Void?

    init(key: String, pageTitle: String, text: String, chatterAPI: ChatterAPI, successCallBack: @escaping (String) -> Void?) {
        self.key = key
        self.pageTitle = pageTitle
        self.text = text
        self.chatterAPI = chatterAPI
        self.successCallBack = successCallBack
    }

    func savePersonalInfo(text: String) -> Observable<Void> {
        if key == Self.stationKey {
            return chatterAPI.setStation(station: text).do(onNext: { [weak self] in
                Self.logger.info("Field key: \(self?.key), update station success!!! ")
                self?.successCallBack(text)
            }, onError: { [weak self] error in
                Self.logger.error("Field key: \(self?.key), update station failed, error: \(error) ")
            })
        }
        var customInfo = RustPB.Contact_V1_UpdateChatterRequest.ExtAttrValue()
        customInfo.text = text
        customInfo.valueType = .fieldValueText
        return chatterAPI.setPersonCustomInfo(customInfo: [key: customInfo]).do(onNext: { [weak self] in
            Self.logger.info("Field key: \(self?.key), update custom info success!!! ")
            self?.successCallBack(text)
        }, onError: { [weak self] error in
            Self.logger.error("Field key: \(self?.key), update custom info failed, error: \(error) ")
        })
    }
}
