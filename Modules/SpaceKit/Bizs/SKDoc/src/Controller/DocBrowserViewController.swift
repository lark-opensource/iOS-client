//
//  DocBrowserViewController.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/16.
//  

import Foundation
import SKCommon
import SKBrowser
import SKFoundation
import SKUIKit
import SKResource
import SpaceInterface

public final class DocBrowserViewController: BrowserViewController {
    
    public weak var syncedBlockContainer: SyncedBlockContainerDelegate?
    
    public weak var docComponentHostDelegate: DocComponentHostDelegate?
    
    var shouldShowCatalogItem: Bool {
        if let url = self.editor.currentURL, let from = url.docs.queryParams?["from"] {
            if from == "group_tab_notice" || isSubscription {
                return false
            }
        }

        if editor.isShowApplyPermissionView, !editor.isPermssionAdminBlocked {
            return false
        }

        let enableType: [DocsType] = [.doc, .docX, .wiki]
        return enableType.contains(docsInfo?.type ?? .unknownDefaultType) && SKDisplay.pad && !needHidenCatalogInVesion()
    }

    public override var canShowCatalogItem: Bool {
        return shouldShowCatalogItem
    }
    
    
    public override var canShowBackItem: Bool {
        if self.showCloseInDocComponent {
            return false
        }
        return super.canShowBackItem
    }
    
    public override func refreshLeftBarButtons() {
        super.refreshLeftBarButtons()
        if self.showCloseInDocComponent {
            let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
            if canShowDoneItem {
                self.navigationBar.leadingBarButtonItems.removeAll(where: { $0 == closeButtonItem })
            } else if !itemComponents.contains(closeButtonItem) {
                self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
            }
        }
    }

    public override func fillOnboardingMaterials() {
        _fillDocOnboardingTypes()
        _fillDocOnboardingArrowDirections()
        _fillDocOnboardingTitles()
        _fillDocOnboardingHints()
    }

    public override func showOnboarding(id: OnboardingID) {
        guard let type = onboardingTypes[id] else {
            DocsLogger.onboardingError("Doc 前端调用的引导 \(id) 没有被注册")
            return
        }

        DocsLogger.onboardingInfo("Doc 前端调用显示 \(id)")
        switch type {
        case .text: OnboardingManager.shared.showTextOnboarding(id: id, delegate: self, dataSource: self)
        case .flow: OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        case .card: OnboardingManager.shared.showCardOnboarding(id: id, delegate: self, dataSource: self)
        }
    }
    public override func catalogDisplayButtonItemAction() {
        _catalogDisplayButtonItemAction()
    }
    
    public override func logNavBarEvent(_ event: DocsTracker.EventType,
                                        click: String? = nil,
                                        target: String? = "none",
                                        extraParam: [String: String]? = nil) {
        if let clickItem = click {
            self.editor.docComponentDelegate?.docComponentHost(self,
                                                               onEvent: .onNavigationItemClick(item: clickItem))
        }
        super.logNavBarEvent(event, click: click, target: target, extraParam: extraParam)
    }
    
    public override func refresh() {
        if docsInfo?.originType == .sync, self.syncedBlockContainer != nil {
            self.syncedBlockContainer?.refresh()
        } else {
            super.refresh()
        }
    }
}

extension DocBrowserViewController {

    private func _fillDocOnboardingTypes() {
        onboardingTypes = [
            OnboardingID.docTranslateIntro: OnboardingType.text,
            .docTodoCenterIntro: .text,
            .docToolbarV2AddNewBlock: .text,
            .docToolbarV2BlockTransform: .text,
            .docToolbarV2Pencilkit: .text,
            .docBlockMenuPenetrableIntro: .text,
            .docBlockMenuPenetrableComment: .text,
            .docIPadCatalogIntro: .flow,
            .docWidescreenModeIntro: .flow,
            .docSmartComposeIntro: .text,
            .docInsertTable: .text,
            .bitableFieldEditIntro: .text
        ]
    }

    private func _fillDocOnboardingArrowDirections() {
        onboardingArrowDirections = [
            OnboardingID.docTranslateIntro: OnboardingStyle.ArrowDirection.targetBottomEdge,
            .docToolbarV2AddNewBlock: .targetTopEdge,
            .docToolbarV2BlockTransform: .targetTopEdge,
            .docToolbarV2Pencilkit: .targetTopEdge,
            .docIPadCatalogIntro: .targetBottomEdge,
            .docWidescreenModeIntro: .targetBottomEdge,
            .docTodoCenterIntro: .targetTopEdge
        ]
    }

    private func _fillDocOnboardingTitles() {
        onboardingTitles = [
            OnboardingID.docIPadCatalogIntro: BundleI18n.SKResource.CreationMobile_Docs_Menu_Tooltip_Title,
            .docWidescreenModeIntro: BundleI18n.SKResource.CreationMobile_Docs_More_FullWidth_Tooltip_Title1,
            .docSmartComposeIntro: BundleI18n.SKResource.Doc_Lark_SmartCompose
        ]
    }

    private func _fillDocOnboardingHints() {
        onboardingHints = [
            OnboardingID.docTranslateIntro: BundleI18n.SKResource.Doc_Translate_Intro,
            .docToolbarV2AddNewBlock: BundleI18n.SKResource.Doc_Toolbar_AddNewBlock,
            .docToolbarV2BlockTransform: BundleI18n.SKResource.Doc_Toolbar_BlockTransform,
            .docToolbarV2Pencilkit:
                BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_FeatureDescription_Toast(),
            .docBlockMenuPenetrableIntro: BundleI18n.SKResource.Doc_BlockMenu_Intro,
            .docBlockMenuPenetrableComment: BundleI18n.SKResource.Doc_BlockMenu_Comment_Intro,
            .docIPadCatalogIntro: BundleI18n.SKResource.CreationMobile_Docs_Menu_Tooltip_Content,
            .docWidescreenModeIntro: BundleI18n.SKResource.CreationMobile_Docs_More_FullWidth_Tooltip_Content1,
            .docSmartComposeIntro: BundleI18n.SKResource.Doc_Lark_SmartComposeOnboardMobile,
            .docTodoCenterIntro: BundleI18n.SKResource.CreationMobile_Docs_TaskCenter_Onboarding_Tooltip,
            .docInsertTable: BundleI18n.SKResource.CreationMobile_Docs_InsertTable_Onboarding_Toast,
            .bitableFieldEditIntro: BundleI18n.SKResource.Bitable_Field_OnboardingCardDesc
        ]
    }
}
