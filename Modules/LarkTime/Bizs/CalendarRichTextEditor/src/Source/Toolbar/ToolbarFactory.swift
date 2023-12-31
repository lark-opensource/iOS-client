//
//  ToolbarFactory.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/8/5.
//

import Foundation

final class ToolbarFactory {
    static func makeToolbar(items: [[String: Any]], jsMethod: String) -> [ToolbarItem] {
        var infos: [ToolbarItem] = []
        for info in items {
            guard let sId = info["id"] as? String else { continue }
            let itemModel = ToolbarItem(identifier: sId, json: info, jsMethod: jsMethod)
            infos.append(itemModel)
        }
        return infos
    }
}
