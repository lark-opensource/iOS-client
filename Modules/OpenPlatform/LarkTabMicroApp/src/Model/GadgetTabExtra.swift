//
//  GadgetTabExtra.swift
//  LarkTabMicroApp
//
//  Created by tujinqiu on 2020/1/13.
//

import Foundation
import LarkLocalizations
import SwiftyJSON

class GadgetTabExtra {
    let extraJSON: JSON

    init(dict: [String: Any]) {
        self.extraJSON = JSON(dict)
    }

    lazy var name: String = {
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        /// 优先使用匹配到的国际化name，其次使用英文的，再次使用中文的，最后使用空串兜底
        return extraJSON["name"][lang].string ?? extraJSON["name"]["en_us"].string ?? extraJSON["name"]["zh_cn"].string ?? ""
    }()

    lazy var appID: String? = {
        return extraJSON["app_id"].string
    }()

    lazy var logoURL: URL? = {
        if let l = extraJSON["logo"]["primary_default"].string {
            return URL(string: l)
        }
        return nil
    }()

    lazy var selectedLogoURL: URL? = {
        if let l = extraJSON["logo"]["primary_selected"].string {
            return URL(string: l)
        }
        return nil
    }()

    lazy var conveninentLogoURL: URL? = {
        if let l = extraJSON["logo"]["secretary_default"].string {
            return URL(string: l)
        }
        return nil
    }()
}
