//
//  CommonListCustomViewMannger.swift
//  SKUIKit
//
//  Created by zoujie on 2023/7/26.
//  


import SKFoundation

// 组装commonList的headrView
final public class CommonListCustomViewMannger {
    
    init() {}
    
    static let shared = CommonListCustomViewMannger()
    
    func getHeadertView(by key: CommonListCustomViewType,
                        params: BTPanelItemActionParams,
                        onClick: ((String) -> Void)?) -> CommonListBaseHeaderView {
        var customView: CommonListBaseHeaderView
        switch key {
        case .AVATAR_HEADER:
            customView = CommnoListAvatarHeader(model: params)
        default:
            customView = CommonListCustomHeader(model: params)
        }
        
        customView.clickCallback = onClick
        return customView
    }
}
