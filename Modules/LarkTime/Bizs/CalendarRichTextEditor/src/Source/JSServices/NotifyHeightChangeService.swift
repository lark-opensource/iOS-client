//
//  NotifyHeightChangeService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/19.
//

import UIKit
import Foundation

final class NotifyHeightChangeService {
    weak var richTextViewDisplayConfig: RichTextViewDisplayConfig?

    init(_ richTextViewDisplayConfig: RichTextViewDisplayConfig) {
        self.richTextViewDisplayConfig = richTextViewDisplayConfig
    }
}

extension NotifyHeightChangeService: JSServiceHandler {
    var handleServices: [JSService] {
        return [.rtNotifyHeight, .richTextResizeY]
    }

    func handle(params: [String: Any], serviceName: String) {
        let keystr = "height"
        guard let height = params[keystr] as? CGFloat else { assertionFailure(); return }
        Logger.info("RTEditor did update height", extraInfo: ["height": height])
        richTextViewDisplayConfig?.updateContentHeight(height)
    }
}
