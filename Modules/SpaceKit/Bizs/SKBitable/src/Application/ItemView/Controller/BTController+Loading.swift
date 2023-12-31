//
//  BTController+Loading.swift
//  SKBitable
//
//  Created by X-MAN on 2023/10/10.
//

import Foundation
import SkeletonView
import SKFoundation

extension BTController {
    func isLoading() -> Bool {
        return self.loadingView.isHidden == false
    }
    
    func showLoading(from: BTViewMode) {
        // 数据已经加载完成就不show loading 了
        guard !self.didLoadInitData else { return }
        self.loadingView.alpha = 1
        self.loadingView.isHidden = false
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        self.loadingView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        self.loadingView.startSkeletonAnimation()
        DocsLogger.btInfo("[BTController] show loading form \(from.description)")
    }
    
    func hideLoading(from: BTViewMode, force: Bool = false) {
        if force {
            self.loadingView.isHidden = true
            DocsLogger.btInfo("[BTController] force hide loading form \(from.description)")
            return
        }
        guard isLoading() else {
            DocsLogger.btInfo("[BTController] hide loading form \(from.description) failed not show")
            return
        }
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.loadingView.alpha = 0
        } completion: { [weak self] _ in
            self?.loadingView.isHidden = true
            self?.loadingView.hideSkeleton()
            DocsLogger.btInfo("[BTController] hide loading form \(from.description)")
        }
    }
}

extension BTController: BTCardLoadingViewDelegate {
    func didClickClose() {
        closeThisCard()
    }
}
