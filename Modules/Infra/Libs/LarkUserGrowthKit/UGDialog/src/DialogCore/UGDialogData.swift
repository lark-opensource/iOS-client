//
//  UGDialogData.swift
//  UGDialog
//
//  Created by Aslan on 2022/01/11.
//

import Foundation
import ServerPB

public typealias UGDialogInfo = ServerPB_Ug_reach_material_DialogMaterial

@dynamicMemberLookup
public struct UGDialogData: Equatable {

    let dialogInfo: UGDialogInfo

    // Dynamic Member Lookup
    subscript<T>(dynamicMember keyPath: KeyPath<ServerPB.ServerPB_Ug_reach_material_DialogMaterial, T>) -> T {
        return dialogInfo[keyPath: keyPath]
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.dialogInfo == rhs.dialogInfo
    }
}
