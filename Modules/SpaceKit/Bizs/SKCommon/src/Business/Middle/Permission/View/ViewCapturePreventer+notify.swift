//
//  ViewCapturePreventer+notify.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/7/10.
//  


import UIKit
import Foundation
import SKFoundation
import SKResource
import UniverseDesignToast
import LarkEMM
import LarkContainer

extension ViewCapturePreventer {
    
    /// 负责弹toast
    class Notifier {
        
        @Provider private var service: ScreenProtectionService
        
        private let toastBottomMargin = CGFloat(220)
        
        weak var dataSource: ViewCapturePreventable?
        
        var onToastShown: (() -> Void)?
        
        init() {
            let name1 = Notification.Name.SpaceTabItemTapped
            NotificationCenter.default.addObserver(self, selector: #selector(handleTabItemTap), name: name1, object: nil)
            
            let name2 = UIApplication.userDidTakeScreenshotNotification
            NotificationCenter.default.addObserver(self, selector: #selector(handleSnapshot), name: name2, object: nil)
            
            let name3 = ViewCapturePreventer.debugAllowStateDidChange
            NotificationCenter.default.addObserver(self, selector: #selector(handleDebugValue), name: name3, object: nil)
            
            let name4 = Notification.Name.BaseTabItemTapped
            NotificationCenter.default.addObserver(self, selector: #selector(handleTabItemTap), name: name4, object: nil)
        }
        
        /// 处理 isCaptureAllowed 设置变化
        func handleCaptureAllowedStateChange(oldValue: Bool, newValue: Bool) {
            let isCapturing = UIScreen.main.isCaptured
            let isMirrored = UIScreen.isMainScreenMirrored()
            DocsLogger.info("oldValue:\(oldValue), newValue:\(newValue), isCapturing:\(isCapturing)")
            let isRecording = isCapturing && !isMirrored // 正在录屏
            if !didShowToastDuringSession {
                if newValue == false, isRecording { // 首次遇到false
                    showRecordNotAllowedToast()
                    didShowToastDuringSession = true
                }
            } else {
                if newValue == false, oldValue == true, isRecording { // 非首次，由true -> false
                    showRecordNotAllowedToast()
                    didShowToastDuringSession = true
                }
            }
        }
        
        func removeToastIfExists() {
            if let onView = getToastContainerView() {
                UDToast.removeToast(on: onView)
            }
        }
        
        func handleRecordChange(isStartRecord: Bool, allowRecord: Bool) {
            if isStartRecord, allowRecord == false {
                showRecordNotAllowedToast()
            }
            DocsLogger.info("handleRecordScreen start:\(isStartRecord), allowRecord:\(allowRecord)",
                            component: LogComponents.permission)
        }
        
        @objc
        func handleSnapshot() {
            guard let source = dataSource else { return }
            
            if source.isCaptureAllowed == false {
                let text = BundleI18n.SKResource.CreationMobile_Docs_OCR_NotAllowed_Screenshot
                if let onView = getToastContainerView(), !service.isSecureProtection {
                    UDToast.showFailure(with: text, on: onView).setCustomBottomMargin(toastBottomMargin)
                    onToastShown?()
                }
                DocsLogger.info("ViewCapturePreventer Toast text: \(text)",
                                component: LogComponents.permission)
            }
            DocsLogger.info("handleSnapshot: isCaptureAllowed: \(source.isCaptureAllowed)",
                            component: LogComponents.permission)
        }
        
        @objc
        private func handleTabItemTap(_ noti: NSNotification) {
            guard let source = dataSource else { return }
            guard let isSameTab = noti.userInfo?[SpaceTabItemTappedNotificationKey.isSameTab] as? Bool else { return }
            let isCapturing = UIScreen.main.isCaptured
            let isMirrored = UIScreen.isMainScreenMirrored()
            DocsLogger.info("isSameTab:\(isSameTab), isCaptureAllowed: \(source.isCaptureAllowed), isCapturing:\(isCapturing)",
                            component: LogComponents.permission)
            if !isSameTab, !source.isCaptureAllowed, isCapturing, !isMirrored {
                showRecordNotAllowedToast()
            }
        }
        
        @objc
        private func handleDebugValue(_ noti: NSNotification) {
            let isAllow = (noti.userInfo?["isAllow"] as? Bool) ?? false
            if isAllow { // 只处理:强制打开
                dataSource?.isCaptureAllowed = isAllow
            }
        }
        
        private func showRecordNotAllowedToast() {
            let text = BundleI18n.SKResource.CreationMobile_Docs_OCR_NotAllowed_Screenrecord
            if let onView = getToastContainerView(), !service.isSecureProtection {
                UDToast.showFailure(with: text, on: onView).setCustomBottomMargin(toastBottomMargin)
                onToastShown?()
            }
            DocsLogger.info("ViewCapturePreventer Toast text: \(text)",
                            component: LogComponents.permission)
        }
        
        private func getToastContainerView() -> UIView? {
            let contentView = dataSource?.contentView
            let types = dataSource?.notifyContainer ?? []
            if types.contains(.superView),
               let superview = contentView?.superview, superview.frame.width > 0, superview.frame.height > 0 {
                return superview
            }
            if types.contains(.window), let window = contentView?.window {
                return window
            }
            if types.contains(.controller), let vcView = contentView?.affiliatedViewController?.view {
                return vcView
            }
            if types.contains(.thisView),
               let view = contentView, view.frame.width > 0, view.frame.height > 0 { // view尺寸为0时toast会显示异常
                return view
            }
            
            let desc1 = String(describing: contentView)
            let desc2 = String(describing: dataSource?.notifyContainer)
            let desc3 = String(describing: contentView?.affiliatedViewController)
            let descAll = [desc1, desc2, desc3].joined(separator: ", ")
            DocsLogger.info("getToastContainerView `nil`, \(descAll)", component: LogComponents.permission)
            return nil
        }
    }
}

private var didShowPreventToastOnceKey: UInt8 = 0

extension ViewCapturePreventer.Notifier {
    /// 在录屏中途是否曾弹出过`无法录屏`的toast，用于保证至少弹出一次但避免后续反复弹
    var didShowToastDuringSession: Bool {
        get {
            (objc_getAssociatedObject(self, &didShowPreventToastOnceKey) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &didShowPreventToastOnceKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}
