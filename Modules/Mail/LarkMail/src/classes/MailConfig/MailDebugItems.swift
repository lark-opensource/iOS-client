//
//  MailDebugItems.swift
//  LarkMail
//
//  Created by CharlieSu on 11/28/19.
//

import Foundation
import LarkDebugExtensionPoint
import Swinject

struct MailDebugItem: DebugCellItem {
    let title: String = "LarkMail"
    let type: DebugCellType = .disclosureIndicator

    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        try? resolver.resolve(assert: LarkMailService.self).mail.presentMailDebugger()
    }
}
