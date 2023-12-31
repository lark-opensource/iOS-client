//
//  DocsConfig.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/2/18.
//

import Foundation

public enum DocContext {
    case syncedBlock(parentToken: String?)
}

/// 打开一篇文档时，需要传递一些配置进来
public struct FileConfig {
    public var isExternal: Bool?
    public var chatId: String?
    public var feedID: String?
    public var openSessionID: String?
    public var browserType: BaseViewController.Type
    public var extraInfos: [String: String]? {
        didSet {
            if let fid = extraInfos?["feedID"] {
                feedID = fid
            }
        }
    }

    public var feedFromInfo: FeedFromInfo?
    // 打开文档来源
    //- 网页：可能是网页appid，也可能是url，优先传 appid
    //- 小程序：小程序app_id
    public var openDocDesc: String?
    
    //文档打开的来源信息，例如同步块的源文档token
    public var docContext: DocContext?
    // 网页应用一事一档功能，传过来的当前网页url
    public var associateAppUrl: String?
    public var associateAppUrlMetaId: Int?

    public init(vcType: BaseViewController.Type) {
        self.browserType = vcType
    }
}
