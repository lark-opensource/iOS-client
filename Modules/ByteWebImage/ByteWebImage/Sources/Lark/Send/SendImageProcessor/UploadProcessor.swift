//
//  UploadProcessor.swift
//  ByteWebImage
//
//  Created by kangkang on 2022/8/23.
//

import RxSwift
import Foundation

/// 上传阶段
class LarkSendImageUploadProcess<U: LarkSendImageUploader>: LarkSendImageProcessor {
    let uploader: U

    init(uploader: U) {
        self.uploader = uploader
    }
    func imageProcess(sendImageState: SendImageState, request: LarkSendImageAbstractRequest) -> Observable<Void> {
        return self.uploader.imageUpload(request: request).flatMap { (result) -> Observable<Void> in
            request.setContext(key: SendImageRequestKey.UploadResult.ResultType, value: result)
            return .just(())
        }
    }
}
