//
//  ImageResourceProgressHandler.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/11/25.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import RxSwift

class ImageResourceProgressHandler: BaseRustPushHandler<RustPB.Media_V1_PushResourceProgressResponse> {
    private var subject: PublishSubject<(String, Progress)> = PublishSubject<(String, Progress)>()
    public var observable: Observable<(String, Progress)> { subject.asObservable() }

    override func doProcessing(message: RustPB.Media_V1_PushResourceProgressResponse) {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = Int64(message.progress)
        subject.onNext((message.key, progress))
    }
}
