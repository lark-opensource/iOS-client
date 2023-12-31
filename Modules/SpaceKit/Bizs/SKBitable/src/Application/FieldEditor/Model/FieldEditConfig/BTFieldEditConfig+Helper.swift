//
//  BTFieldEditConfig+Helper.swift
//  SKBitable
//
//  Created by yinyuan on 2023/3/1.
//

import Foundation
import SKFoundation

// Helper
extension BTFieldEditConfig {
    func trackEditViewEvent(eventType: DocsTracker.EventType,
                            params: [String: Any]) {
        guard let viewController = viewController, let viewModel = viewModel else {
            return
        }
        viewController.delegate?.trackEditViewEvent(eventType: eventType, params: params, fieldEditModel: viewModel.fieldEditModel)
    }
}
