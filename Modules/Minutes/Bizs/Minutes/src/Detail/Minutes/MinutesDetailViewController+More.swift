//
//  MinutesDetailViewController+More.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/1/31.
//

import UIKit
import EENavigator
import MinutesNavigator
import MinutesFoundation
import MinutesNetwork
import LarkAlertController
import UniverseDesignToast
import UniverseDesignIcon
import Kingfisher
import UniverseDesignColor
import LarkFeatureGating
import LarkGuide
import LarkGuideUI
import AppReciableSDK
//import SpaceInterface
import UniverseDesignIcon

public extension Notification {
    static let minutesTopicChanged = Notification.Name("minutes.topic.changed")

    struct MinutesDetailKey {
        public static let minutesContent = "minutes.content"
    }
}

extension MinutesDetailViewController {

    var shouldShowEditSpeakerItem: Bool {
        let canEditSpeaker = viewModel.minutes.info.basicInfo?.canEditSpeaker ?? false
        return canEditSpeaker
    }

    var shouldShowCommentTipsItem: Bool {
        // 只有远端url时，才加载评论选项
        if isInCCMfg {
            return false
        }
        return viewModel.minutes.info.isRemotePlayURL
    }

    var isInCCMfg: Bool {
        viewModel.minutes.info.basicInfo?.isInCCMfg == true
    }

    var shouldShowRenameItem: Bool {
        // 编辑权限 或者是所有者可以重命名
        let permission = viewModel.minutes.info.currentUserPermission
        return permission.contains(.edit) || permission.contains(.owner)
    }
    var shouldShowShareItem: Bool {
        // reviewStatus为normal接口
        let reviewStatus = viewModel.minutes.info.reviewStatus
        return reviewStatus == .normal
    }
    var shouldShowTranslateItem: Bool {
        let subtitlelanguage = viewModel.minutes.subtitleLanguages
        if subtitlelanguage.count <= 1 {
            return false
        }
        return true
    }
    var shouldShowDeleteItem: Bool {
        // 只有所有者可以删除
        guard let someBasicInfo = viewModel.minutes.basicInfo else { return false }
        return someBasicInfo.isOwner == true
    }
    var shouldShowMoreInfoItem: Bool {
        return true
    }

    var shouldShowReportItem: Bool {
        FeatureGatingConfig.isMinutesReportEnabled && viewModel.minutes.basicInfo?.showReportIcon == true
    }

    // disable-lint: long_function
    func presentMoreViewController() {
        guard let someBasicInfo = viewModel.minutes.basicInfo else { return }
        var items: [MinutesMoreItem] = []

        let tracker = self.tracker

        if shouldShowMoreInfoItem {
            let onClickMoreInfoClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showMoreInfoPanelWhenClickMoreInfoButton()
                tracker.tracker(name: .detailMoreClick, params: ["click": "more_information", "target": "vc_minutes_more_information_view"])
            }
            let moreInfoItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_MoreDetails_MenuTitle, action: onClickMoreInfoClosure)

