//
//  LeakAvoider.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/25.
//  

import Foundation
import WebKit

class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController( userContentController, didReceive: message)
    }
}
