//
//  RustImageAPI.swift
//  Lark-Rust
//
//  Created by Sylar on 2017/12/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
import ByteWebImage

final class RustImageAPI: LarkAPI, ImageAPI {

    func uploadImage(data: Data, imageCompressedSizeKb: Int64) -> Observable<LarkModel.ImageSet> {
        var request = RustPB.Media_V1_UploadImageRequest()
        request.image = data
        request.compressedSizeKb = imageCompressedSizeKb
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Media_V1_UploadImageResponse) -> LarkModel.ImageSet in
                response.imageSet
            })
            .subscribeOn(scheduler)
    }

    func uploadImageV2(data: Data, imageType: ImageType) -> Observable<String> {
        var request = RustPB.Media_V1_UploadImageV2Request()
        request.image = data
        request.imageType = imageType
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Media_V1_UploadImageV2Response) -> String in
                response.imageKey
            })
            .subscribeOn(scheduler)
    }

    func imageStyleDetectRequest(image: Data) -> Observable<RustPB.Media_V1_ImageStyleDetectResponse> {
        var request = RustPB.Media_V1_ImageStyleDetectRequest()
        request.image = image
        return client.sendAsyncRequest(request)
    }

    func uploadSecureImage(data: Data, type: RustPB.Media_V1_UploadSecureImageRequest.TypeEnum, imageCompressedSizeKb: Int64) -> Observable<String> {
        return self.uploadSecureImage(data: data, type: type, imageCompressedSizeKb: imageCompressedSizeKb, encrypt: false)
    }

    func uploadSecureImage(data: Data, type: RustPB.Media_V1_UploadSecureImageRequest.TypeEnum, imageCompressedSizeKb: Int64, encrypt: Bool) -> Observable<String> {
        var request = RustPB.Media_V1_UploadSecureImageRequest()
        request.type = type
        request.image = data
        let size = data.bt.imageSize
        if size != .zero {
            request.width = Int32(size.width)
            request.height = Int32(size.height)
        }
        if imageCompressedSizeKb > 0 {
            request.compressedSizeKb = imageCompressedSizeKb
        }
        request.isSecretChatImage = encrypt
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Media_V1_UploadSecureImageResponse) -> String in
            return response.token
        })
        .subscribeOn(scheduler)
    }

    func getImageCompressParameters(size: Int64, shortSide: Int32, longSide: Int32, quality: Int32?) throws -> CompressParameters {
        var request = RustPB.Media_V1_GetImageCompressParametersRequest()
        request.imageSize = size
        request.shortSide = shortSide
        request.longSide = longSide
        if let quality = quality {
            request.quality = quality
        }
        return try self.client.sendSyncRequest(request)
    }
}
