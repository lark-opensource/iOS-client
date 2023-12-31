//
//  WADebugItem.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/12/1.
//

import Foundation
import LarkDebugExtensionPoint
import EENavigator


public struct WADebugItem: DebugCellItem {
    public var title: String = "WADebug"
    
    public var type: DebugCellType = .disclosureIndicator

    public var switchValueDidChange: ((Bool) -> Void)?

    public init() {}
    
    public func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(WADetailDebugController(), from: debugVC)
    }
}


struct WADebugCellItem {
    enum WADebugCellType {
        case text
        case tap
        case switchButton(isOn: Bool, tag: WADebugSwitchButtonTag)
    }
    
    enum WADebugSwitchButtonTag: Int {
        case updatePkgVersion = 1000
    }
    
    let title: String
    let detail: String?
    let type: WADebugCellType
    
    init(title: String, detail: String?, type: WADebugCellType) {
        self.title = title
        self.detail = detail
        self.type = type
    }
    
    static let updatePkgVersion = WADebugCellItem(title: "updatePkgVersion", detail: nil, type: .switchButton(isOn: false, tag: .updatePkgVersion))
}




