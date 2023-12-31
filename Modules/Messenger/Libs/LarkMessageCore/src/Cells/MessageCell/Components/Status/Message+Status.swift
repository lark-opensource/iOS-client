//
//  Message+Status.swift
//  LarkMessageCore
//
//  Created by Meng on 2019/4/9.
//

import UIKit
import Foundation
import LarkModel

extension LarkModel.Message {

    internal var successPercent: CGFloat {
        var total = unreadCount + readCount - 1
        var read = readCount - 1
        if isUrgent {
            total = Int32(ackUrgentChatterIds.count + unackUrgentChatterIds.count)
            read = Int32(ackUrgentChatterIds.count)
        }
        return _calculatePercent(read: read, total: total)
    }

    private func _calculatePercent(read: Int32, total: Int32) -> CGFloat {
        guard total > 0 else { return read == total ? 1.0 : 0.0 }
        let percent = CGFloat(read) / CGFloat(total) * 100.0
        switch percent {
        case 0.0:
            return 0.0
        case 0.0..<5.56:                            // 20度
            return CGFloat(20.0) / CGFloat(360.0)
        case 5.56..<90.56:                          // 实际百分比
            return percent / 100.0
        case 90.56..<100.0:                         // 326度
            return CGFloat(326.0) / CGFloat(360.0)
        case 100.0:                                 // 360度
            return 1.0
        default:
            return 0.0
        }
    }

}
