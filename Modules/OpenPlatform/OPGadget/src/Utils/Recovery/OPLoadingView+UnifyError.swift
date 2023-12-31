//
//  OPLoadingView+UnifyError.swift
//  OPGadget
//
//  Created by qianhongqiang on 2022/6/07.
//

import Foundation
import OPSDK
import TTMicroApp
import LKCommonsLogging

private let logger = Logger.log(OPLoadingView.self, category: "OPLoadingView")

extension OPLoadingView {
    func changeToErrorState(errorStyle: UnifyExceptionStyle, uniqueID: OPAppUniqueID) {
        emptyView.removeFromSuperview()
        
        bindUniqueID(uniqueID)
        
        let imageType = OPLoadingView.EmptyViewImageType(rawValue: errorStyle.image) ?? .loadError
        
        let emptyView = createEmptyView(imageType: imageType,
                                                     title: errorStyle.title,
                                                     content: errorStyle.content,
                                                     primaryText: errorStyle.actions?.primaryButton?.actionText) { [weak self] _ in
            guard let self = self else { return }
            if errorStyle.actions?.primaryButton?.clickEvent == .restart {
                if let container = OPApplicationService.current.getContainer(uniuqeID: self.uniqueID) {
                    container.reload(monitorCode: GDMonitorCode.unify_error_restart)
                }
            } else {
                logger.error("unsupport click event \(String(describing: errorStyle.actions?.primaryButton?.clickEvent))")
            }
            
            self.loadingView.isHidden = false
            self.loadingView.startLoading()
            self.titleView.isHidden = false
            self.logoView.isHidden = false
            self.topTitleView.isHidden = true
            self.emptyView.removeFromSuperview()
        }
        
        change(to: emptyView)
        
        topTitleView.isHidden = false
        loadingView.stopLoading()
        loadingView.isHidden = true
        titleView.isHidden = true
        logoView.isHidden = true
    }
}
