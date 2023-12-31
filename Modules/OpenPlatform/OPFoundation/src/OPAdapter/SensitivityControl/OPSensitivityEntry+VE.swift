//
//  OPSensitivityEntry+VE.swift
//  OPFoundation
//
//  Created by zhangxudong.999 on 2023/5/19.
//

import Photos
import Contacts
import LarkSensitivityControl

public extension OPSensitivityEntry {
    
    /// UIImageWriteToSavedPhotosAlbum
    @objc static func UIImageWriteToSavedPhotosAlbum(forToken token: OPSensitivityEntryToken,
                                                     image: UIImage,
                                                     completionTarget: Any?,
                                                     completionSelector: Selector?,
                                                     contextInfo: UnsafeMutableRawPointer?) throws {
        if sensitivityControlEnable() {
            try LarkSensitivityControl.AlbumEntry.UIImageWriteToSavedPhotosAlbum(forToken: token.psdaToken, image, completionTarget, completionSelector, contextInfo)
        } else {
            UIKit.UIImageWriteToSavedPhotosAlbum(image, completionTarget, completionSelector, contextInfo)
        }
    }
    //BDPAuthorization checkAlbumPermission
    @objc static func photos_PHPhotoLibrary_requestAuthorization(forToken token: OPSensitivityEntryToken,
                                                                 handler: @escaping ((Int) -> Void)) throws {
        if sensitivityControlEnable() {
            try LarkSensitivityControl.AlbumEntry.requestAuthorization(forToken: token.psdaToken) { status in
                handler(status.rawValue)
            }
        } else {
            PHPhotoLibrary.requestAuthorization({ status in
                handler(status.rawValue)
            })
        }
    }
    
    //OpenPluginChooseMedia.handleAVAsset()
    static func photos_PHImageManager_requestAVAsset(forToken token: OPSensitivityEntryToken,
                                                     manager: PHImageManager,
                                                     forVideoAsset asset: PHAsset,
                                                     options: PHVideoRequestOptions?,
                                                     resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable: Any]?) -> Void) throws {
        if sensitivityControlEnable() {
            try LarkSensitivityControl.AlbumEntry.requestAVAsset(
                forToken: token.psdaToken,
                manager: manager,
                forVideoAsset: asset,
                options: options,
                resultHandler: resultHandler)
        } else {
            manager.requestAVAsset(forVideo: asset, options: options, resultHandler:resultHandler)
        }
    }
    /// BDPAuthorization checkMicrophonePermission
    @objc static func AVAudioSession_requestRecordPermission(forToken token: OPSensitivityEntryToken,
                                                             session: AVAudioSession,
                                                             response: @escaping (Bool) -> Void) throws {
        if sensitivityControlEnable() {
            try AudioRecordEntry.requestRecordPermission(forToken: token.psdaToken,
                                                         session: session,
                                                         response: response)
        } else {
            session.requestRecordPermission(response)
        }
    }
    /// BDPAuthorization checkCameraPermission
    @objc static func AVCaptureDevice_requestAccessVideo(forToken token: OPSensitivityEntryToken,
                                                         completionHandler handler: @escaping (Bool) -> Void) throws {
        if sensitivityControlEnable() {
            try CameraEntry.requestAccessCamera(forToken: token.psdaToken,
                                                completionHandler: handler)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: handler)
        }
    }
    /*
     ContactsEntry.requestAccess(forToken token: Token,
     contactsStore: CNContactStore,
     forEntityType entityType: CNEntityType,
     completionHandler: @escaping (Bool, Error?) -> Void) throws
     */
    static func ContactsEntry_requestAccess(forToken token: OPSensitivityEntryToken,
                                            contactsStore: CNContactStore,
                                            forEntityType entityType: CNEntityType,
                                            completionHandler: @escaping (Bool, Error?) -> Void) throws {
        if sensitivityControlEnable() {
            try LarkSensitivityControl.ContactsEntry.requestAccess(forToken: token.psdaToken,
                                                                   contactsStore: contactsStore,
                                                                   forEntityType: entityType,
                                                                   completionHandler: completionHandler)
        } else {
            contactsStore.requestAccess(for: entityType, completionHandler: completionHandler)
        }
    }
    
    static func PHImageManager_requestImageData(
        forToken token: OPSensitivityEntryToken,
        manager: PHImageManager,
        forAsset asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable: Any]?) -> Void) throws {
            if sensitivityControlEnable() {
                try AlbumEntry.requestImageData(forToken: token.psdaToken,
                                                manager: manager,
                                                forAsset: asset,
                                                options: options,
                                                resultHandler: resultHandler)
            } else {
                manager.requestImageData(for: asset, options: options, resultHandler: resultHandler)
            }
    }
    
   
}
