//
//  MinutesClipViewController+More+More.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

import UIKit
import EENavigator
import MinutesNavigator
import MinutesFoundation
import MinutesNetwork
import LarkAlertController
import UniverseDesignToast
import Kingfisher
import UniverseDesignColor
import LarkFeatureGating
import LarkGuide
import LarkGuideUI
import AppReciableSDK
//import SpaceInterface
import UniverseDesignIcon
import LarkSnsShare


extension MinutesClipViewController {
    var shouldShowShareItem: Bool {
        // reviewStatus为normal接口
        if isVideo {
            let reviewStatus = viewModel.minutes.info.reviewStatus
            return reviewStatus == .normal
        } else {
            return true
        }
    }
    
    var shouldShowTranslateItem: Bool {
        return true
    }
    var shouldShowDeleteItem: Bool {
        // 只有所有者可以删除
        if viewModel.minutes.basicInfo?.isOwner == true || viewModel.minutes.basicInfo?.clipInfo?.isClipCreator == true {
            return true
        } else {
            return false
        }
    }

    func presentMoreViewController() {
        guard let someBasicInfo = viewModel.minutes.basicInfo else { return }
        var items: [MinutesMoreItem] = []

        let tracker = self.tracker

        if shouldShowShareItem {
            let onClickShareClosure = { [weak self] in
                guard let self = self else { return }
                self.showShareSnsPanel()
            }
            let shareItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_Share, action: onClickShareClosure)

            items.append(shareItem)
        }

        if shouldShowTranslateItem {
            let onClickTranslateClosure = { [weak self] in
                guard let self = self else { return }

                self.tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_language_change"])

                if self.isInTranslationMode {
                    self.exitTranlation()
                } else {
                    if self.viewModel.minutes.data.subtitles.isEmpty {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: self.view)
                        return
                    }

                    if self.viewModel.minutes.basicInfo?.supportAsr == false {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow, on: self.view)
                        return
                    }
                    self.presentChooseTranlationLanVC(items: self.createTransItems())
                }
            }
            let image = UIImage.dynamicIcon(isInTranslationMode ? .iconTranslateCancelThin : .iconTranslateOutlined, dimension: 20, color: UIColor.ud.iconN1) ?? UIImage()
            let translateItem = MinutesMoreClickItem(icon: image,
                                                     title: isInTranslationMode ? BundleI18n.Minutes.MMWeb_G_ExitTranslation : BundleI18n.Minutes.MMWeb_G_Translate, action: onClickTranslateClosure)
            items.append(translateItem)
        }

        let startTime = TimeInterval(someBasicInfo.startTime) / 1000.0
        let duration = TimeInterval(someBasicInfo.duration) / 1000.0
        let minutesMoreViewController = MinutesMoreViewController(topic: someBasicInfo.topic,
                                                                  info: "\(BundleI18n.Minutes.MMWeb_G_OwnerColon)\(someBasicInfo.ownerInfo?.userName ?? "")",
                                                                  items: items, shouldShowDeleteItem: shouldShowDeleteItem)
        let placeholderImage: UIImage
        switch someBasicInfo.mediaType {
        case .audio:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
        case .text:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_text_width
        case .video:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_video_width
        default:
            placeholderImage = BundleResources.Minutes.minutes_feed_list_item_audio_width
        }
        minutesMoreViewController.coverImageView.kf.setImage(with: URL(string: someBasicInfo.videoCover),
                                                             placeholder: placeholderImage,
                                                             options: [.downloader(videoPlayer.imageDownloader)])
        minutesMoreViewController.delegate = self
        if traitCollection.horizontalSizeClass == .regular {
            let sv = moreSourceView ?? videoControlView.moreButton
            minutesMoreViewController.isRegular = true
            minutesMoreViewController.modalPresentationStyle = .popover
            minutesMoreViewController.popoverPresentationController?.backgroundColor = UIColor.ud.bgFloatBase
            minutesMoreViewController.popoverPresentationController?.sourceView = sv
            minutesMoreViewController.popoverPresentationController?.sourceRect = sv.bounds
            minutesMoreViewController.popoverPresentationController?.permittedArrowDirections = moreSourceView == nil ? .down : .up
            minutesMoreViewController.preferredContentSize = CGSize.init(width: 375, height: minutesMoreViewController.viewHeight)
        }
        present(minutesMoreViewController, animated: true, completion: nil)

        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.more)
        tracker.tracker(name: .clickButton, params: trackParams)

        tracker.tracker(name: .detailClick, params: ["click": "more", "target": "vc_minutes_detail_more_view"])
        tracker.tracker(name: .detailMoreView, params: [:])
    }
}

extension MinutesClipViewController {

