//
//  ItemStatusService.swift
//  LarkListItem
//
//  Created by Yuri on 2023/10/8.
//

import UIKit
import RustPB

public protocol ItemStatusServiceType {
    func generateStatusView(status: [RustPB.Basic_V1_Chatter.ChatterCustomStatus]?) -> UIView?
}

