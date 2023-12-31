//
//  MinutesScene.swift
//  LarkMinutes
//
//  Created by lvdaqian on 2021/8/9.
//

import Foundation
import LarkSceneManager
import EENavigator
import LarkUIKit
import MinutesNavigator
import LKCommonsLogging
import Minutes
import LarkContainer

@available(iOS 13.0, *)
public struct MinutesScene: SceneConfig {
    public static let key = "Minutes"
    public static func icon() -> UIImage {
        MinutesOpenResource.ipadSwitcherIcon
    }

    static let logger = Logger.log(MinutesScene.self, category: "Minutes")

    public static func createRootVC(scene: UIScene, session: UISceneSession, options: UIScene.ConnectionOptions, sceneInfo: Scene, localContext: AnyObject?) -> UIViewController? {

        logger.info("perpare to create root vc for id: \(sceneInfo.id).")

        if let vc = localContext as? UIViewController {
            if vc is UINavigationController {
                logger.info("localContext is UINavigationController(\(type(of: vc))), use it.")
                return vc
            }
            logger.info("localContext is not UINavigationController(\(type(of: vc))), wrap it.")
            return LkNavigationController(rootViewController: vc)
        }

        let navi = LkNavigationController()
        navi.view.backgroundColor = UIColor.ud.bgBody

        let userResolver = Container.shared.getCurrentUserResolver()
        
        switch sceneInfo.id {
        case "home":
            userResolver.navigator.push(body: MinutesHomePageBody(fromSource: .others), naviParams: nil, context: sceneInfo.userInfo, from: navi, animated: false, completion: nil)
        case "me":
            userResolver.navigator.push(body: MinutesHomeMeBody(fromSource: .others), naviParams: nil, context: sceneInfo.userInfo, from: navi, animated: false, completion: nil)
        case "shared":
            userResolver.navigator.push(body: MinutesHomeMeBody(fromSource: .others), naviParams: nil, context: sceneInfo.userInfo, from: navi, animated: false, completion: nil)
        case "trash":
            userResolver.navigator.push(body: MinutesHomeTrashBody(fromSource: .others), naviParams: nil, context: sceneInfo.userInfo, from: navi, animated: false, completion: nil)
        default:
            if let url = URL(string: sceneInfo.id) {
                userResolver.navigator.push(url, context: sceneInfo.userInfo, from: navi, animated: false, completion: nil)
            } else {
                logger.warn("can't push \(sceneInfo.id) as URL.")
            }
        }

        return navi
    }
}
