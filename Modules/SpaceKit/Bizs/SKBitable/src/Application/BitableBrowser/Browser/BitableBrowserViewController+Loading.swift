//
//  BitableBrowserViewController+Loading.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/8.
//

import Foundation

extension BitableBrowserViewController {
    
    func showBitableLoading(from: String, loadingType: BTContainerLoadingPlugin.LoadingType) {
        container.getOrCreatePlugin(BTContainerLoadingPlugin.self).showSkeletonLoading(from: from, loadingType: loadingType)
    }
    
    func hideBitableLoading(from: String, loadingType: BTContainerLoadingPlugin.LoadingType) {
        switch loadingType {
        case .all:
            container.getOrCreatePlugin(BTContainerLoadingPlugin.self).hideAllSkeleton(from: from)
        case .main, .onlyBody, .onlyHeader:
            container.getOrCreatePlugin(BTContainerLoadingPlugin.self).hideSkeletonLoading(from: from, loadingType: loadingType)
        }
        
    }
    
}
