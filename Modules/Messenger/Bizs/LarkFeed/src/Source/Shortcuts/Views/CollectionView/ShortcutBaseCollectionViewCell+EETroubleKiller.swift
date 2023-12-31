//
//  ShortcutCollectionCell+EETroubleKiller.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/6.
//

import Foundation
import EETroubleKiller

extension ShortcutCollectionCell: CaptureProtocol & DomainProtocol {

    public var isLeaf: Bool {
        return true
    }

    public var domainKey: [String: String] {
        guard let cellViewModel = cellViewModel else {
            return ["": ""]
        }
        return [cellViewModel.id: cellViewModel.description]
    }
}
