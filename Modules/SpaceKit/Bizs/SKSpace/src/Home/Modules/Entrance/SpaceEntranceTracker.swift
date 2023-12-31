//
//  SpaceEntranceTracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/24.
//

import Foundation
import SKFoundation
import SKCommon

public struct SpaceEntranceTracker: SpaceTracker {
    var bizParameter: SpaceBizParameter

    let entranceIDs: [String]

    func reportShow() {
        let types = entranceIDs.joined(separator: ",")
        let params: P = [
            "function_type": types
        ]
        DocsTracker.log(enumEvent: .spaceEntranceShow, parameters: params)
    }

    func reportClick(index: Int) {
        guard index < entranceIDs.count else {
            spaceAssertionFailure("entrance click index out of bounds")
            return
        }
        let entranceID = entranceIDs[index]
        let params: P = [
            "function_type": entranceID
        ]
        DocsTracker.log(enumEvent: .spaceEntranceClick, parameters: params)
        DocsTracker.reportSpaceHomePageClick(params: SpacePageClickParameter.typeFor(entrance: entranceID), bizParms: bizParameter)
    }
}
