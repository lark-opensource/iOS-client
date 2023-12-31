//
//  AnnouncementService.swift
//  SKBrowser
//
//  Created by zoujie on 2021/4/1.
//  


import Foundation
import SKCommon

public final class AnnouncementService: BaseJSService {}

extension AnnouncementService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.announcementPublish,
                .announcementPublishAlert,
                .setTemplate,
                .templateHidden]
    }

    public func handle(params: [String: Any], serviceName: String) {
        
        guard let announcementVC = navigator?.currentBrowserVC as? AnnouncementViewController else { return }

        switch serviceName {
        case DocsJSService.announcementPublish.rawValue:
            guard let callback = params["callback"] as? String else {
                return
            }
            announcementVC.announcementPublish(callback: callback)
        case DocsJSService.announcementPublishAlert.rawValue:
            announcementVC.announcementPublishAlert()
        case DocsJSService.setTemplate.rawValue:
            announcementVC.setTemplateView(params: params)
        case DocsJSService.templateHidden.rawValue:
            guard let callback = params["callback"] as? String else {
                return
            }
            announcementVC.templateHiddenCallback = callback
        default:
            break
        }
    }
}
