//
//  MindNoteBrowserViewController.swift
//  SKMindnote
//
//  Created by guoqp on 2022/9/20.
//

import Foundation
import SKBrowser
import SKCommon
import SKFoundation
import SKUIKit
import SKResource

public final class MindNoteBrowserViewController: BrowserViewController {

    public override func fillOnboardingMaterials() {
        _fillOnboardingTypes()
        _fillOnboardingArrowDirections()
        _fillOnboardingTitles()
        _fillBitableOnboardingHints()
    }

    public override func showOnboarding(id: OnboardingID) {
        guard let type = onboardingTypes[id] else {
            DocsLogger.onboardingError("bitable onboarding \(id) is nil")
            return
        }
        DocsLogger.onboardingInfo("bitable show onboarding \(id)")
        switch type {
        case .text: OnboardingManager.shared.showTextOnboarding(id: id, delegate: self, dataSource: self)
        case .flow: OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        case .card: OnboardingManager.shared.showCardOnboarding(id: id, delegate: self, dataSource: self)
        }
    }
}

extension MindNoteBrowserViewController {
    private func _fillOnboardingTypes() {
    }

    private func _fillOnboardingArrowDirections() {
    }

    private func _fillOnboardingTitles() {
    }

    private func _fillBitableOnboardingHints() {
        onboardingHints = [
            .bitableFieldEditIntro: BundleI18n.SKResource.Bitable_Field_OnboardingCardDesc
        ]
    }
}
