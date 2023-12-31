//
//  SubtitleAlertUtil.swift
//  ByteView
//
//  Created by kiri on 2021/4/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI
import UniverseDesignIcon

struct SubtitleAlertUtil {
    static func showSelectLanguageAlert(router: Router, context: InMeetViewContext, selectedLanguage: Subtitle.Language,
                                        selectableSpokenLanguages: [Subtitle.Language],
                                        completion: @escaping (Subtitle.Language?) -> Void,
                                        alertGenerationCallback: ((ByteViewDialog) -> Void)?) {
        var language = selectedLanguage
        let button = SubtitleSelectLanguageButton(selectedLanguage: selectedLanguage, selectableSpokenLanguages: selectableSpokenLanguages)
        button.fullScreenDetector = context.fullScreenDetector
        button.router = router
        button.selectionCallback = {
            language = $0
        }
        let title = I18n.View_G_SubtitlesSelectSpokenLanguage
        let leftTitle = I18n.View_G_CancelButton
        ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .subtitleSelection)
        ByteViewDialog.Builder()
            .id(.selectSubtitleSpokenLanguage)
            .adaptsLandscapeLayout(true)
            .needAutoDismiss(true)
            .title(title)
            .button(button)
            .leftTitle(leftTitle)
            .leftHandler({ _ in
                SubtitleTracks.trackCancelSpokenLanguage()
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .subtitleSelection, action: "cancel")
                completion(nil)
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ _ in
                SubtitleTracks.trackConfirmSpokenLanguage(language.language)
                ThemeAlertTrackerV2.trackClickPopupAlert(content: .subtitleSelection, action: "confirm")
                completion(language)
            })
            .show { (alertController) in
                button.hostAlert = alertController
                alertGenerationCallback?(alertController)
            }
    }

    static func showRecordAudioConfirmedAlert(meeting: InMeetMeeting, completion: @escaping (Bool) -> Void, alertGenerationCallback: ((ByteViewDialog) -> Void)?) {
        guard meeting.setting.isAudioRecordEnabledForSubtitle else {
            completion(false)
            return
        }
        let title = I18n.View_VM_AllowUsToUseAudio
        let message = I18n.View_VM_AllowUsToUseAudioDescriptionNew
        ByteViewDialog.Builder()
            .id(.recordMeetingAudio)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_VM_NoButton)
            .leftHandler({ _ in completion(false) })
            .rightTitle(I18n.View_VM_YesButton)
            .rightHandler({ _ in completion(true) })
            .show { alert in alertGenerationCallback?(alert) }
    }

    static func showDetectedLanguageTipAlert(tip: LangDetectTip, info: LangDetectTip.Alert, completion: @escaping (Bool) -> Void,
                                             alertGenerationCallback: ((ByteViewDialog) -> Void)?) {
        switch tip {
        case .mismatching:
            SubtitleTracks.trackLangDetectMismatchAlert()
        case .nonsupport:
            SubtitleTracks.trackLangDetectNonsupportAlert()
        default:
            break
        }
        ByteViewDialog.Builder()
            .id(info.id)
            .title(info.title)
            .message(info.description)
            .buttonsAxis(.vertical)
            .leftTitle(info.button1)
            .leftHandler({ _ in
                switch tip {
                case .mismatching:
                    SubtitleTracks.trackLangDetectMismatchAction(true)
                    completion(true)
                case .nonsupport:
                    SubtitleTracks.trackLangDetectNonsupportAction(false)
                    completion(false)
                default:
                    break
                }
            })
            .rightTitle(info.button2)
            .rightHandler({ _ in
                switch tip {
                case .mismatching:
                    SubtitleTracks.trackLangDetectMismatchAction(false)
                    completion(false)
                case .nonsupport:
                    SubtitleTracks.trackLangDetectNonsupportAction(true)
                    completion(true)
                default:
                    break
                }
            })
            .show { alert in alertGenerationCallback?(alert) }
    }

    static func constructDetectedLanguageTipInfo(_ tip: LangDetectTip, httpClient: HttpClient,
                                                 completion: @escaping (Result<LangDetectTip.Alert, Error>) -> Void) {
        switch tip {
        case .mismatching(let detectedKey, let currentKey):
            Logger.network.info("Get i18n by detectedKey: \(detectedKey), currentKey = \(currentKey)")
            return httpClient.i18n.get([detectedKey, currentKey]) {
                switch $0 {
                case .success(let templates):
                    guard let detectedLanguage = templates[detectedKey],
                          let currentLanguage = templates[currentKey] else {
                              completion(.failure(VCError.unknown))
                              return
                          }
                    let title = I18n.View_G_DetectedSpokenLanguageTitleBraces(detectedLanguage)
                    let description = I18n.View_G_DetectedSpokenLanguageInfoBraces(currentLanguage,
                                                                                   detectedLanguage)
                    let button1 = I18n.View_G_KeepUsingOriginalBraces(currentLanguage)
                    let button2 = I18n.View_G_OpenSubtitleSettings
                    completion(.success(LangDetectTip.Alert(title: title,
                                                            description: description,
                                                            button1: button1,
                                                            button2: button2,
                                                            id: .spokenMismatching)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .nonsupport(let detectedKey):
            Logger.network.info("Get i18n by detectedKey: \(detectedKey)")
            return httpClient.i18n.get(detectedKey) {
                switch $0 {
                case .success(let detectedLanguage):
                    let title = I18n.View_G_DetectedSpokenLanguageTitleBraces(detectedLanguage)
                    let description = I18n.View_G_SpeakingUnsupportedLangSelectBraces(detectedLanguage)
                    let button1 = I18n.View_G_OpenSubtitleSettings
                    let button2 = I18n.View_G_GotItButton
                    completion(.success(LangDetectTip.Alert(title: title,
                                                            description: description,
                                                            button1: button1,
                                                            button2: button2,
                                                            id: .spokenNonsupport)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        default:
            completion(.failure(VCError.unknown))
        }
    }
}

private class SubtitleSelectLanguageButton: UIButton {
    private(set) var selectedLanguage: Subtitle.Language
    private let selectableSpokenLanguages: [Subtitle.Language]
    private let selectLanguageLabel = UILabel()
    private let selectLanguageImage = UIImageView(image: UDIcon.getIconByKey(.downOutlined, iconColor: .ud.iconN3, size: CGSize(width: 12, height: 12)))
    var selectionCallback: ((Subtitle.Language) -> Void)?
    weak var router: Router?
    weak var hostAlert: ByteViewDialog?
    weak var fullScreenDetector: InMeetFullScreenDetector?
    init(selectedLanguage: Subtitle.Language, selectableSpokenLanguages: [Subtitle.Language]) {
        self.selectedLanguage = selectedLanguage
        self.selectableSpokenLanguages = selectableSpokenLanguages
        super.init(frame: .zero)
        vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        layer.cornerRadius = 4.0
        layer.masksToBounds = true
        layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        layer.borderWidth = 1.0

        selectLanguageLabel.textAlignment = .left
        selectLanguageLabel.text = selectedLanguage.desc
        selectLanguageLabel.textColor = UIColor.ud.textTitle
        selectLanguageLabel.font = UIFont.systemFont(ofSize: 16)
        selectLanguageLabel.numberOfLines = 1
        selectLanguageLabel.lineBreakMode = .byTruncatingTail

        addSubview(selectLanguageLabel)
        addSubview(selectLanguageImage)
        selectLanguageLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        selectLanguageImage.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(15)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }

        addTarget(self, action: #selector(didSelectLanguage(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didSelectLanguage(_ sender: UIButton) {
        let appearance = ActionSheetAppearance(backgroundColor: Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody,
                                               titleColor: UIColor.ud.textPlaceholder)
        let actionSheet = ActionSheetController(appearance: appearance)
        for language in selectableSpokenLanguages {
            let action = SheetAction(title: language.desc, handler: { [language, weak self] _ in
                self?.selectedLanguage = language
                self?.selectLanguageLabel.text = language.desc
                self?.selectionCallback?(language)
            })
            actionSheet.addAction(action)
        }
        let cancelAction = SheetAction(title: I18n.View_G_CancelButton, sheetStyle: .cancel, handler: { _ in })
        actionSheet.addAction(cancelAction)
        if Display.pad {
            actionSheet.modalPresentation = .alwaysPopover
            let height = actionSheet.intrinsicHeight
            let anchor = AlignPopoverAnchor(sourceView: self,
                                            contentWidth: .equalToSourceView,
                                            contentHeight: height,
                                            positionOffset: CGPoint(x: 0, y: 4),
                                            cornerRadius: 12,
                                            dimmingColor: UIColor.clear,
                                            containerColor: UIColor.ud.bgFloat)
            let popover = AlignPopoverManager.shared.present(viewController: actionSheet, from: hostAlert, anchor: anchor)
            popover.fullScreenDetector = fullScreenDetector
        } else {
            actionSheet.modalPresentation = .popover
            let popoverConfig = DynamicModalPopoverConfig(sourceView: selectLanguageImage,
                                                          sourceRect: selectLanguageImage.bounds,
                                                          backgroundColor: UIColor.ud.bgBody,
                                                          popoverSize: actionSheet.padContentSize,
                                                          permittedArrowDirections: .up)
            let regularConfig = DynamicModalConfig(presentationStyle: .popover, popoverConfig: popoverConfig, backgroundColor: .clear)
            let compactConfig = DynamicModalConfig(presentationStyle: .pan)
            router?.presentDynamicModal(actionSheet, regularConfig: regularConfig, compactConfig: compactConfig)
        }
    }
}
