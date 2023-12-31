//
//  PickerRouterType.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/2/23.
//

import UIKit
import LarkModel

protocol PickerRouterType {
    func pushToMultiSelectedPage(from: UIViewController, picker: Picker, context: PickerContext, completion handler: @escaping ((UIViewController) -> Void))

    func presentToTargetPreviewPage(from: UIViewController, item: PickerItem)
}
