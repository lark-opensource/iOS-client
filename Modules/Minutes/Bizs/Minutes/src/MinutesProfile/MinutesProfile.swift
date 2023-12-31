//
//  MinutesProfile.swift
//  Minutes
//
//  Created by panzaofeng on 2021/4/12.
//

import UIKit
import MinutesFoundation
import EENavigator
import LarkUIKit
//import LarkMessengerInterface
import RustPB
import LarkContainer

public final class MinutesProfile {
    public static func personProfile(chatterId: String, from: NavigatorFrom?, resolver: UserResolver?) {
        let dependency: MinutesDependency? = try? resolver?.resolve(assert: MinutesDependency.self)
        dependency?.messenger?.pushOrPresentPersonCardBody(chatterID: chatterId, from: from)
    }
}
