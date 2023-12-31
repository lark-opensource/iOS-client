//
//  EditViewControllerGenerator.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/2/7.
//

import Foundation
import UIKit
import LarkContainer

class EditViewControllerGenerator {
    static func generateEditViewController(userResolver: UserResolver,
                                           focusStatus: UserFocusStatus,
                                           onDeletingSuccess: ((UserFocusStatus, [Int64: UserFocusStatus]) -> Void)?,
                                           onUpdatingSuccess: ((UserFocusStatus) -> Void)?) -> UIViewController {
        let focusManager = try? userResolver.resolve(assert: FocusManager.self)
        if focusManager?.isStatusNoteEnabled ?? false {
            let editVC = FocusEditController(userResolver: userResolver, focusStatus: focusStatus)
            editVC.onDeletingSuccess = onDeletingSuccess
            editVC.onUpdatingSuccess = onUpdatingSuccess
            return editVC
        } else {
            let editVC = FocusEditNoDescController(userResolver: userResolver, focusStatus: focusStatus)
            editVC.onDeletingSuccess = onDeletingSuccess
            editVC.onUpdatingSuccess = onUpdatingSuccess
            return editVC
        }
    }
}
