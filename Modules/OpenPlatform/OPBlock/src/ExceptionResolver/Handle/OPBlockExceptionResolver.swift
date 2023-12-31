//
//  OPBlockExceptionResolver.swift
//  OPBlock
//
//  Created by chenziyi on 2021/10/26.
//

import Foundation
import OPSDK
import LarkOPInterface
import ECOProbe
import LKCommonsLogging

private let logger = Logger.oplog(OPBlockExceptionResolver.self, category: "OPBlockExceptionResolver")

class OPBlockExceptionResolver {
    /// 处理guide info异常
    public static func resolve(error: OPError, router: OPBlockContainerRouter) {
        guard let item = GuideInfoStatusViewItems.dataMap[error] else {
            logger.error("[Block] No corresponding viewitem to this error: \(error.localizedDescription)")
            return
        }
        DispatchQueue.main.async {
            router.showStatusView(item: item)
        }
        GuideInfoStatusViewItems.dataMap.removeValue(forKey: error)
    }
}
