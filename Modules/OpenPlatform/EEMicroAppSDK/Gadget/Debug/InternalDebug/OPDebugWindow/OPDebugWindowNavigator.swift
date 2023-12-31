//
//  OPDebugWindowNavigator.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/2/22.
//

import UIKit

class OPDebugWindowNavigator: UINavigationController {
    weak var moveDelegate: OPDebugCommandWindowMoveDelegate?

    override func viewDidLoad() {
        view.layer.cornerRadius = OPDebugWindowLayout.windowRadius
        view.layer.masksToBounds = true
    }

    /// 用户交互行为
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 如果navigationBar.isHidden为true，则代表导航栏隐藏依赖了，不应该再继续接受用户的交互行为了
        if navigationBar.isHidden { return }
        moveDelegate?.touchBegan(touches.randomElement())
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if navigationBar.isHidden { return }
        moveDelegate?.touchMoved(touches.randomElement())
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if navigationBar.isHidden { return }
        moveDelegate?.touchEnded(touches.randomElement())
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if navigationBar.isHidden { return }
        moveDelegate?.touchEnded(touches.randomElement())
    }
}