            items.append(moreInfoItem)
        }

        if shouldShowCommentTipsItem {
            let showCommentTipsItem = MinutesMoreSwitchItem(icon: UDIcon.getIconByKey(.replyCnOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)),
                                                            titleValue: { _ in BundleI18n.Minutes.MMWeb_G_ShowCommentTags },
                                                            subtitleValue: { value in
                                                                value ? BundleI18n.Minutes.MMWeb_G_ShowCommentLabelsEnabled : BundleI18n.Minutes.MMWeb_G_ShowCommentLabelsDisabled
                                                            },
                                                            initValue: shouldShowCommentTip,
                                                            action: { [weak self] value in
                                                                self?.shouldShowCommentTip = value
                                                                var params: [AnyHashable: Any] = [:]
                                                                params.append(.commentDisplay)
                                                                params.append(actionEnabled: value)
                                                                tracker.tracker(name: .clickButton, params: params)

                                                                tracker.tracker(name: .detailClick, params: ["click": "comment_display", "is_open": value, "target": "none"])
                                                            })

            items.append(showCommentTipsItem)
        }

        if shouldShowRenameItem {
            let onClickRenameClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showRenameAlertController()
            }
            let renameItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.renameOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_Rename, action: onClickRenameClosure)
            items.append(renameItem)
        }

        if shouldShowShareItem {
            let onClickShareClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showSharePanelWhenClickShareButton()
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
                    self.presentChooseTranlationLanVC()
                }
            }
            let translateItem = MinutesMoreClickItem(icon:
                                                        UIImage.dynamicIcon(isInTranslationMode ? .iconTranslateCancelThin : .iconTranslateOutlined, dimension: 20, color: UIColor.ud.iconN1) ?? UIImage(),
                                                     title: isInTranslationMode ? BundleI18n.Minutes.MMWeb_G_ExitTranslation : BundleI18n.Minutes.MMWeb_G_Translate, action: onClickTranslateClosure)
            items.append(translateItem)
        }

        if shouldShowEditSpeakerItem {
            let onClickEditSpeakerClosure: (() -> Void) = { [weak self] in
                self?.preEnterSpeakerEdit {
                    // force clear guide info
                    guard let guide = self?.guideService else { return }
                    guide.didShowedGuide(guideKey: "vc_minutes_edit_speaker")
                }
            }

            let showEditSpeakerItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.editOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)),
                                                           title: BundleI18n.Minutes.MMWeb_G_EditSpeaker_Menu,
                                                           action: onClickEditSpeakerClosure)
            items.append(showEditSpeakerItem)
        }

        if shouldShowReportItem {
            let reportItem = MinutesMoreClickItem(icon: UDIcon.warnReportOutlined, title: BundleI18n.Minutes.MMWeb_G_Report) { [weak self] in
                guard let self = self,
                      let domain = MinutesSettingsManager.shared.tnsReportDomain(with: self.viewModel.minutes.baseURL)else { return }
                let token = self.viewModel.minutes.objectToken
                let urlString = "https://\(domain)/cust/lark_report?type=minutes&params=%7B%22obj_token%22%3A%22\(token)%22%7D"
                if let url = URL(string: urlString) {
                    self.userResolver.navigator.push(url, from: self)
                }
                self.tracker.tracker(name: .detailMoreClick, params: ["click": "report"])
            }
            items.append(reportItem)
        }

        let startTime = TimeInterval(someBasicInfo.startTime) / 1000.0
        let minutesMoreViewController = MinutesMoreViewController(topic: someBasicInfo.topic,
                                                                  info: "\(BundleI18n.Minutes.MMWeb_G_OwnerColon)\(someBasicInfo.ownerInfo?.userName ?? "")",
                                                                  items: items, shouldShowDeleteItem: shouldShowDeleteItem)
        minutesMoreViewController.delegate = self
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
        present(minutesMoreViewController, animated: true, completion: nil)

        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.more)
        tracker.tracker(name: .clickButton, params: trackParams)

        tracker.tracker(name: .detailClick, params: ["click": "more", "target": "vc_minutes_detail_more_view"])
        tracker.tracker(name: .detailMoreView, params: [:])
    }
    // enable-lint: long_function

    func preEnterSpeakerEdit(type: MinutesEditSpeakerType = .common, finish: @escaping() -> Void) {
        MinutesEditDetailReciableTracker.shared.startEnterEditMode()
        // 埋点
        self.tracker.tracker(name: .detailClick, params: ["click": "speaker_edit_enter", "target": "none"])

        let hud = MinutesTranslationHUD(isTranslating: false)

        hud.frame = self.view.bounds
        self.view.addSubview(hud)

        self.entryEditSession(type: type) {
            MinutesEditDetailReciableTracker.shared.finishDataProcess()
            DispatchQueue.main.async {
                hud.removeFromSuperview()
                MinutesEditDetailReciableTracker.shared.endEnterEditMode()
                finish()
            }
        }
    }
}

// MARK: - Delete
extension MinutesDetailViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= limitLength
    }
}

extension MinutesDetailViewController {

    private func showMoreInfoPanelWhenClickMoreInfoButton() {
        let minutesStatisticsViewController = MinutesStatisticsViewController(resolver: userResolver, minutes: viewModel.minutes)

        let nav = MinutesStatisticsNavigationController(rootViewController: minutesStatisticsViewController)
        userResolver.navigator.present(nav, from: self)
    }

