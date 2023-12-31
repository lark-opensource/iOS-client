//
//  ForwardViewControllerService.swift
//  LarkForward
//
//  Created by Prontera on 2020/4/3.
//

import Foundation
import UIKit

public protocol ForwardViewControllerService {
    func forwardViewController(with content: ForwardAlertContent) -> UIViewController?
    func forwardComponentViewController(alertContent: ForwardAlertContent,
                                        commonConfig: ForwardCommonConfig,
                                        targetConfig: ForwardTargetConfig,
                                        additionNoteConfig: ForwardAdditionNoteConfig,
                                        chooseConfig: ForwardChooseConfig) -> UIViewController?
    func getForwardVC(provider: ForwardAlertProvider, delegate: ForwardComponentDelegate?) -> ForwardComponentVCType
}
