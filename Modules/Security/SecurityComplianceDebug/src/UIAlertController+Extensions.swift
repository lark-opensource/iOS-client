//
//  UIAlertController+Extensions.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/12/6.
//

import Foundation
import UIKit

extension UIAlertController {
    static public func generateChoiceDialog<T>(choiceList: [T],
                                               getChoiceName: (T) -> String,
                                               complete: @escaping (T) -> Void) -> UIAlertController {
        let dialog = UIAlertController(title: "列表", message: nil, preferredStyle: .actionSheet)
        choiceList.forEach { choice in
            dialog.addAction(UIAlertAction(title: getChoiceName(choice), style: .default, handler: { _ in
                complete(choice)
            }))
        }
        dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
        return dialog
    }
}
