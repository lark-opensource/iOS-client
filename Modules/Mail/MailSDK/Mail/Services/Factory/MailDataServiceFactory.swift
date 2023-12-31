//
//  MailDataServiceFactory.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/8/15.
//

import Foundation
import LarkContainer

final class MailDataServiceFactory {
    static var commonDataService: DataService? {
        if let userContext = try? Container.shared.getCurrentUserResolver().resolve(assert: MailUserContext.self) {
            return userContext.dataService
        } else {
            mailAssertionFailure("[UserContainer] Access DataService before user login")
            return nil
        }
    }
}
