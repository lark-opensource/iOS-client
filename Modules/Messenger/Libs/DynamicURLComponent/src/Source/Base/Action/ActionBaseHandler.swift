//
//  ActionBaseHandler.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/11/30.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkModel
import EENavigator
import LarkContainer
import LarkRustClient

public protocol ActionBaseHandler {
    static func handleAction(entity: URLPreviewEntity?,
                             action: Basic_V1_UrlPreviewAction,
                             actionID: String,
                             dependency: URLCardDependency,
                             completion: ActionCompletionHandler?,
                             actionDepth: Int)
}

func mainOrAsync(task: @escaping () -> Void) {
    if Thread.isMainThread {
        task()
    } else {
        DispatchQueue.main.async { task() }
    }
}
