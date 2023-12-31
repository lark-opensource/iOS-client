//
//  UIApplication+Capture.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/6/6.
//

import Foundation
import UIKit
import LarkExtensions

extension UIWindow {

    var directCaptureInfo: CaptureInfo {
        let domainKey = (self as? DomainProtocol)?.domainKey ?? [:]
        let name = String.tkName(self) + " \(self.windowIdentifier)"
        return CaptureInfo(name: name,
                           frame: convert(frame, to: nil),
                           visible: visible,
                           domainKey: domainKey)
    }

    func convertToCaptureInfo(in depthLimit: Int) -> CaptureInfo {
        var info = directCaptureInfo
        var cachedCaptureInfos: [UIView: UIViewController] = [:]
        if let rootVC = rootViewController {
            rootVC.collectCapureInfos(&cachedCaptureInfos)
        }
        info.subInfos = captureInfo(with: cachedCaptureInfos, depthLimit: depthLimit)
        return info
    }

}

extension UIViewController {

    func collectCapureInfos(_ cachedCaptureInfos: inout [UIView: UIViewController]) {
        cachedCaptureInfos[view] = self
        children.forEach({ $0.collectCapureInfos(&cachedCaptureInfos) })
    }

}

extension UIView {

    func captureInfo(with cachedCaptureInfos: [UIView: UIViewController],
                     depthLimit: Int) -> [CaptureInfo] {
        guard depthLimit > 0 else { return [] }
        var infos: [CaptureInfo] = []
        for subview in subviews {
            let vc = cachedCaptureInfos[subview] as? CaptureProtocol
            let view = subview as? CaptureProtocol
            if let captured = vc ?? view {
                if captured.handle {
                    let domainKey = (captured as? DomainProtocol)?.domainKey ?? [:]
                    var info = CaptureInfo(name: String.tkName(captured), frame: subview.screenFrame,
                                           visible: subview.visible, domainKey: domainKey, subInfos: [])
                    if !captured.isLeaf {
                        info.subInfos = subview.captureInfo(with: cachedCaptureInfos, depthLimit: depthLimit - 1)
                    }
                    infos.append(info)
                } else {
                    if !captured.isLeaf {
                        let subInfos = subview.captureInfo(with: cachedCaptureInfos, depthLimit: depthLimit - 1)
                        infos.append(contentsOf: subInfos)
                    }
                }
            } else {
                let subInfos = subview.captureInfo(with: cachedCaptureInfos, depthLimit: depthLimit - 1)
                infos.append(contentsOf: subInfos)
            }
        }
        return infos
    }

}
