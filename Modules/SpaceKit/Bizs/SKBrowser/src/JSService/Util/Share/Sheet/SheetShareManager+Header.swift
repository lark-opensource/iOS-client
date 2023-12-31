//
// Created by duanxiaochen.7 on 2021/2/7.
// Affiliated with SKBrowser.
//
// Description:

import SKFoundation
import SKUIKit
import SKCommon

// MARK: header定义
extension SheetShareManager {
    func handleShowShareTitle(_ params: [String: Any]) {

        guard let bvc = self.registeredVC, let containerView = bvc.view else {
            return
        }

        self.shareHeaderView?.stopInterceptPopGesture()
        self.shareHeaderView?.removeFromSuperview()
        self.shareHeaderView = nil
        
        let shareHeaderView = SheetShareCustomHeaderView()
        self.shareHeaderView = shareHeaderView

        containerView.addSubview(shareHeaderView)

        shareHeaderView.snp.makeConstraints { (make) in
            make.size.equalTo(bvc.navigationBar)
            make.center.equalTo(bvc.navigationBar)
        }
        shareHeaderView.style = .light

        shareHeaderView.startInterceptPopGesture(gesture: bvc.navigationController?.interactivePopGestureRecognizer)
        
        forcePortraint(force: true)

        if var naviInfo = SheetNaviInfo.deserialize(from: params) {
            naviInfo.rightItem = naviInfo.rightItem.map({ (itemInfo) -> SheetNaviItemInfo in
                var result = itemInfo
                result.callback = { [weak self] in
                    self?.callJSService(DocsJSCallBack(naviInfo.callback), params: params)
                }
                return result
            })

            shareHeaderView.exitAction = { [weak self] in
                guard let self = self else {
                    return
                }
                DocsLogger.info("sheetShareManager sheet点击退出按钮")
                self.callJSService(DocsJSCallBack.sheetTitleExit, params: [:])
                self.restoreStatusAndFreeCache()
                DocsLogger.info("sheetShareManager alert点击退出隐藏loading")
                self.hideLoadingTip()
            }
            shareHeaderView.setup(info: naviInfo)
        }

        shareHeaderViewIsShown.onNext(true)
    }

    func handleHideSheetTitle(_ params: [String: Any]) {
        forcePortraint(force: false)
        shareHeaderView?.stopInterceptPopGesture()
        shareHeaderView?.removeFromSuperview()
        shareHeaderViewIsShown.onNext(false)
        shareHeaderView?.stopInterceptPopGesture()
    }
}
