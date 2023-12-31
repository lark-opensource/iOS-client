//
//  LocalFileProvider.swift
//  LarkMail
//
//  Created by tefeng liu on 2019/6/6.
//

import Foundation
import MailSDK
import LarkModel
import LarkUIKit
import EENavigator
import LarkContainer
#if MessengerMod
import LarkMessengerInterface
#endif

#if MessengerMod
extension LocalAttachFile: MailSendFileInfoProtocol {}
#endif

class LocalFileProvider: LocalFileProxy {

    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func presentLocalFilePicker(params: LocalFileParams, wrap: UINavigationController.Type?, fromVC: UIViewController, closeCallBack: (() -> Void)?) {
#if MessengerMod
        var body = LocalFileBody()
        body.maxSelectCount = params.maxSelectCount
        body.maxTotalFileSize = params.maxTotalFileSize
        body.maxSingleFileSize = params.maxSingleFileSize
        body.chooseLocalFiles = params.chooseLocalFiles
        body.extraFilePaths = params.extraPaths
        body.title = params.title
        resolver.navigator.present(body: body,
                                 wrap: wrap ?? LkNavigationController.self,
                                 from: fromVC,
                                 prepare: { (vc) in
            let isPad = UIDevice.current.userInterfaceIdiom == .pad
            vc.modalPresentationStyle = isPad ? .formSheet : .overCurrentContext
            if let nav = vc as? UINavigationController {
                if let rootVC = nav.viewControllers[0] as? BaseUIViewController {
                    rootVC.closeCallback = closeCallBack
                }
            }
        })
#endif
    }

    func presentLocalFilePicker(params: LocalFileParams, wrap: UINavigationController.Type?, fromVC: UIViewController) {
        presentLocalFilePicker(params: params, wrap: wrap, fromVC: fromVC, closeCallBack: nil)
    }
}
