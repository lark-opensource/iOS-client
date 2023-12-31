//
//  MinutesSubtitlesViewController+EditSpeaker.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import EENavigator
import UniverseDesignDialog
import UniverseDesignToast
import LarkAlertController
import LarkUIKit

enum MinutesEditSpeakerType {
    case common
    case quick  // 快速编辑，点头像直接进入
}

extension MinutesSubtitlesViewController {
    func editSubtitleProfile(paragraph: Paragraph) {

        if let speaker = paragraph.speaker {
            if let iconType = speaker.iconType {
                if iconType == 0 {
                    //open profile
                    self.openProfileFromAvatarTouch(paragraph: paragraph)
                } else if iconType == 1 {
                    if !viewModel.isClip {
                        //edit
                        self.enterSpeakerEditFromAvatarTouch(paragraph: paragraph)
                        self.tracker.tracker(name: .detailClick, params: ["click": "cluster_speaker", "target": "none"])
                    }
                } else if iconType == 2 {
                    if !viewModel.isClip {
                        //ai voice print confirmed
                        confirmVoiceprintSpeakerFromAvatarTouch(paragraph: paragraph)
                    } else {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_FromVoiceprint_Bubble, on: self.view)
                    }
                }
            }
        }
    }

    private func openProfileFromAvatarTouch(paragraph: Paragraph) {
        //no type, open profile
        self.tracker.tracker(name: .clickButton, params: ["action_name": "profile_picture", "page_name": "detail_page", "from_source": " speaker_picture"])

        self.tracker.tracker(name: .detailClick, params: ["click": "profile", "location": "speaker_picture", "target": "none"])

        if paragraph.speaker?.userType == .lark {
            if let userId = paragraph.speaker?.userID {
                let from = userResolver.navigator.mainSceneTopMost
                MinutesProfile.personProfile(chatterId: userId, from: from, resolver: userResolver)
            }
        } else if paragraph.speaker?.userType == .pstn {
            if let isBind = paragraph.speaker?.isBind, isBind == true, let bindID = paragraph.speaker?.bindID {
                let from = userResolver.navigator.mainSceneTopMost
                MinutesProfile.personProfile(chatterId: bindID, from: from, resolver: userResolver)
            }
        }
    }

    func openProfileBy(userId: String) {
        let from = userResolver.navigator.mainSceneTopMost
        MinutesProfile.personProfile(chatterId: userId, from: from, resolver: userResolver)
    }

    private func enterSpeakerEditFromAvatarTouch(paragraph: Paragraph) {
        let pid = paragraph.id
        if isEditingSpeaker {
            showEditSpeakerAlert(with: paragraph)
        } else {
            enterSpeakerEdit(with: paragraph)
        }
    }

    func showEditSpeakerAlert(with paragraph: Paragraph) {
        guard let session = self.editSession else { return }
        let alert = MinutesEditSpeakerAlertController(resolver: userResolver, session: session, paragraph: paragraph)
        alert.didFinishedEditBlock = { [weak self] (p, toast) in
            self?.topLoadRefresh()
            if let tip = toast {
                self?.delegate?.showToast(text: tip)
            }
            self?.delegate?.didFinishedEdit()
        }
        if Display.pad {
            alert.modalPresentationStyle = .formSheet
            alert.transitioningDelegate = nil
        }
        userResolver.navigator.present(alert, from: self)
    }

    func enterSpeakerEdit(with paragraph: Paragraph) {
        self.delegate?.enterSpeakerEdit(finish: {[weak self] in
            guard let `self` = self, let session = self.editSession else { return }
            let alert = MinutesEditSpeakerAlertController(resolver: self.userResolver, session: session, paragraph: paragraph)
            alert.didFinishedEditBlock = { [weak self] (p, toast) in
                self?.topLoadRefresh()
                if let tip = toast {
                    self?.delegate?.showToast(text: tip)
                }
                self?.delegate?.didFinishedEdit()
            }
            alert.endBlock = { [weak self] in
                self?.delegate?.finishSpeakerEdit()
            }
            if Display.pad {
                alert.modalPresentationStyle = .formSheet
                alert.transitioningDelegate = nil
            }
            self.userResolver.navigator.present(alert, from: self)
        })
    }

    private func confirmVoiceprintSpeakerFromAvatarTouch(paragraph: Paragraph) {
        if let speaker = paragraph.speaker, let marker = speaker.marker {
            if let canEditSpeaker = viewModel.minutes.info.basicInfo?.canEditSpeaker, canEditSpeaker == true {
                self.tracker.tracker(name: .detailClick, params: ["click": "speaker_identity", "source": "voiceprint", "user_type": "editor", "target": "none"])
                let dialog = UDDialog()
                dialog.setTitle(text: BundleI18n.Minutes.MMWeb_G_FromVoiceprint_Bubble)
                dialog.setContent(text: BundleI18n.Minutes.MMWeb_G_SpeakerWrongEdit_Pop)
                dialog.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_EditSpeakers_Button,
                                 dismissCompletion: { [weak self] in
                        guard let self = self else { return }
                    self.tracker.tracker(name: .voiceprintClick, params: ["click": "edit_speaker", "target": "none"])
                    self.enterSpeakerEditFromAvatarTouch(paragraph: paragraph)
                })
                dialog.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_M_GotIt, dismissCompletion: nil)
                self.present(dialog, animated: true, completion: nil)
            } else {
                if speaker.userID != passportUserService?.user.userID {
                    self.tracker.tracker(name: .detailClick, params: ["click": "speaker_identity", "source": "voiceprint", "user_type": "others", "target": "none"])
                    UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_FromVoiceprint_Bubble, on: self.view)
                } else {
                    self.tracker.tracker(name: .detailClick, params: ["click": "speaker_identity", "source": "voiceprint", "user_type": "me", "target": "none"])
                    UDToast.showLoading(with: BundleI18n.Minutes.MMWeb_G_Loading, on: self.view)
                    viewModel.requestSpeakerCount(userId: speaker.userID, userType: speaker.userType) {[weak self] removed in
                        guard let self = self else { return }

                        UDToast.removeToast(on: self.view)

                        let dialog = UDDialog()

                        dialog.setTitle(text: BundleI18n.Minutes.MMWeb_G_FromVoiceprint_Bubble)
                        if removed.count <= 0 {
                            dialog.setContent(text: BundleI18n.Minutes.MMWeb_G_IfNotSpeakerRemove)
                        } else {
                            if let name = paragraph.speaker?.userName {
                                let checkBoxString = BundleI18n.Minutes.MMWeb_G_RemoveSpeakerBatch(removed.count, name, lang: nil)
                                let contentView = MinutesEditSpeakerRemoveView(contentText: BundleI18n.Minutes.MMWeb_G_IfNotSpeakerRemove, checkBoxText: checkBoxString, frame: .zero)
                                contentView.setCheckBox(isOn: true)
                                self.isSpeakerRemoveBatchOn  = true
                                contentView.delegate = self
                                dialog.setContent(view: contentView)
                            }
                        }
                        dialog.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_M_RemoveButton,
                                         dismissCompletion: { [weak self] in
                            guard let self = self else { return }
                            self.tracker.tracker(name: .voiceprintClick, params: ["click": "remove", "is_batch": self.isSpeakerRemoveBatchOn, "target": "none"])
                            UDToast.showLoading(with: BundleI18n.Minutes.MMWeb_G_Loading, on: self.view)
                            self.viewModel.requestRemoveSpeaker(paragraph: paragraph, isBatch: self.isSpeakerRemoveBatchOn, successHandler: {[weak self] newSpeaker in
                                guard let self = self else { return }
                                UDToast.removeToast(on: self.view)
                                if self.isSpeakerRemoveBatchOn {
                                    self.viewModel.updateViewDataSpeaker(with: newSpeaker)
                                } else {
                                    self.viewModel.updateOneSubtitle(with: newSpeaker, pid: paragraph.id)
                                }
                            }, failureHandler: { [weak self] error in
                                guard let self = self else { return }
                                let errorText: String = error?.localizedDescription ?? BundleI18n.Minutes.MMWeb_G_FailedToLoad
                                UDToast.showFailure(with: errorText, on: self.view)
                            })
                        })
                        dialog.addPrimaryButton(text: BundleI18n.Minutes.MMWeb_M_GotIt, dismissCompletion: nil)
                        self.present(dialog, animated: true, completion: nil)

                    } failureHandler: {  [weak self] error in
                        guard let self = self else { return }
                        let errorText: String = error?.localizedDescription ?? BundleI18n.Minutes.MMWeb_G_FailedToLoad
                        UDToast.showFailure(with: errorText, on: self.view)
                    }
                }
            }
        }
    }
}

extension MinutesSubtitlesViewController: MinutesEditSpeakerRemoveViewDelegate {
    func checkBoxDidChangeStatus(isOn: Bool) {
        self.isSpeakerRemoveBatchOn = isOn
    }
}