    func showShareSnsPanel() {
        sharePanel.show(){ [weak self] result, itemType  in
            guard let self = self else { return }
            switch result {
            case .success:
                switch itemType {
                case .copy:
                    UDToast.showSuccess(with: BundleI18n.Minutes.MMWeb_G_CopiedSuccessfully, on: self.view)
                default:
                    MinutesLogger.detail.info("todo somthing")
                }
            case .failure(let errorCode, let debugMsg):
                switch errorCode {
                case .notInstalled:
                    UDToast.showFailure(with: "\(debugMsg)", on: self.view)
                case .userCanceledManually, .triggleDowngradeHandle:
                    MinutesLogger.detail.info("todo nothing")
                default:
                    UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_FailedToLoad, on: self.view)
                    MinutesLogger.detail.info("failed to share more show\(errorCode)errorMsg:\(debugMsg)")
                }
            }
        }
    }

    func hideSharePanel() {
        self.sharePanel.dismiss(animated: true, completion: nil)
    }

    // disable-lint: magic number
    func showShareToChat() {
        // 等待panel消失
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.75) {
            let url = self.viewModel.minutes.baseURL
            let from = self.userResolver.navigator.mainSceneTopMost
            self.dependency?.messenger?.pushOrPresentShareContentBody(text: url.absoluteString, from: from)

            var trackParams: [AnyHashable: Any] = [:]
            trackParams.append(.headerShareActionName)
            self.tracker.tracker(name: .clickButton, params: trackParams)
            self.tracker.tracker(name: .detailClick, params: ["click": "header_share", "target": "vc_minutes_share_view"])
        }
    }
    // enable-lint: magic number

    private func showAlertVC() {
        let alertVC = LarkAlertController()
        let message: String = BundleI18n.Minutes.MMWeb_G_ConfirmDeleteClip
        alertVC.setContent(text: message, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17))
        alertVC.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: { [weak self] in
            guard let wSelf = self else { return }

            wSelf.handleCancelTracker()
        })
        alertVC.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Delete, dismissCompletion: { [weak self] in
            guard let wSelf = self else { return }
            wSelf.requestDeleteMinuteClip()
            
            wSelf.handleDeleteTracker()
        })
        present(alertVC, animated: true)

        tracker.tracker(name: .detailMoreClick, params: ["click": "delete", "object_type": "7"])
    }
    
    private func handleDeleteTracker() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.headerPageDelete)
        trackParams["action_result"] = "delete"
        tracker.tracker(name: .deleteClick, params: ["click": "confirm", "object_type": "7"])
    }
    
    private func handleCancelTracker() {
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.headerPageDelete)
        trackParams["action_result"] = "cancel"
        tracker.tracker(name: .clickButton, params: trackParams)
    }

    private func postDeleteClipNotification(withToken token: String) {
        NotificationCenter.default.post(name: NSNotification.Name.Clip.clipDidDelete, object: self, userInfo: ["token": token])
    }

    private func requestDeleteMinuteClip() {
        UDToast.showLoading(with: BundleI18n.Minutes.MMWeb_G_Loading, on: self.view)
        viewModel.requestDeleteClip(successHandler: { [weak self] in
            guard let self = self else { return }
            UDToast.removeToast(on: self.view)
            self.showMinutesClipResourceDeletedVC()
            self.postDeleteClipNotification(withToken: self.viewModel.minutes.objectToken)
        }, failureHandler: {[weak self] error in
            guard let self = self else { return }
            UDToast.removeToast(on: self.view)
            guard let someError = error as? ResponseError else { return }
            switch someError {
            case .resourceDeleted:
                self.showMinutesClipResourceDeletedVC()
                self.postDeleteClipNotification(withToken: self.viewModel.minutes.objectToken)
            default: break
            }
        })
    }

    private func showMinutesClipResourceDeletedVC() {
        self.videoPlayer.pause()
        let vc = MinutesErrorStatusViewController(resolver: userResolver, minutesStatus: MinutesInfoStatus.resourceDeleted, isClip: true)
        addChild(vc)
        view.addSubview(vc.view)
        view.bringSubviewToFront(vc.view)

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }

            wSelf.navigationController?.popViewController(animated: true)
        }
    }
}

extension MinutesClipViewController: MinutesDeleteItemDelegate {
    func deleteItem() {
        self.dismiss(animated: true, completion: nil)
        let onClickDeleteClosure = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.showAlertVC()
        }
        onClickDeleteClosure()
    }
}

extension MinutesClipViewController: LarkSharePanelDelegate {
    public func clickShareItem(at shareItemType: LarkShareItemType, in panel: PanelType) {
        if panel == .actionPanel {
            var actionName: String = ""
            switch shareItemType {
            case .copy:
                actionName = "copy_link"
                self.tracker.tracker(name: .clipListClick, params: ["click": "copy_link"])
            case .custom(let shareToLark):
                self.tracker.tracker(name: .clipListClick, params: ["click": "send_to_chat"])
                break
            default:
                break
            }
        }
    }
}

extension Notification.Name {
    struct Clip {
        static let clipDidDelete = Notification.Name(rawValue: "clip.clipDidDelete")
    }
}
