//
//  EmailDocRedirector.swift
//  SKCommon
//
//  Created by peilongfei on 2023/3/15.
//  


import SKFoundation
import UniverseDesignToast
import EENavigator
import RxSwift

class EmailDocRedirector {
    
    static func redirectToVCAfterBindEmail(resource: SKRouterResource, params: SKRouter.Params?) {
        guard let requestParams = resource.url.docs.queryParams else {
            DocsLogger.info("redirectToVCAfterBindEmail: queryParams is nil")
            return
        }
        guard let inviteToken = requestParams["invite"] else  {
            DocsLogger.info("redirectToVCAfterBindEmail: inviteToken is nil")
            return
        }
        guard let token = DocsUrlUtil.getFileInfoFrom(resource.url).token else {
            DocsLogger.info("redirectToVCAfterBindEmail: objtoken is nil")
            return
        }
        let fromVC = EmailDocRedirector.fromVC(with: params)
        let objType = resource.docsType.rawValue
        let newUrl = resource.url.remove(name: "invite")
        UDToast.showDefaultLoading(on: fromVC.view.window ?? fromVC.view)
        PermissionManager.emailInviteRelation(type: objType, token: token, inviteToken: inviteToken).subscribeOn(MainScheduler.instance).subscribe { _ in
            UDToast.removeToast(on: fromVC.view.window ?? fromVC.view)
            Navigator.shared.open(newUrl, from: fromVC)
        }
    }
    
    static func fromVC(with params: [AnyHashable: Any]?) -> UIViewController {
        if let context = params as? [String: Any],
           let from = context[ContextKeys.from],
           let fromWrapper = from as? NavigatorFromWrapper,
           let fromVC = fromWrapper.fromViewController {
            return fromVC
        } else if let vc = Navigator.shared.mainSceneWindow?.fromViewController {
            return vc
        } else {
            return UIViewController()
        }
    }
}
