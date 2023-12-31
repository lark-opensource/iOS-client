//
//  AnnouncementDelegate.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/2.
//  


import Foundation
import RxSwift
import UIKit


public struct AnnouncementPublishAlertParams {
    public var chatId: String
    public var docUrl: String
    public var thumbnailUrl: String
    public var objToken: String
    public var changed: Bool
    public var fromVc: UIViewController
    public var targetView: UIView
    
    public init(chatId: String, docUrl: String, thumbnailUrl: String, objToken: String, changed: Bool, fromVc: UIViewController, targetView: UIView) {
        self.chatId = chatId
        self.docUrl = docUrl
        self.thumbnailUrl = thumbnailUrl
        self.objToken = objToken
        self.changed = changed
        self.fromVc = fromVc
        self.targetView = targetView
    }
}

public protocol AnnouncementDelegate: AnyObject {
    func didEndEdit(_ docUrl: String,
                    thumbnailUrl: String,
                    chatId: String,
                    changed: Bool,
                    from: UIViewController,
                    syncThumbBlock: ((PublishSubject<Any>) -> Void)?)
    
    func showPublishAlert(params: AnnouncementPublishAlertParams)
}

public protocol AnnouncementViewControllerBase: AnyObject {
    func setAnnouncementStatus(_ canAnnounce: Bool)
}
