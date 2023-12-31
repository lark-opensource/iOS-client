//
//  BitableHomeTabCreateDependency.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/10/27.
//

import Foundation
import LarkContainer
import SKCommon
import LarkQuickLaunchInterface
import SKFoundation

public final class BitableHomeTabCreateDependency {
    public static func createHomePage(context: BaseHomeContext) -> BitableHomeTabViewController {
        let traceId = BTOpenHomeReportMonitor.reportStart(context: context)
        var realContext = context
        realContext.addExtra(key: BaseHomeContext.openHomeTraceId, value: traceId, overwrite: true)

        let vc = BitableHomeTabViewController(context: realContext)
        return vc
    }
}
