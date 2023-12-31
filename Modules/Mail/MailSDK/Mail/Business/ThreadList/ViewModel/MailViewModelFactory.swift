//
//  MailViewModelFactory.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/23.
//

import Foundation
import LKCommonsLogging

var MailViewModelFactory: MailViewModelFactoryImp {
    return MailViewModelFactoryImp.shared
}

class MailViewModelFactoryImp {
    static let shared = MailViewModelFactoryImp()

    let logger = Logger.log(MailViewModelFactoryImp.self, category: "Module.Mail")
}

// MARK: Home ViewModel
extension MailViewModelFactoryImp {
    func creatMailHomeInitViewModel(userContext: MailUserContext) -> MailHomeViewModel {
        if let vm = userContext.bootManager.homePreloader.consumeViewModelIfNeeded() {
            logger.info("creatMailHomeInitViewModel used preloaded")
            return vm
        }

        return MailHomeViewModel(userContext: userContext)
    }
}
