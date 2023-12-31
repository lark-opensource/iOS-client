//
//  DKFeedModule.swift
//  SKDrive
//
//  Created by majie on 2021/8/24.
//
import Foundation
import SKCommon
import SKResource
import SKFoundation
import EENavigator
import RxSwift
import RxCocoa

class DKFeedModule: DKBaseSubModule {
    deinit {
        DocsLogger.driveInfo("DKFeedModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }

            if case .showFeed = action {
                self.showFeedVC()
            }
        }).disposed(by: bag)
        return self
    }
    
    func showFeedVC() {
        guard let host = hostModule, let hostVC = host.hostController, let manager = host.commentManager else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        var style: UIModalPresentationStyle
        if host.commonContext.isInVCFollow {
            style = .overFullScreen
        } else {
            style = .overCurrentContext
        }
        let feedViewController = manager.commentAdapter.constructMessageViewController(host.commonContext.feedFromInfo)
        feedViewController.modalPresentationStyle = style
        if let feedVC = feedViewController as? FeedPanelViewController {
            feedVC.supportOrientations = hostVC.supportedInterfaceOrientations
        }
        host.commentManager?.commentAdapter.fetchMessageData()
        hostVC.present(feedViewController, animated: true) {
            hostVC.resizeContentViewIfNeed(feedViewController.contentView.frame.height)
        }
        
        let params = ["notification_num": manager.messageUnreadCount.value]
        DriveStatistic.reportClickEvent(DocsTracker.EventType.navigationBarClick,
                                        clickEventType: DriveStatistic.DriveTopBarClickEventType.notification,
                                        fileId: fileInfo.fileToken,
                                        fileType: fileInfo.fileType,
                                        params: params)
    }
}
