//
//  LarkLiveDependency.swift
//  LarkLive
//
//  Created by panzaofeng on 2021/10/14.
//

import Foundation
import UIKit
import EENavigator
import LarkAccountInterface

public protocol LarkLiveDependency {
    
    var isInRecording: Bool { get }

    var isInMeeting: Bool { get }

    var isInPodcast: Bool { get }

    func stopPodcast()

    func pushOrPresentShareContentBody(text: String, from: NavigatorFrom?, style: Int)

    func getLocalUserInfo() -> (name: String, url: String, userId: String)
    
    func getAccountTenant() -> LarkAccountInterface.Tenant?
}
