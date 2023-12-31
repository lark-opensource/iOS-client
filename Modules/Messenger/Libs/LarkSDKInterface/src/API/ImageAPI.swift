//
//  ImageAPI.swift
//  LarkSDKInterface
//
//  Created by liuwanlin on 2018/6/5.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RustPB

public typealias ImageType = RustPB.Media_V1_UploadImageV2Request.ImageType

public typealias ImageAPIProvider = () -> ImageAPI

public protocol ImageAPI {

    func uploadImage(data: Data, imageCompressedSizeKb: Int64) -> Observable<ImageSet>

    func uploadImageV2(data: Data, imageType: ImageType) -> Observable<String>

    func uploadSecureImage(data: Data, type: RustPB.Media_V1_UploadSecureImageRequest.TypeEnum, imageCompressedSizeKb: Int64) -> Observable<String>

    func uploadSecureImage(data: Data, type: RustPB.Media_V1_UploadSecureImageRequest.TypeEnum, imageCompressedSizeKb: Int64, encrypt: Bool) -> Observable<String>

    func getImageCompressParameters(size: Int64, shortSide: Int32, longSide: Int32, quality: Int32?) throws -> CompressParameters

    func imageStyleDetectRequest(image: Data) -> Observable<RustPB.Media_V1_ImageStyleDetectResponse>
}
