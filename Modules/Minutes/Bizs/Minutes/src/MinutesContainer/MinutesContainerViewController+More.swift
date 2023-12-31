//
//  MinutesContainerViewController+More.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/9/8.
//

import Foundation
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
import LarkUIKit
import LarkMedia

extension MinutesContainerViewController {
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
        if let dependency = dependency, dependency.isShareEnabled(){
            // reviewStatus为normal接口
            let reviewStatus = viewModel.minutes.info.reviewStatus
            return reviewStatus == .normal
        } else {
            return false
        }
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

    var shouldShowClipListItem: Bool {
        guard let someBasicInfo = viewModel.minutes.basicInfo else { return false }

        if let clipInfo = someBasicInfo.clipInfo, clipInfo.clipNumber > 0, someBasicInfo.isOwner == true {
            return true
        } else {
            return false
        }
    }

    var shouldShowReportItem: Bool {
        FeatureGatingConfig.isMinutesReportEnabled && viewModel.minutes.basicInfo?.showReportIcon == true
    }

    // disable-lint: long_function
    func presentMoreViewController() {
        guard let someBasicInfo = viewModel.minutes.basicInfo else { return }
        var items: [MinutesMoreItem] = []

        let tracker = self.tracker
        let isInTranslationMode = currentTranslationChosenLanguage != .default

        if shouldShowShareItem {
            let onClickShareClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showSharePanelWhenClickShareButton()
            }
            let shareItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.shareOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_Share, action: onClickShareClosure)

            items.append(shareItem)
        }

        if !isText, Display.phone {
            let onClickShareClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.podcastAction()
            }
            let podcastItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.headphoneFilled, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_PodcastMode, action: onClickShareClosure)
            items.append(podcastItem)
        }

        if shouldShowRenameItem {
            let onClickRenameClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showRenameAlertController()
            }
            let renameItem = MinutesMoreClickItem(icon:  UDIcon.getIconByKey(.renameOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_Rename, action: onClickRenameClosure)

            items.append(renameItem)
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

        if shouldShowTranslateItem {
            let onClickTranslateClosure = { [weak self] in
                guard let self = self else { return }

                self.tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_language_change"])

                if isInTranslationMode {
                    self.rightMinutesDetail?.exitTranlation()
                    self.leftMinutesDetail?.exitTranlation()
                } else {
                    self.presentChooseTranlationLanVC()
                }
            }

            let translateItem = MinutesMoreClickItem(icon:
                                                        UIImage.dynamicIcon(isInTranslationMode ? .iconTranslateCancelThin : .iconTranslateOutlined, dimension: 20, color: UIColor.ud.iconN1) ?? UIImage(),
                                                     title: isInTranslationMode ? BundleI18n.Minutes.MMWeb_G_ExitTranslation : BundleI18n.Minutes.MMWeb_G_Translate, action: onClickTranslateClosure)
            items.append(translateItem)
        }

        if shouldShowCommentTipsItem {
            let showCommentTipsItem = MinutesMoreSwitchItem(icon: UDIcon.getIconByKey(.replyCnOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)),
                                                            titleValue: { _ in BundleI18n.Minutes.MMWeb_G_ShowCommentTags },
                                                            subtitleValue: { value in
                                                                value ? BundleI18n.Minutes.MMWeb_G_ShowCommentLabelsEnabled : BundleI18n.Minutes.MMWeb_G_ShowCommentLabelsDisabled
                                                            },
                                                            initValue: self.leftMinutesDetail?.shouldShowCommentTip ?? true,
                                                            action: { [weak self] value in
                                                                self?.leftMinutesDetail?.shouldShowCommentTip = value
                                                                var params: [AnyHashable: Any] = [:]
                                                                params.append(.commentDisplay)
                                                                params.append(actionEnabled: value)
                                                                tracker.tracker(name: .clickButton, params: params)

                                                                tracker.tracker(name: .detailClick, params: ["click": "comment_display", "is_open": value, "target": "none"])
                                                            })

            items.append(showCommentTipsItem)
        }

        if shouldShowMoreInfoItem {
            let onClickMoreInfoClosure = { [weak self] in
                guard let wSelf = self else { return }
                wSelf.showMoreInfoPanelWhenClickMoreInfoButton()
                tracker.tracker(name: .detailMoreClick, params: ["click": "more_information", "target": "vc_minutes_more_information_view"])
            }
            let moreInfoItem = MinutesMoreClickItem(icon: UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), title: BundleI18n.Minutes.MMWeb_G_MoreDetails_MenuTitle, action: onClickMoreInfoClosure)

            items.append(moreInfoItem)
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
        if isSceneRegular {
            let moreButton = navigationBar.moreButton
            minutesMoreViewController.isRegular = true
            minutesMoreViewController.modalPresentationStyle = .popover
            minutesMoreViewController.popoverPresentationController?.backgroundColor = UIColor.ud.bgFloatBase
            minutesMoreViewController.popoverPresentationController?.sourceView = moreButton
            minutesMoreViewController.popoverPresentationController?.sourceRect = moreButton.bounds
            minutesMoreViewController.popoverPresentationController?.permittedArrowDirections = .up
            minutesMoreViewController.preferredContentSize = CGSize.init(width: 375, height: minutesMoreViewController.viewHeight)
        }
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
        let detail = isRegular ? rightMinutesDetail : leftMinutesDetail

        detail?.entryEditSession(type: type) { [weak self, weak detail] in
            MinutesEditDetailReciableTracker.shared.finishDataProcess()
            DispatchQueue.main.async {
                hud.removeFromSuperview()
                MinutesEditDetailReciableTracker.shared.endEnterEditMode()
                finish()
                if Display.pad {
                    self?.navigationBar.isEditSpeaker = detail?.isEditingSpeaker ?? false
                }
            }
        }
    }
}

