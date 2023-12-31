//
//  SheetBrowserViewController.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/16.
//  


import Foundation
import SKBrowser
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UIKit
import SKInfra

public final class SheetBrowserViewController: BrowserViewController {

    public override var topContainer: BrowserTopContainer { sheetTopContainer }

    lazy var sheetTopContainer = SheetBrowserTopContainer(navBar: self.navigationBar)

    var tabSwitcher: SheetTabSwitcherView { sheetTopContainer.tabSwitcher }

    weak var sheetInputView: SheetInputView?

    weak var toolbar: SheetToolbar?

    weak var fabContainer: FABContainer?

    weak var toolkitManager: SheetToolkitManager?

    var isInSheetCardMode = false // 是否在 Sheet 卡片模式中

    var fakeCollectionView: UICollectionView? // 在 sheet 工作表栏 drag and drop 的过程中，在工作表栏下方贴一个假的 collection view，并设为不支持 drop，从而隐藏被拖动 cell 右上角的绿色加号
    
    public var renameSheetRequest: DocsRequest<Bool>?

    public override func setupView() {
        view.addSubview(statusBar)
        statusBar.snp.makeConstraints { it in
            it.top.leading.trailing.equalToSuperview()
            it.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        super.setupView()
        topPlaceholder.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.height.equalTo(topContainer)
        }
        sheetTopContainer.sheetDelegate = self
        navigationBar.renameDelegate = self
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        editor.permissionConfig.permissionEventNotifier.addObserver(self)
    }

    public override var canShowInNewScene: Bool {
        if docsInfo?.isOriginDriveFile == true {
            return false
        }
        return super.canShowInNewScene
    }

    public override func updatePhoneUI(for orientation: UIInterfaceOrientation) {
        var shouldHideCustomTopContainer = orientation.isLandscape && SKDisplay.phone
        if orientation.isLandscape, let hideCustomHeaderInLandscape = self.browerEditor?.customTCDisplayConfig?.hideCustomHeaderInLandscape {
            shouldHideCustomTopContainer = hideCustomHeaderInLandscape
        }
        customTCMangager.setCustomTopContainerHidden(shouldHideCustomTopContainer)
        super.updatePhoneUI(for: orientation)
    }

    public override func viewDidTransition(from oldSize: CGSize, to size: CGSize) {
        super.viewDidTransition(from: oldSize, to: size)
        tabSwitcher.updateTrailingButton()
    }
    
    public override func viewDidSplitModeChange() {
        super.viewDidSplitModeChange()
        tabSwitcher.updateTrailingButton()
    }

    public override func fillOnboardingMaterials() {
        _fillSheetOnboardingTypes()
        _fillSheetOnboardingArrowDirections()
        _fillSheetOnboardingTitles()
        _fillSheetOnboardingHints()
    }

    public override func showOnboarding(id: OnboardingID) {
        guard let type = onboardingTypes[id] else {
            DocsLogger.onboardingError("Sheet 前端调用的引导 \(id) 没有被注册")
            return
        }

        DocsLogger.onboardingInfo("Sheet 前端调用显示 \(id)")
        switch type {
        case .text: OnboardingManager.shared.showTextOnboarding(id: id, delegate: self, dataSource: self)
        case .flow: OnboardingManager.shared.showFlowOnboarding(id: id, delegate: self, dataSource: self)
        case .card: OnboardingManager.shared.showCardOnboarding(id: id, delegate: self, dataSource: self)
        }
    }

    public override func setupFeelGood() {
        if let type = docsInfo?.type,
           let scenarioType = FeelGoodRegister.conver(type) {
            magicRegister = FeelGoodRegister(type: scenarioType, businessInterceptor: self) {
                [weak self] in return self
            }
        }
    }

    public override func setFullScreenProgress(_ progress: CGFloat, forceUpdate: Bool = false, editButtonAnimated: Bool = true, topContainerAnimated: Bool = true) {
        if progress == 0.0 && UIApplication.shared.statusBarOrientation.isPortrait {
            sheetTopContainer.navBar.isHidden = false
        } else if progress == 1.0 {
            sheetTopContainer.navBar.isHidden = true
        }
        sheetTopContainer.updateSubviewsContraints()
    }

    public override func updateTopPlaceholderHeight(webviewContentOffsetY: CGFloat, scrollView: EditorScrollViewProxy? = nil, forceUpdate: Bool = false) {
        // sheet 的 top container 和 top placeholder 是永远同高度的，自动布局有约束，所以不用做任何处理
    }

    public override func topContainerDidUpdateSubviews() {
        topPlaceholder.setNeedsLayout()
//        debugPrint("sheet&*()\(newHeight): topPlaceholder.frame.height: \(topPlaceholder.frame.height), topContainer.frame.height: \(topContainer.frame.height)")
    }
}

extension SheetBrowserViewController {

    private func _fillSheetOnboardingTypes() {
        onboardingTypes = [
            .sheetRedesignSearch: .text,
            .sheetRedesignListMode: .text,
            .sheetRedesignViewImage: .text,
            .sheetRedesignCardModeEdit: .card,
            .sheetLandscapeIntro: .card,
            .sheetNewbieIntro: .card,
            .sheetNewbieSearch: .flow,
            .sheetNewbieEdit: .flow,
            .sheetToolbarIntro: .flow,
            .sheetOperationPanelOperate: .flow,
            .sheetCardModeShare: .flow,
            .sheetCardModeToolbar: .flow,
            .sheetCardModeDrag: .text,
            .bitableFieldEditIntro: .text
        ]
    }

