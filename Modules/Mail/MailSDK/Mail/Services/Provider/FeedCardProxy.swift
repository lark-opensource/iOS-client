//
//  FeedCardProxy.swift
//  MailSDK
//
//  Created by ByteDance on 2023/9/27.
//
import Foundation
import UniverseDesignIcon
public protocol FeedCardProxy {
    var noSubjectStr: String { get }
    var noContent: String { get }
    var editIcon: UIImage { get }
}

public extension FeedCardProxy {
    var noSubjectStr: String {
        return BundleI18n.MailSDK.Mail_ThreadList_TitleEmpty
    }
    
    var noContent: String {
        return BundleI18n.MailSDK.Mail_KeyContact_ChatPage_EmptyState
    }
    
    var editIcon: UIImage {
        return UDIcon.getIconByKey(.editContinueOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.R500, renderingMode: .alwaysTemplate)

    }
}
