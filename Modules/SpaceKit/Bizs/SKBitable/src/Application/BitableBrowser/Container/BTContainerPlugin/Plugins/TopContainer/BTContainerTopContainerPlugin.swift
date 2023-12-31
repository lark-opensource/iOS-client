//
//  BTContainerTopContainerPlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import SKFoundation
import SKBrowser
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKCommon

final class BTContainerTopContainerPlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            topContainer
        }
    }
    
    private lazy var titleInfo = NavigationTitleInfo(customView: sideFoldBarButton, displayType: .fullCustomized)
    
    private lazy var sideFoldBarButton: SideFoldBarButton = {
        let view = SideFoldBarButton()
        view.control.addTarget(self, action: #selector(switchBlockContainerPerform), for: .touchUpInside)
        return view
    }()
    
    override func didUpdateHeaderModel(headerModel: BaseHeaderModel) {
        super.didUpdateHeaderModel(headerModel: headerModel)
        sideFoldBarButton.updateTitle(title: headerModel.subTitle)
    }
    
    private var topContainer: BrowserTopContainer? {
        get {
            service?.browserViewController?.topContainer
        }
    }
    
    override func load(service: BTContainerService) {
        super.load(service: service)
        guard let topContainer = topContainer else {
            DocsLogger.error("invalid topContainer")
            return
        }
        topContainer.layer.masksToBounds = true
        
        topContainer.navBar.titleInfo = NavigationTitleInfo(customView: sideFoldBarButton, displayType: .fullCustomized)
        var layoutAttributes = SKNavigationBar.LayoutAttributes(titleFont: UIFont.systemFont(ofSize: 17, weight: .medium), titleTextColor: UDColor.textTitle, subTitleFont: UIFont.systemFont(ofSize: 12, weight: .regular), subTitleTextColor: UDColor.textCaption, interButtonSpacing: 20, barHorizontalInset: 20, titleHorizontalAlignment: .leading, titleVerticalAlignment: .center)
        layoutAttributes.titleHorizontalOffsetWhenLeft1Button = 16
        layoutAttributes.titleHorizontalOffset = 8
        layoutAttributes.buttonHitTestInset = UIEdgeInsets(top: -6, left: 0, bottom: -6, right: 0)
        topContainer.navBar.layoutAttributes = layoutAttributes
        
        
        topContainer.navBar.disableCustomBackgroundColor = true  // 禁止其他逻辑自定义背景色
        topContainer.navBar.customizeBarAppearance(
            backgroundColor: BTContainer.Constaints.navBarBackgroundColor,
//            itemBackgroundColorMapping: SKNavigationBar.BitableStyle.itemBackgroundColorMapping,
            iconHeight: BTContainer.Constaints.navBarIconHeight,
            cornerRadius: BTContainer.Constaints.navBarButtonBackgroundCornerRadius)
    }
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        if new.fullScreenType == .none, stage == .animationBeginStage {
            if new.shouldShowSideBarButton != old?.shouldShowSideBarButton {
                refreshSideBarButtons(status: new, true) // 这种情况需要刷左侧按钮
            }
        }
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        guard let topContainer = topContainer else {
            DocsLogger.error("invalid topContainer")
            return
        }
        
        if new.fullScreenType == .webFullScreen || new.fullScreenType == .webFullScreenShowStatusBar {
            topContainer.alpha = 0
            return
        }
        
        if new.fullScreenType != .none {
            sideFoldBarButton.hide(animated: false)
        } else if stage == .finalStage, new.shouldShowSideBarButton != old?.shouldShowSideBarButton {
            refreshSideBarButtons(status: new, false) // 这种情况需要刷左侧按钮
        } else if stage == .finalStage, sideFoldBarButton.isShow != new.shouldShowSideBarButton {
            refreshSideBarButtons(status: new, false)
        }
        
        if new.isRegularMode {
            topContainer.backgroundColor = .clear
        } else {
            if new.blockCatalogueHidden {
                if new.baseHeaderHidden {
                    topContainer.backgroundColor = BTContainer.Constaints.viewCatalogueTopColor
                } else {
                    topContainer.backgroundColor = .clear
                }
            } else {
                topContainer.backgroundColor = .clear
            }
        }
        
        if new.blockCatalogueHidden {
            topContainer.transform = CGAffineTransform(translationX: 0, y: 0)
            topContainer.alpha = 1
        } else {
            if new.baseHeaderHidden {
                if new.isRegularMode {
                    topContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                    topContainer.alpha = 1
                } else {
                    topContainer.transform = CGAffineTransform(translationX: new.blockCatalogueWidth, y: 0)
                    topContainer.alpha = 0
                }
            } else {
                if new.isRegularMode {
                    topContainer.transform = CGAffineTransform(translationX: 0, y: 0)
                    topContainer.alpha = 1
                } else {
                    topContainer.transform = CGAffineTransform(translationX: 0, y: -new.topContainerHeight)
                    topContainer.alpha = 0
                }
            }
        }
        
    }
    
    func setFullScreenProgress(_ progress: CGFloat, forceUpdate: Bool = false, editButtonAnimated: Bool = true, topContainerAnimated: Bool = true) {
        guard let topContainer = topContainer else {
            DocsLogger.error("invalid topContainer")
            return
        }
        if progress == 0.0 {
            topContainer.navBar.isHidden = false
        } else if progress == 1.0 {
            topContainer.navBar.isHidden = true
        }
        topContainer.updateSubviewsContraints()
    }
    
    private var isFromTemplatePreview: Bool {
        get {
            service?.browserViewController?.isFromTemplatePreview == true
        }
    }
    
    func updateNavBarHeightIfNeeded() {
        guard let topContainer = topContainer else {
            DocsLogger.error("invalid topContainer")
            return
        }
        topContainer.navBar.navigationMode = .blocking(list: [.tree])
        topContainer.navBar.sizeType = .formSheet
    }
    
    public func refreshSideBarButtons(status: BTContainerStatus, _ animated: Bool) {
        guard let topContainer = topContainer else {
            return
        }
        if titleInfo.displayType != topContainer.navBar.titleInfo?.displayType {
            DocsLogger.warning("displayType has changed")
            topContainer.navBar.titleInfo = titleInfo
        }
        if status.shouldShowSideBarButton {
            sideFoldBarButton.show(animated: animated)
        } else {
            sideFoldBarButton.hide(animated: animated)
        }
    }
    
    @objc
    private func switchBlockContainerPerform() {
        DocsLogger.info("switchBlockContainerPerform")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.setBlockCatalogueHidden(blockCatalogueHidden: !status.blockCatalogueHidden, animated: true)
        service.trackContainerEvent(.bitableCalloutSidebarClick,
                                    params: ["click": "callout_sidebar",
                                             "sidebar_type": "table_list"])
    }
    
}
