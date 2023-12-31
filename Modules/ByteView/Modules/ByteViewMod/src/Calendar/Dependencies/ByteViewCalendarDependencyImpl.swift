//
//  ByteViewCalendarDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/30.
//

import Foundation
import Calendar
import LarkContainer
import ByteViewCalendar
import ByteViewNetwork
#if MessengerMod
import LarkMessengerInterface
#endif
import RustPB

final class ByteViewCalendarDependencyImpl: ByteViewCalendarDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func gotoUpgrade(from: UIViewController) {
        #if MessengerMod
        userResolver.navigator.push(body: MineAboutLarkBody(), from: from)
        #endif
    }

    func showPstnPhones(meetingNumber: String, phones: [PSTNPhone], from: UIViewController) {
        let body = PstnPhonesBody(meetingNumber: meetingNumber, phones: phones)
        if let vc = userResolver.navigator.response(for: body).resource as? UIViewController {
            from.presentDynamicModal(vc, regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                     compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        }
    }
}
