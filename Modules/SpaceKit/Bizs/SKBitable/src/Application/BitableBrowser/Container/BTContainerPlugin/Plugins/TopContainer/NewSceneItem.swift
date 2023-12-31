//
//  NewSceneItem.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/20.
//

import SKFoundation
import LarkSplitViewController
import SKUIKit

private class NewSceneItemWrapper: UIView, SKBarButtonCustomInsetable {
    var offset: CGPoint {
        return CGPoint(x: -4, y: 0)
    }
}

func generateNewSceneItem(clickCallBack: @escaping (() -> Void), sceneId: String) -> SKBarButtonItem {
    let button = SceneButtonItem(clickCallBack: { _ in
        clickCallBack()
    }, sceneKey: "Docs", sceneId: sceneId)
    let buttonHeight: CGFloat = 24.0
    let wapperView = NewSceneItemWrapper()
    wapperView.addSubview(button)
    button.snp.makeConstraints { (maker) in
        maker.height.width.equalTo(buttonHeight)
        maker.center.equalToSuperview()
    }
    let scale: CGFloat =  BTContainer.Constaints.navBarIconHeight / buttonHeight
    button.transform = CGAffineTransform(scaleX: scale, y: scale)
    wapperView.frame = CGRect(origin: .zero, size: BTContainer.Constaints.navBarButtonBackgroundSize)
    wapperView.backgroundColor = BTContainer.Constaints.navBarButtonBackgroundColor
    wapperView.layer.cornerRadius = BTContainer.Constaints.navBarButtonBackgroundCornerRadius
    wapperView.layer.masksToBounds = true
    return SKBarButtonItem(customView: wapperView)
}
