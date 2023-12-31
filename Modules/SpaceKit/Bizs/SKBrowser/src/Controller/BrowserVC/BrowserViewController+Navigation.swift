//
//  BrowserViewController+CustomNavigator.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/12/16.
//
//  CustomNavigatorDocsBrowserViewController被拆迁成BrowserViewController的Extension


import UIKit
import SKCommon
import SKUIKit
import SKFoundation
import LarkUIKit
import RxSwift
import UniverseDesignIcon
import SKResource

// MARK: NavigationBar Title Special logic
// FIXME: 应该各个 BrowserViewController 的子类提供实现，而不是在基类这里判断文件类型实现
extension BrowserViewController: SKNavigationBarTitleUIDelegate {
    public func titleBarShouldShowExternalLabel(_ titleBar: SKNavigationBarTitle) -> Bool {
        if let docType = DocsUrlUtil.getFileType(from: docsURL.value) {
            if docType == .mindnote {
                return false   // 思维笔记不显示租户标签
            } else if docType == .doc {
                if User.current.info?.isToNewC == true {
                    //小B用户不需要展示标签
                    return false
                }
                return titleBar.shouldShowTexts //doc外部标签需要和标题一起显示
            } else if docType == .sheet {
                if User.current.info?.isToNewC == true {
                    //小B用户不需要展示标签
                    return false
                }
                return true
            }
        }
        return true
    }
    public func titleBarShouldShowSecondTagLabel(_ titleBar: SKNavigationBarTitle) -> Bool {
        return false
    }
    
    public func titleBarShouldShowTemplateTag(_ titleBar: SKNavigationBarTitle) -> Bool {
        return titleBar.titleLabel.intrinsicContentSize.height > 0.001
    }

    public func titleBarShouldShowTitle(_ titleBar: SKNavigationBarTitle) -> Bool {
        guard let inherentType = docsInfo?.inherentType else {
            return true
        }
        switch inherentType {
        case .sheet:
            if SKDisplay.pad {
                navigationBar.titleShouldRename = false
            }
            if SKDisplay.phone {
                return docsInfo?.isVersion ?? false
            }
        case .bitable:
            if SKDisplay.phone {
                return false
            }
            return true
        default:
            return true
        }
        return true
    }

    public func titleBarShouldShowAvatar(_ titleBar: SKNavigationBarTitle) -> Bool {
        // Sheet的特定条件不显示
        if docsInfo?.type == .sheet {
            return false
        }
        return true
    }

    public func configureAvatarImageView(_ avatarImage: DocsAvatarImageView, with icon: IconSelectionInfo?) {
        avatarImage.configure(icon, trigger: "navigation_bar_icon")
    }
    
    public func titleBarShouldShowActionButton(_ titleBar: SKUIKit.SKNavigationBarTitle) -> Bool {
        guard docsInfo?.isVersion == true, canShowVersionTitle else {
            return false
        }
        return true
    }
    
    public func titleBarShowTitle() -> String? {
        guard docsInfo?.isVersion == true, canShowVersionTitle else {
            return nil
        }
        return  BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Header_Mob(docsInfo!.versionInfo?.name ?? "")
    }
    
    public func configureActionButton(_ tipIcon: UIImageView) {
        guard docsInfo?.isVersion == true, canShowVersionTitle else {
            return
        }
        tipIcon.backgroundColor = .clear
        tipIcon.image = UDIcon.downBoldOutlined.colorImage(UIColor.ud.iconN1)
        tipIcon.contentMode = .scaleAspectFit
    }
    
    public func updateActionButton(_ tipIcon: UIImageView) {
        guard docsInfo?.isVersion == true, canShowVersionTitle else {
            return
        }
        tipIcon.image = UDIcon.downBoldOutlined.colorImage(UIColor.ud.iconN1)
    }
    
    public func actionButtonHandle(_ tipIcon: UIImageView, dissCallBack: @escaping() -> Void) {
        guard docsInfo?.isVersion == true, canShowVersionTitle else {
            return
        }
        tipIcon.image = UDIcon.upBoldOutlined.colorImage(UIColor.ud.iconN1)
        self.showVersionsListPanel(dissCallBack: dissCallBack)
    }
}

// MARK: - Navigation Bar Helper Methods

extension BrowserViewController {

    public func getNavBarLeftButtonFrame(by id: SKNavigationBar.ButtonIdentifier) -> CGRect? {
        guard !navigationBar.isHidden else { return nil }
        for button in navigationBar.leadingButtons where button.item?.id == id {
            guard !button.isHidden && button.bounds != .zero else { return nil }
            return button.convert(button.bounds, to: view)
        }
        return nil
    }

    public func getNavBarRightButtonFrame(by id: SKNavigationBar.ButtonIdentifier) -> CGRect? {
        guard !navigationBar.isHidden else { return nil }
        for button in navigationBar.trailingButtons where button.item?.id == id {
            guard !button.isHidden && button.bounds != .zero else { return nil }
            return button.convert(button.bounds, to: view)
        }
        return nil
    }
}

/// 重复打开文档处理者
/// (场景: 点击推送进入文档需要弹出feed面板vc，但如果已经处于该文档的vc中了，需要让该vc直接弹出feed面板vc)
public protocol RepetitiveOpenBrowserHandler {
    
    /// 触发了打开文档的请求，目标vc与当前topvc是同一个
    func didReceiveOpenRequestWhenTargetVcIsCurrentTop(fileConfig: FileConfig)
}

extension BrowserViewController: RepetitiveOpenBrowserHandler {
    
    public func didReceiveOpenRequestWhenTargetVcIsCurrentTop(fileConfig: FileConfig) {
        
        let logPrefix = #function
        
        updateConfig(fileConfig)
        
        var params: [String: Any] = ["animated": true, "isFromLarkFeed": true]
        guard let feedFromInfo = self.fileConfig?.feedFromInfo, feedFromInfo.canShowFeedAtively else {
            DocsLogger.info("\(logPrefix), feedFromInfo: \(self.fileConfig?.feedFromInfo?.description ?? "")")
            return
        }
        feedFromInfo.record(.openPanel)
        params["feedInfo"] = feedFromInfo
        DocsLogger.info("\(logPrefix), open feed: \(feedFromInfo.description)")
        editor.jsEngine.simulateJSMessage(DocsJSService.feedShowMessage.rawValue, params: params)
    }
}

private extension FeedFromInfo {
    
    var description: String {
        let logInfo = ["feedId: \(feedId)",
                       "isFromLarkFeed: \(isFromLarkFeed)",
                       "unreadCount: \(unreadCount)",
                       "messageType: \(messageType)",
                       "isFromPushNotification: \(isFromPushNotification)"]
            .joined(separator: ", ")
        return logInfo
    }
}
