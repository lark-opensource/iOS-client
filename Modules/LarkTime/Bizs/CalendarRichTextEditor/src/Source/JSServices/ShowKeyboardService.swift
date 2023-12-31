//
//  ShowKeyboardService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/19.
//

import Foundation
final class ShowKeyboardService {
    weak var richTextViewUIResponse: RichTextViewUIResponse?
    init(_ responder: RichTextViewUIResponse) {
        self.richTextViewUIResponse = responder
    }
}

extension ShowKeyboardService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtUtilKeyBoard]
    }

    func handle(params: [String: Any], serviceName: String) {
        richTextViewUIResponse?.becomeFirst(trigger: "editor")
    }
}
