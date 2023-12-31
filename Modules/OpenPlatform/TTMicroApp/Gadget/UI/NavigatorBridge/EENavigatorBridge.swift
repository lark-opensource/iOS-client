//
//  EENavigatorBridge.swift
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/10.
//

import EENavigator
import LarkOPInterface
import LarkUIKit
import LKCommonsLogging
import LarkSplitViewController

@objcMembers
open class EENavigatorBridge: NSObject {

    private static let logger = Logger.oplog(EENavigatorBridge.self, category: "Gadget.EENavigatorBridge")
    // 关闭小程序UI通用逻辑：可能是点了关闭按钮，也可能是加载失败
    // 小程序目前内部打开方式分为 present 和 push， UI架构从底至顶分别如下：
    // push: UINavigationController(push 小程序的 host navi，在lark里是LkNavigationController) -> other vcs（navi里的其他vc）-> BDPBaseContainerController(BDPAppController，小程序vc)
    // present: vc (present 小程序的 host vc) -> BDPRootNavigatonController -> BDPBaseContainerController(BDPAppController， 小程序vc)
    public class func closeMiniProgram(with container: UIViewController, completion: ((Bool) -> Void)?) {

        guard let container = container as? BDPBaseContainerController else {
            EENavigatorBridge.logger.error("can not close mp with wrong container")
            return
        }
        
        // present 打开的小程序
        if container.presentingViewController != nil {
            if container.navigationController as? BDPRootNavigationController == nil {
                EENavigatorBridge.logger.warn("close presented mp \(container.uniqueID), but has navigation is not BDPRootNavigationController")
            }
            container.dismiss(animated: true) {
                completion?(true)
            }
            return
        }

        // push 打开的小程序
        guard let navi = container.navigationController else {
            completion?(false)
            EENavigatorBridge.logger.error("close pushed mp \(container.uniqueID), but has no navigation")
            return
        }
        if navi.viewControllers.count > 1 {
            navi.popViewController(animated: true)
            completion?(true)
            return
        }

        // 理论上，iPhone不应该走到这里了
        guard Display.pad else {
            assertionFailure("iphone can not close pushed mp \(container.uniqueID) because navi is empty after pop")
            completion?(false)
            EENavigatorBridge.logger.error("close pushed mp \(container.uniqueID) but navi is empty after pop")
            return
        }
        Navigator.shared.showDetail(LKSplitViewController2.DefaultDetailController(), wrap: LkNavigationController.self, from: container) {
            completion?(true)
        }
    }
    
    // 避免小程序内部导航被主端探测并用于 push 其他 VC
    public class func setSupportNavigator(viewController: UIViewController, supportNavigator: Bool) {
        viewController.supportNavigator = supportNavigator
    }
}
