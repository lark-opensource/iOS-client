//
//  MinutesDependency.swift
//  Minutes
//
//  Created by Supeng on 2021/10/14.
//

import Foundation
import UIKit
import EENavigator

public protocol MinutesMeetingDependency {

    var isInMeeting: Bool { get }
    
    var mutexDidChangeNotificationName: NSNotification.Name? { get }
    var mutexDidChangeNotificationKey: String { get }
}

public protocol MinutesLarkLiveDependency {
    
    var isInLiving: Bool { get }

    func stopLiving()
}

public protocol MinutesDocsDependency {
    func openDocShareViewController(token: String,
                                    type: Int,
                                    isOwner: Bool,
                                    ownerID: String,
                                    ownerName: String,
                                    url: String,
                                    title: String,
                                    tenantID: String,
                                    needPopover: Bool?,
                                    padPopDirection: UIPopoverArrowDirection?,
                                    popoverSourceFrame: CGRect?,
                                    sourceView: UIView?,
                                    isInVideoConference: Bool,
                                    hostViewController: UIViewController)
    
    ///异步获取icon图片
    ///支持通过url进行兜底显示
    func getDocsIconImageAsync(url: String, finish: @escaping (UIImage) -> Void)
}

public protocol MinutesMessengerDependency {
    func pushOrPresentShareContentBody(text: String, from: NavigatorFrom?)
    func pushOrPresentPersonCardBody(chatterID: String, from: NavigatorFrom?)

    func showEnterpriseTopic(abbrId: String, query: String)
    func dismissEnterpriseTopic()
}

public protocol MinutesConfigDependency {
    func getUserAgreementURL() -> URL?
}

public protocol MinutesDependency {
    var meeting: MinutesMeetingDependency? { get }
    var docs: MinutesDocsDependency? { get }
    var messenger: MinutesMessengerDependency? { get }
    var larkLive: MinutesLarkLiveDependency? { get }
    var config: MinutesConfigDependency? { get }
    
    func isShareEnabled() -> Bool
}

extension NSNotification.Name {
    public static let minutesMeetingWindowObserver = NSNotification.Name("minutesMeetingWindowObserver")
}

public let minutesMeetingWindowKey = "minutesMeetingWindowKey"
