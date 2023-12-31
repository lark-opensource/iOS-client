//
//  BTNativeCardTracker.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/13.
//

import Foundation
import SKFoundation

class BTNativeCardTracker {
        
    static func pageView() {
        var params: [String: Any] = [
            "mobile_grid_type": "mobile_card_layout"
        ]
        // 暂时又前端埋，后续有需要加Native的埋点，放到这里
//        params.merge(other: CardViewConstant.commonParams)
//        DocsTracker.newLog(enumEvent: .baseContentPageView, parameters: params)
    }
}
