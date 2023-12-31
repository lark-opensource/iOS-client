//
//  ScanQRManager.swift
//  SKCommon
//
//  Created by zengsenyuan on 2022/5/30.
//  


import SKUIKit
import SKFoundation
import SpaceInterface

public struct ScanQRManager {
    

    public enum VCFollowDelegateType {
        case browser(_ delegate: BrowserVCFollowDelegate?) //这里用可选是为了让外面传参数更加方便
        case space(_ delegate: SpaceFollowAPIDelegate?)
    }
    /// 打开二维码
    /// - Parameters:
    ///   - code: 二维码信息
    ///   - fromVC: 从哪里进行跳转
    ///   - vcFollowDelegateType: 如果当前再 VC 中，做处理
    public static func openScanQR(code: String, fromVC: UIViewController, vcFollowDelegateType: VCFollowDelegateType?) {
        
        func openScanQRService(code: String, fromVC: UIViewController) {
            NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: LarkOpenEvent.scanQR(code, fromVC))
        }
        
        func _scanQR() {
            guard let vcFollowDelegateType = vcFollowDelegateType else {
                openScanQRService(code: code, fromVC: fromVC)
                DocsLogger.info("ScanQRManager openScanQR normal")
                return
            }
            switch vcFollowDelegateType {
            case .browser(let delegate):
                guard let delegate = delegate else {
                    openScanQRService(code: code, fromVC: fromVC)
                    DocsLogger.info("ScanQRManager openScanQR normal because browser vcFollow is nil")
                    return
                }
                delegate.follow(onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { _fromVC in
                    if let fromVC = _fromVC {
                        DocsLogger.info("ScanQRManager openScanQR by browser vcFollow")
                        openScanQRService(code: code, fromVC: fromVC)
                    } else {
                        DocsLogger.error("ScanQRManager openScanQR by browser vcFollow fail")
                    }
                })))
                
            case .space(let delegate):
                guard let delegate = delegate else {
                    openScanQRService(code: code, fromVC: fromVC)
                    DocsLogger.info("ScanQRManager openScanQR normal because space vcFollow is nil")
                    return
                }
                delegate.follow(nil, onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { _fromVC in
                    if let fromVC = _fromVC {
                        DocsLogger.error("ScanQRManager openScanQR by space vcFollow")
                        openScanQRService(code: code, fromVC: fromVC)
                    } else {
                        DocsLogger.error("ScanQRManager openScanQR by space vcFollow fail")
                    }
                })))
            }
        }
        DispatchQueue.main.async {
            _scanQR()
        }
    }
}
