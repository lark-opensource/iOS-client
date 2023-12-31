//
//  SpaceMultiListTracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/24.
//

import Foundation
import SKFoundation
import SKCommon

struct SpaceMultiListTracker: SpaceTracker {
    let bizParameter: SpaceBizParameter = SpaceBizParameter(module: .home(.recent))
    let subTabIDs: [String]

    init(subTabIDs: [String]) {
        self.subTabIDs = subTabIDs
    }

    mutating func reportClick(index: Int) {
        guard index < subTabIDs.count else {
            spaceAssertionFailure("subTab index out of bounds")
            return
        }
        let tabID = subTabIDs[index]
        let params: P = [
            "tab_type": tabID
        ]
        DocsTracker.log(enumEvent: .spaceSubTabClick, parameters: params)
    }
}
