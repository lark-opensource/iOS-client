//
//  CommentNavigationController.swift
//  SKCommon
//
//  Created by huayufan on 2022/10/20.
//  


import SKUIKit
import SKCommon

public final class DocCommentNavigationController: SKNavigationController, HierarchyIndependentController {
    public var businessIdentifier: String = "DocComment"
    // 可能会显示正文图片在底部，优先级定为20，评论图片为30
    public var hierarchyPriority: HierarchyIndependentPriority = .comment
    
    public var representEnable: Bool = true
    
    public var willDismissCallback: (() -> Void)?
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if presentingViewController == nil {
            willDismissCallback?()
        }
        super.dismiss(animated: flag, completion: completion)
    }
}
