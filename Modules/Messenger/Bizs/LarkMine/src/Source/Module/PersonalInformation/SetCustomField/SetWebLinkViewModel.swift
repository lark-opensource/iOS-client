//
//  SetWebLinkViewModel.swift
//  LarkMine
//
//  Created by ByteDance on 2022/12/30.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import RustPB
import RxSwift
import LKCommonsLogging

class SetWebLinkViewModel {

    private let chatterAPI: ChatterAPI

    static let logger = Logger.log(SetWebLinkViewModel.self, category: "Module.Mine")

    var key: String
    var pageTitle: String
    var text: String?
    var link: String?
    var successCallBack: (_ text: String, _ link: String) -> Void?

    init(key: String, pageTitle: String, text: String?, link: String?, chatterAPI: ChatterAPI, successCallBack: @escaping (_ text: String, _ link: String) -> Void?) {
        self.key = key
        self.pageTitle = pageTitle
        self.text = text
        self.link = link
        self.chatterAPI = chatterAPI
        self.successCallBack = successCallBack
    }

    func savePersonalInfo(text: String, link: String) -> Observable<Void> {
        var customInfo = RustPB.Contact_V1_UpdateChatterRequest.ExtAttrValue()
        customInfo.text = text
        customInfo.link = link
        customInfo.valueType = .fieldValueLink
        return chatterAPI.setPersonCustomInfo(customInfo: [key: customInfo]).do(onNext: { [weak self] in
            Self.logger.info("Field key: \(self?.key), update custom info success!!! ")
            self?.successCallBack(text, link)
        }, onError: { [weak self] error in
            Self.logger.error("Field key: \(self?.key), update custom info failed, error: \(error) ")
        })
    }

    func isLegalLink(link: String) -> Bool {
        let link = link.trimmingCharacters(in: .whitespaces)
        return link.hasPrefix("http://") || link.hasPrefix("https://") || link.isEmpty
    }
}