    private func _fillSheetOnboardingArrowDirections() {
        onboardingArrowDirections = [
            .sheetRedesignListMode: .targetBottomEdge,
            .sheetNewbieSearch: .targetBottomEdge,
            .sheetNewbieEdit: .targetTopEdge,
            .sheetToolbarIntro: .targetTopEdge,
            .sheetOperationPanelOperate: .targetTopEdge,
            .sheetCardModeShare: .targetBottomEdge,
            .sheetCardModeToolbar: .targetTopEdge,
            .sheetCardModeDrag: .targetTopEdge,
            .bitableFieldEditIntro: .targetBottomEdge
        ]
    }

    private func _fillSheetOnboardingTitles() {
        onboardingTitles = [
            OnboardingID.sheetLandscapeIntro: BundleI18n.SKResource.Sheet_Landscape_Intro,
            .sheetRedesignCardModeEdit: BundleI18n.SKResource.Doc_Sheet_CardModeEditOnboardingTitle,
            .sheetNewbieIntro: BundleI18n.SKResource.Sheet_Newbie_Intro,
            .sheetNewbieSearch: BundleI18n.SKResource.Sheet_Newbie_Search,
            .sheetNewbieEdit: BundleI18n.SKResource.Sheet_Newbie_Edit,
            .sheetToolbarIntro: BundleI18n.SKResource.CreationMobile_Tips_Title,
            .sheetOperationPanelOperate: BundleI18n.SKResource.CreationMobile_Tips_Title,
            .sheetCardModeShare: BundleI18n.SKResource.CreationMobile_Sheets_ShareCardTitle,
            .sheetCardModeToolbar: BundleI18n.SKResource.CreationMobile_Sheets_CardViewTitle
        ]
    }

    private func _fillSheetOnboardingHints() {
        onboardingHints = [
            .sheetRedesignCardModeEdit: BundleI18n.SKResource.Doc_Sheet_CardModeEditOnboardingHint,
            .sheetRedesignListMode: BundleI18n.SKResource.Sheet_Redesign_ListMode,
            .sheetRedesignViewImage: BundleI18n.SKResource.Sheet_Redesign_ViewImage,
            .sheetLandscapeIntro: BundleI18n.SKResource.Sheet_Landscape_IntroHint,
            .sheetNewbieIntro: BundleI18n.SKResource.Sheet_Newbie_IntroHint,
            .sheetNewbieSearch: BundleI18n.SKResource.Sheet_Newbie_SearchHint,
            .sheetNewbieEdit: BundleI18n.SKResource.Sheet_Newbie_EditHint,
            .sheetToolbarIntro: BundleI18n.SKResource.CreationMobile_Tips_Bodytext,
            .sheetOperationPanelOperate: BundleI18n.SKResource.CreationMobile_Toolbox_Action,
            .sheetCardModeShare: BundleI18n.SKResource.CreationMobile_Sheets_ShareCard,
            .sheetCardModeToolbar: BundleI18n.SKResource.CreationMobile_Sheets_CardViewText,
            .sheetCardModeDrag: BundleI18n.SKResource.CreationMobile_Sheets_FullCard,
            .bitableFieldEditIntro: BundleI18n.SKResource.Bitable_Field_OnboardingCardDesc
        ]
    }
}

extension SheetBrowserViewController: SheetRenameRequest {
    public func beginRenamingSheet() -> Bool {
        logNavBarEvent(.navigationBarClick, click: "rename")
        if let toolbar = toolbar, let sheetInputView = sheetInputView, sheetInputView.isFirstResponder {
            toolbar.delegate?.didRequestHideKeyboard()
            sheetInputView.endEdit()
            return true
        }
        return false
    }

    public func renameSheet(_ newTitle: String, nodeToken: String?, completion: ((_ error: Error?) -> Void)?) {
        guard let docsInfo = self.docsInfo else {
            return
        }
        let objToken = docsInfo.objToken
        self.renameSheetRequest?.cancel()
        self.renameSheetRequest = DocsRequest<Bool>(path: OpenAPI.APIPath.renameSheet, params: ["token": docsInfo.objToken, "title": newTitle])
        self.renameSheetRequest?.set(transform: { [weak renameSheetRequest] (result) -> (Bool?, error: Error?) in
            if let err = DocsNetworkError(result?["code"].int), err.code != .success {
                DocsLogger.error("重命名 sheet 失败 reqID: \(renameSheetRequest?.requestID ?? "nil")", error: err)
                return (false, err)
            } else {
                // 旧的逻辑
                return (true, nil)
            }
        }).start(result: { [weak renameSheetRequest, weak self] (_, error) in
            guard (error as? URLError)?.errorCode != NSURLErrorCancelled else {
                return
            }
            completion?(error)
            if error == nil {
                self?.notifyFrontendTitleDidChange(to: newTitle)
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.rename(objToken: objToken, with: newTitle)
            } else {
                DocsLogger.error("重命名 sheet 失败 reqID: \(renameSheetRequest?.requestID ?? "nil")", error: error)
            }
        })
    }

    private func notifyFrontendTitleDidChange(to newTitle: String) {
        editor.callFunction(.setTitle, params: ["title": newTitle], completion: nil)
    }
}

extension SheetBrowserViewController: DocsPermissionEventObserver {
    
    public func onCopyPermissionUpdated(canCopy: Bool) {
        sheetTopContainer.setCaptureAllowed(canCopy)
    }
}
