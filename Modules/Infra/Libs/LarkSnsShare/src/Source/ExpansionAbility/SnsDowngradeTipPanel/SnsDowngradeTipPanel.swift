//
//  SnsDowngradeTipPanel.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/14.
//

import UIKit
import Foundation
import UniverseDesignColor

public final class SnsDowngradeTipPanel: SnsOperationTipPanel {
    public init(
        snsType: SnsType,
        material: DowngradeTipPanelMaterial,
        autoOperationHandler: @escaping ((SnsOperationTipPanel) -> Void),
        ctaButtonDidClick: @escaping ((SnsOperationTipPanel) -> Void),
        skipButtonDidClick: ((SnsOperationTipPanel) -> Void)? = nil
    ) {
        var panelTitle: String?
        var defalutPanelTitle = ""
        var ctaIcon: UIImage!
        var ctaTitle = ""
        var copyContent: String?
        var ctaBackgroundColor: UIColor!
        var ctaHightlightColor: UIColor!

        switch snsType {
        case .wechat:
            ctaIcon = Resources.cta_wechat
            ctaTitle = BundleI18n.LarkSnsShare.Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved_button
            ctaBackgroundColor = UIColor.ud.colorfulGreen
            ctaHightlightColor = UIColor.ud.G600
        case .qq:
            ctaIcon = Resources.cta_qq
            ctaTitle = BundleI18n.LarkSnsShare.Lark_Invitation_ShareViaQQ_ImageCreatedAndSaved_button
            ctaBackgroundColor = UIColor.ud.colorfulWathet
            ctaHightlightColor = UIColor.ud.W600
        case .weibo:
            ctaIcon = Resources.cta_weibo
            ctaTitle = BundleI18n.LarkSnsShare.Lark_Invitation_ShareViaWeibo_ImageCreatedAndSaved_button
            ctaBackgroundColor = UIColor.ud.colorfulRed
            ctaHightlightColor = UIColor.ud.R600
        }

        switch material {
        case .text(let title, let content):
            panelTitle = title
            defalutPanelTitle = BundleI18n.LarkSnsShare.Lark_Invitation_InviteViaWeChat_General_Title
            copyContent = content
        case .image(let title):
            panelTitle = title
            defalutPanelTitle = BundleI18n.LarkSnsShare.Lark_Invitation_ShareViaWeChat_ImageCreatedAndSaved
        }

        let panelConfig = PanelConfig(
            copyContent: copyContent ?? "",
            title: panelTitle ?? defalutPanelTitle,
            displayContent: copyContent ?? "",
            ctaButtonIcon: ctaIcon,
            ctaButtonTitle: ctaTitle,
            ctaButtonTitleColor: UIColor.ud.primaryOnPrimaryFill,
            ctaButtonBackgroundColor: ctaBackgroundColor,
            ctaButtonHightlightColor: ctaHightlightColor,
            skipButtonTitle: BundleI18n.LarkSnsShare.Lark_Invitation_TeamCodeClose,
            contentAlignment: .left,
            autoOperationHandler: autoOperationHandler,
            ctaButtonDidClick: ctaButtonDidClick,
            skipButtonDidClick: skipButtonDidClick
        )

        super.init(panelConfig: panelConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
