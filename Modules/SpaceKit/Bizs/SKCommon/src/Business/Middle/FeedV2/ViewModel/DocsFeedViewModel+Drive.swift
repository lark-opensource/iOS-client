//
//  DocsFeedViewModel+Drive.swift
//  SKCommon
//
//  Created by huayufan on 2021/6/20.
//  


import SKUIKit

extension DocsFeedViewModel {

    func setupNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeGapStatus(_ :)),
                                               name: Notification.Name.CommentFeedV2Back,
                                               object: nil)
        
        NotificationCenter.default.post(name: Notification.Name.BrowserFullscreenMode,
                                        object: nil,
                                        userInfo: ["enterFullscreen": true,
                                                   "token": docsInfo.objToken])
    }
    
    @objc
    func changeGapStatus(_ notification: Notification) {
        guard let userInfo = notification.userInfo as? [String: Any] else { return }
        guard let state = userInfo["gapState"] as? DraggableViewController.GapState else { return }
        self.output?.gapStateRelay.accept(state)
    }
}
