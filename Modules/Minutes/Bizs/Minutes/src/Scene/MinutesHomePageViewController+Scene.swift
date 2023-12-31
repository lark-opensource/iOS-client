//
//  MinutesHomePageViewController+Scene.swift
//  Minutes
//
//  Created by lvdaqian on 2021/8/10.
//

import Foundation
import LarkSceneManager
import MinutesFoundation
import MinutesNetwork
import LarkUIKit

extension MinutesSpaceType {
    var sceneID: String {
        switch self {
        case .home:
            return "home"
        case .my:
            return "me"
        case .share:
            return "shared"
        case .trash:
            return "trash"
        }
    }
}

extension MinutesHomePageViewController: MinutesMultiSceneController {
    var sceneID: String {
        spaceType.sceneID
    }
}
