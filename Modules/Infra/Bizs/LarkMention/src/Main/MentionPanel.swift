//
//  MentionPanel.swift
//  LarkMention-Core-Model-Resources-Util-View
//
//  Created by Yuri on 2022/6/9.
//

import UIKit
import Foundation
import LarkContainer

/// mention面板
public final class MentionPanel: MentionType {
    public var passthroughViews: [UIView]?
    
    public var sourceView: UIView?
    
    public weak var delegate: MentionPanelDelegate?
    
    public var defaultItems: [PickerOptionType]?
    
    public var provider: MentionDataProviderType?
    
    public var recommendItems: [PickerOptionType]?
    
    public var uiParameters: MentionUIParameters = MentionUIParameters()
    
    public var searchParameters: MentionSearchParameters = MentionSearchParameters()
    
    /// 面板展示所在业务，埋点需要
    public var productLevel: String?
    /// 面板展示所在业务场景，埋点需要
    public var scene: String?
    
    public func addTab(search parameters: MentionSearchParameters) {
    }

    public let userResolver: LarkContainer.UserResolver
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    public func show(from vc: UIViewController) {
        // mention埋点
        let mentionTracker = MentionTraker(productLevel: productLevel ?? "", scene: scene ?? "")
        var prov = provider
#if canImport(LarkSearchCore)
        prov = provider ?? MentionDataProvider(resolver: self.userResolver, parameters: searchParameters)
#else
#endif
        let mentionVc = MentionViewController(mentionTracker: mentionTracker, uiParameters: uiParameters, searchParameters: searchParameters, provider: prov)
        mentionVc.passthroughViews = passthroughViews
        mentionVc.delegate = delegate
        mentionVc.recommendItems = recommendItems
        self.mentionVC = mentionVc
        mentionVc.show(from: vc, sourceView: sourceView)
    }
    
    public func close() {
        mentionVC?.onDismiss()
    }
    
    public func search(text: String) {
        mentionVC?.search(text: text)
    }
    // MARK: - Private
    private weak var mentionVC: MentionViewController?
}
