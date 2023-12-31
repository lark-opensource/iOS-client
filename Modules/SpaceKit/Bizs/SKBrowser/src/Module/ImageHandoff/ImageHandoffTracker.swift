//
//  ImageHandoffTracker.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/8/9.
//  

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

class ImageHandoffTracker {
    static let event = DocsTracker.EventType.imageHandoff

    enum Action: String {
        case openPanel = "open_image_Panel"
        case selectImage = "select_image"
        case takePhoto = "take_a_photo"
    }

    class func openPanel(fileId: String) {
        var params: [String: Any] = [:]
        params["action"] = Action.openPanel.rawValue
        params["file_type"] = DocsType.doc.name
        params["file_id"] = DocsTracker.encrypt(id: fileId)
        DocsTracker.log(enumEvent: ImageHandoffTracker.event, parameters: params)
    }

    class func uploaded(fileId: String, count: Int, size: Int, success: Bool, selectImage: Bool) {
        var params: [String: Any] = [:]
        params["action"] = selectImage ? Action.selectImage.rawValue : Action.takePhoto.rawValue
        params["file_id"] = DocsTracker.encrypt(id: fileId)
        params["file_type"] = DocsType.doc.name
        params["upload_status"] = success
        params["upload_quantity"] = count
        params["upload_image_size"] = size
        DocsTracker.log(enumEvent: ImageHandoffTracker.event, parameters: params)
    }
}
