//
//  InMeetingLabViewModel+ImagePicker.swift
//  ByteView
//
//  Created by wangpeiran on 2021/4/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

private struct LabVMImagePicker {
    static let maxImageSize = 15
    static let maxCompressSize = 2
}

extension InMeetingLabViewModel {
    func showImagePicker() {
        guard let from = self.router.topMost else {
            return
        }
        let send = I18n.View_G_Done
        service.larkRouter.showImagePicker(from: from, sendButtonTitle: send, takePhotoEnable: false) { [weak self] (picker, image) in
            guard self != nil, let asset = image else {
                picker.dismiss(animated: true, completion: nil)
                return
            }
            Logger.effectBackGround.info("lab bg: Photo --isGIF-\(asset.isGIF)---pixelSize-\(asset.pixelSize)---fileSize-\(asset.fileSize)---filename-\(asset.fileName)")

            if asset.fileSize > (LabVMImagePicker.maxImageSize * 1024 * 1024) {
                Toast.show(I18n.View_VM_UnableToAddLargeFiles(LabVMImagePicker.maxImageSize))
                LabTrack.trackShowPopupView("background_limit_size_vc")
                picker.dismiss(animated: true, completion: nil)
                return
            }

            DispatchQueue.global().async {
                var compressRatio: CGFloat = 1
                if var imageData = asset.originalImage()?.jpegData(compressionQuality: compressRatio) {
                    Logger.effectBackGround.info("lab bg: Photo orginSize \(imageData.count)")
                    if imageData.count > (LabVMImagePicker.maxCompressSize * 1024 * 1024) {
                        compressRatio = CGFloat(LabVMImagePicker.maxCompressSize * 1024 * 1024) / CGFloat(imageData.count)
                        if let compressData = asset.originalImage()?.jpegData(compressionQuality: compressRatio) {
                            imageData = compressData
                        }
                    }
                    Logger.effectBackGround.info("lab bg: Photo compressSize\(imageData.count) compressRatio: \(compressRatio)")
                    self?.virtualBgService.uploadVirtualBg(name: asset.fileName ?? "lab-\(NSDate().timeIntervalSince1970)", data: imageData)
                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
}
