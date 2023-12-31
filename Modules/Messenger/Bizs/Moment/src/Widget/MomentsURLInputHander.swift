//
//  MomentsURLInputHander.swift
//  Moment
//
//  Created by liluobin on 2023/8/21.
//

import UIKit
import LarkBaseKeyboard
import EditTextView
import TangramService

class MomentsURLInputHander: BaseURLInputHander {
    override var psdaToken: String {
        return token
    }

    let token: String

    init(urlPreviewAPI: URLPreviewAPI?, psdaToken: String) {
        self.token = psdaToken
        super.init(urlPreviewAPI: urlPreviewAPI)
    }
}
