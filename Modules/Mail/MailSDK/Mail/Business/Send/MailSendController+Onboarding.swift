//
//  MailSendController+Onboarding.swift
//  MailSDK
//
//  Created by Ender on 2023/9/4.
//

import Foundation
import LarkGuideUI

extension MailSendController {
    func showPriorityGuideIfNeeded() {
        let guideKey = "all_email_priority_mobile"
        guard accountContext.featureManager.open(.mailPriority, openInMailClient: false),
              accountContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey) == true,
              let moreBtn = moreBtn else { return }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(moreBtn))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_EmailPriority_FeatureNotice_Title,
                                        detail: BundleI18n.MailSDK.Mail_EmailPriority_FeatureNotice_Desc)
        let buttonInfo = ButtonInfo(title: BundleI18n.MailSDK.Mail_EmailPriority_FeatureNotice_GotIt, buttonType: .finished)
        let bottomConfig = BottomConfig(rightBtnInfo: buttonInfo)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)
        let bubbleConfig = SingleBubbleConfig(delegate: self,
                                              bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor,
                                                                             textConfig: textConfig,
                                                                             bottomConfig: bottomConfig),
                                              maskConfig: maskConfig)
        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig)) { [weak self] in
            self?.accountContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
    }

    func showReadReceiptGuideIfNeeded() {
        let guideKey = "all_email_read_receipt_mobile"
        guard accountContext.featureManager.open(.readReceipt, openInMailClient: false),
              accountContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: guideKey) == true,
              let moreBtn = moreBtn else { return }
        let targetAnchor = TargetAnchor(targetSourceType: .targetView(moreBtn))
        let textConfig = TextInfoConfig(title: BundleI18n.MailSDK.Mail_ReadReceiptFeatureNotice_Title,
                                        detail: BundleI18n.MailSDK.Mail_ReadReceiptFeatureNotice_Desc)
        let buttonInfo = ButtonInfo(title: BundleI18n.MailSDK.Mail_ReadReceiptFeatureNotice_GotIt, buttonType: .finished)
        let bottomConfig = BottomConfig(rightBtnInfo: buttonInfo)
        let maskConfig = MaskConfig(shadowAlpha: 0, windowBackgroundColor: .clear, maskInteractionForceOpen: true)
        let bubbleConfig = SingleBubbleConfig(delegate: self,
                                              bubbleConfig: BubbleItemConfig(guideAnchor: targetAnchor,
                                                                             textConfig: textConfig,
                                                                             bottomConfig: bottomConfig),
                                              maskConfig: maskConfig)
        accountContext.provider.guideServiceProvider?.guideService?.showBubbleGuideIfNeeded(guideKey: guideKey,
                                                                                            bubbleType: .single(bubbleConfig)) { [weak self] in
            self?.accountContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: guideKey)
        }
    }
}