    private func showRenameAlertController() {
        let alert = UIAlertController(title: BundleI18n.Minutes.MMWeb_G_Rename, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_Cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_ConfirmButton, style: .default, handler: { [weak self] (_) in
            guard let wSelf = self else { return }
            if let text = (alert.textFields?.first)?.text, text.isEmpty == false {
                wSelf.viewModel.minutes.info.updateTitle(catchError: true, topic: text, completionHandler: { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            if wSelf.navigationBar.titleLabel.text == text {
                                wSelf.tracker.tracker(name: .detailClick, params: ["click": "header_title_edit", "target": "none", "is_change": "false"])
                            } else {
                                wSelf.navigationBar.changeTitle(text)
                                wSelf.postMinutesTopicChangeNotification(newTopic: text)
                                wSelf.tracker.tracker(name: .detailClick, params: ["click": "header_title_edit", "target": "none", "is_change": "true"])
                            }
                        case .failure(let error):
                            let extra = Extra(isNeedNet: true, category: ["object_token": wSelf.viewModel.minutes.info.objectToken])

                            MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                                event: .minutes_edit_detail_error,
                                                                userAction: "rename",
                                                                error: error,
                                                                extra: extra)
                            wSelf.tracker.tracker(name: .detailClick, params: ["click": "header_title_edit", "target": "none", "is_change": "false"])
                        }
                    }
                })
            }
        }))
        alert.addTextField { [weak self] (textField) in
            textField.text = self?.viewModel.minutes.basicInfo?.topic
            textField.delegate = self
        }
        present(alert, animated: true, completion: nil)
    }

    // disable-lint: duplicated_code
    private func postMinutesTopicChangeNotification(newTopic: String) {
        let someObjectToken = viewModel.minutes.info.objectToken
        if someObjectToken.isEmpty { return }
        NotificationCenter.default.post(name: NSNotification.Name.SpaceList.topicDidUpdate, object: nil, userInfo: ["token": someObjectToken, "topic": newTopic])
    }
    // enable-lint: duplicated_code

    private func showSharePanelWhenClickShareButton() {
        if let info = viewModel.minutes.basicInfo {
        }

        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.headerShareActionName)
        self.tracker.tracker(name: .clickButton, params: trackParams)
        self.tracker.tracker(name: .detailClick, params: ["click": "header_share", "target": "vc_minutes_share_view"])
    }

    // disable-lint: duplicated_code
    private func showAlertControllerWhenClickDeleteButton() {
        let alertController: LarkAlertController = LarkAlertController()
        let title: String = BundleI18n.Minutes.MMWeb_G_DeleteQuestion(viewModel.minutes.basicInfo?.topic ?? "")
        let message: String = BundleI18n.Minutes.MMWeb_G_My_DeleteFileName_PopupText
        alertController.setTitle(text: title, color: UIColor.ud.textTitle, font: UIFont.boldSystemFont(ofSize: 17))
        alertController.setContent(text: message, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17))
        alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: { [weak self] in
            guard let wSelf = self else { return }

            var trackParams: [AnyHashable: Any] = [:]
            trackParams.append(.headerPageDelete)
            trackParams["action_result"] = "cancel"
            wSelf.tracker.tracker(name: .clickButton, params: trackParams)
        })
        alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Delete, dismissCompletion: { [weak self] in
            guard let wSelf = self else { return }
            wSelf.requestDeleteMinute()

            var trackParams: [AnyHashable: Any] = [:]
            trackParams.append(.headerPageDelete)
            trackParams["action_result"] = "delete"
            wSelf.tracker.tracker(name: .clickButton, params: trackParams)
        })
        present(alertController, animated: true)

        tracker.tracker(name: .detailMoreClick, params: ["click": "delete", "target": "vc_minutes_delete_view"])
    }
    // enable-lint: duplicated_code

    private func requestDeleteMinute() {
        viewModel.requestDeleteMinutes(catchError: true, successHandler: { [weak self] in
            guard let wSelf = self else { return }
            wSelf.showMinutesResourceDeletedVC()
        }, failureHandler: {[weak self] error in
            guard let wSelf = self else { return }
            guard let someError = error as? ResponseError else { return }
            switch someError {
            case .resourceDeleted:
                wSelf.showMinutesResourceDeletedVC()
            default: break
            }
        })
    }

    private func showMinutesResourceDeletedVC() {
        self.videoPlayer.pause()
        let vc = MinutesErrorStatusViewController(resolver: userResolver, minutesStatus: MinutesInfoStatus.resourceDeleted, isClip: false)
        addChild(vc)
        view.addSubview(vc.view)
        view.bringSubviewToFront(vc.view)

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }

            wSelf.navigationController?.popViewController(animated: true)
        }
    }
}

