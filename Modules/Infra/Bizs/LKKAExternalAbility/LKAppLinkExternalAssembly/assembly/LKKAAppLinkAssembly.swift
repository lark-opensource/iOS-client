import UIKit
import Foundation
import LarkAssembler
import EENavigator
import Swinject
import LKAppLinkExternal
import LKNativeAppContainer
import LKCommonsLogging

public class LKNativeAssembly: LarkAssemblyInterface {
    public init() {
        _ = NativeAppContainer.shared
        KAAppLinkExternal.shared.navigator = Navigator.shared
    }
    public func registUnloginWhitelist(container: Container) {
        "//applink.feishu.cn/client/native_extension/open"
    }
}

extension Navigator: KANavigator {
    var logger: Log {
        Logger.log(LKNativeAssembly.self, category: "KANavigator")
    }
    public func push(vc: UIViewController, style: LKAppLinkExternal.KAPushStyle, completion: LKAppLinkExternal.KACompletion?) {
        logger.info("KANavigator will push vc, style: \(style)")
        switch style {
        case .detail:
            showDetail(vc, from: getTopVC(), completion: completion)
        default:
            push(vc, from: getTopVC(), completion: completion)
        }
    }
    
    public func present(vc: UIViewController, completion: LKAppLinkExternal.KACompletion?) {
        logger.info("KANavigator will present vc")
        present(vc, from: getTopVC(), completion: completion)
    }
    
    public func pop(vc: UIViewController, completion: LKAppLinkExternal.KACompletion?) {
        logger.info("will pop vc")
        var vcs = getTopVC().navigationController?.viewControllers
        if vc == vcs?.last {
            pop(from: getTopVC(), completion: nil)
        } else {
            vcs?.removeAll(where: { temp in
                temp == vc
            })
            logger.info("KANavigator will remove vc")
            getTopVC().navigationController?.viewControllers = vcs ?? []
        }
    }
  
    public func open(url: NSURL, from: UIViewController) {
        push(url as URL, from: from)
    }
    
    private func getTopVC() -> UIViewController {
        let vc = mainSceneTopMost
        logger.info("KANavigator top vc: \(mainSceneTopMost.debugDescription)")
        return vc ?? UIViewController()
    }
}