extension MinutesContainerViewController {

    private func showMoreInfoPanelWhenClickMoreInfoButton() {
        let minutesStatisticsViewController = MinutesStatisticsViewController(resolver: userResolver, minutes: viewModel.minutes)

        if isSceneRegular {
            userResolver.navigator.present(minutesStatisticsViewController, wrap: LkNavigationController.self, from: self, prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            let nav = MinutesStatisticsNavigationController(rootViewController: minutesStatisticsViewController)
            userResolver.navigator.present(nav, from: self)
        }
    }

    private func showRenameAlertController() {
        let title = viewModel.minutes.basicInfo?.topic ?? ""
        let alert = UIAlertController(title: BundleI18n.Minutes.MMWeb_G_Rename, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_Cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_ConfirmButton, style: .default, handler: { [weak self] (_) in
            guard let wSelf = self else { return }
            if let text = (alert.textFields?.first)?.text, text.isEmpty == false {
                wSelf.viewModel.minutes.info.updateTitle(catchError: true, topic: text, completionHandler: { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            if title == text {
                                wSelf.tracker.tracker(name: .detailClick, params: ["click": "header_title_edit", "target": "none", "is_change": "false"])
                            } else {
//                                wSelf.navigationBar.changeTitle(text)
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
            let shareType: Int = 28
            dependency?.docs?.openDocShareViewController(token: info.objectToken,
                                            type: shareType,
                                            isOwner: info.isOwner ?? false,
                                            ownerID: info.ownerID,
                                            ownerName: info.ownerInfo?.userName ?? "",
                                            url: viewModel.minutes.baseURL.absoluteString,
                                            title: info.topic,
                                            tenantID: "",
                                            needPopover: isSceneRegular,
                                            padPopDirection: .up,
                                            popoverSourceFrame: navigationBar.moreButton.bounds,
                                            sourceView: navigationBar.moreButton,
                                            isInVideoConference: false,
                                            hostViewController: self)
        }

        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.headerShareActionName)
        self.tracker.tracker(name: .clickButton, params: trackParams)
        self.tracker.tracker(name: .detailClick, params: ["click": "header_share", "target": "vc_minutes_share_view"])
    }

    // disable-lint: duplicated_code
    private func podcastAction() {
        LarkMediaManager.shared.tryLock(scene: .mmPlay, observer: videoPlayer) { [weak self] in
           guard let self = self else {
               return
           }
           switch $0 {
           case .success:
               DispatchQueue.main.async {
                   self.leftMinutesDetail?.switchToPodcast()
               }
           case .failure(let error):
               DispatchQueue.main.async {
                   let targetView = self.userResolver.navigator.mainSceneWindow?.fromViewController?.view
                   if case let MediaMutexError.occupiedByOther(context) = error {
                       if let msg = context.1 {
                           MinutesToast.showTips(with: msg, targetView: targetView)
                       }
                   } else {
                       MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                   }
               }
           }
       }
    }
    // enable-lint: duplicated_code


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
        videoPlayer.pause()
        showMinutesErrorStatusVC(status: .resourceDeleted)
    }

    // disable-lint: duplicated_code
    func presentChooseTranlationLanVC() {
        if viewModel.minutes.data.subtitles.isEmpty {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: view)
            return
        }

        if viewModel.minutes.basicInfo?.supportAsr == false {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow, on: view)
            return
        }

        var items: [MinutesTranslationLanguageModel] = []

        for language in viewModel.minutes.subtitleLanguages where language != .default {
            let item = MinutesTranslationLanguageModel(language: language.name,
                    code: language.code,
                    isHighlighted: language == currentTranslationChosenLanguage)
            items.append(item)
        }
        let center = SelectTargetLanguageTranslateCenter(items: items)
        center.selectBlock = { [weak self] vm in
            guard let self = self else {
                return
            }
            let lang = Language(name: vm.language, code: vm.code)
            self.currentTranslationChosenLanguage = lang
            self.rightMinutesDetail?.startTranslate(with: lang)
            self.leftMinutesDetail?.startTranslate(with: lang)
        }
        center.showSelectDrawer(from: self, resolver: userResolver, isRegular: isSceneRegular)
    }
    // enable-lint: duplicated_code
}

// MARK: - Delete
extension MinutesContainerViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= limitLength
    }
}

extension MinutesContainerViewController: MinutesDeleteItemDelegate {
    func deleteItem() {
        self.dismiss(animated: true, completion: nil)
        let onClickDeleteClosure = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.showAlertControllerWhenClickDeleteButton()
        }
        onClickDeleteClosure()
    }
}