extension MinutesDetailViewController {

    var editSpeakerConfig: BubbleItemConfig {
        let target = TargetAnchor(targetSourceType: .targetView(navigationBar.moreButton))
        let text = TextInfoConfig(detail: BundleI18n.Minutes.MMWeb_G_EditSpeakerHere_Onboard)
        return BubbleItemConfig(guideAnchor: target, textConfig: text)
    }

    func showGuideIfNeeded() {
        guard shouldShowEditSpeakerItem else { return }
        guard let guide = guideService else { return }

        guide.showBubbleGuideIfNeeded(guideKey: "vc_minutes_edit_speaker", bubbleType: .single(.init(bubbleConfig: editSpeakerConfig))) {
            MinutesLogger.detail.info("edit speaker guide has shown.")
        }

    }
}

extension MinutesDetailViewController: MinutesEditSessionDelegate {

    public func onDeactive(_ reason: KeepEditExitReason) {
        switch reason {
        case .expired:
            self.showTips(with: BundleI18n.Minutes.MMWeb_G_NoActionForLongQuitEdit_Toast)
        case .otherDevice:
            self.showTips(with: BundleI18n.Minutes.MMWeb_G_EditOnOtherDeviceQuitEdit_Toast)
        default:
            break
        }

        self.isEditingSpeaker = false
    }

    func entryEditSession(type: MinutesEditSpeakerType = .common, finish:@escaping () -> Void) {
        guard self.viewModel.editSession == nil else {
            finish()
            return
        }
        let minutes = self.viewModel.minutes
        let objectToken = minutes.objectToken

        MinutesEditDetailReciableTracker.shared.finishPreProcess()
        MinutesEditSession.createSession(for: minutes) { [weak self] (result) in
            guard let self = self else { return }
            var hasfinshed = true
            switch result {
            case .success(let session):
                // keep session
                DispatchQueue.main.async {
                    session.delegate = self
                    self.viewModel.editSession = session
                    switch type {
                    case .common:
                        self.isEditingSpeaker = true
                    case .quick:
                        self.subtitlesViewController?.editSession = session
                    }
                }
            case .failure(let error):
                switch error {
                case .otherEditor(let editorName):
                    // show toast
                    self.showTips(with: BundleI18n.Minutes.MMWeb_G_NameEditing(editorName))
                case .lowversion:
                    // refresh current data
                    hasfinshed = false
                    self.viewModel.minutes.refresh(catchError: false, refreshAll: true) {
                        self.entryEditSession(type: type, finish: finish)
                    }
                case .network(let error):
                    // show toast
                    self.showTips(with: BundleI18n.Minutes.MMWeb_G_ConnectionErrorCheckInternet_Toast)
                    let extra = Extra(isNeedNet: true, category: ["object_token": objectToken])

                    MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                        event: .minutes_edit_detail_error,
                                                        userAction: "enterEditSession",
                                                        error: error,
                                                        extra: extra)
                }
            }
            if hasfinshed {
                MinutesEditDetailReciableTracker.shared.finishNetworkReqeust()
                finish()
            }
        }
    }

    func showTips(with text: String) {
        DispatchQueue.main.async {
            let targetView = self.userResolver.navigator.mainSceneWindow?.fromViewController?.view
            
            MinutesToast.showTips(with: text, targetView: targetView)
        }
    }

    func quickEditSpeaker() {

    }
}

extension MinutesDetailViewController: MinutesDeleteItemDelegate {
    func deleteItem() {
        self.dismiss(animated: true, completion: nil)
        let onClickDeleteClosure = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.showAlertControllerWhenClickDeleteButton()
        }
        onClickDeleteClosure()
    }
}
