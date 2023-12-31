//
//  MessengerMockDependency+DriveSDK.swift
//  LarkMessenger
//
//  Created by bytedance on 2021/1/24.
//

import Foundation
import RxSwift
import Moment
import Swinject
import LarkContainer
#if CCMMod
import SpaceInterface
#endif

public final class LarkMomentDependencyImpl: LarkMomentDependency {
    private let resolver: UserResolver

    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func upload(localPath: String,
                fileName: String,
                mountNodePoint: String,
                mountPoint: String) -> Observable<MomentsUploadInfo>? {
        #if CCMMod
        return try? resolver.resolve(type: DocCommonUploadProtocol.self)
            .upload(localPath: localPath,
                               fileName: fileName,
                               mountNodePoint: mountNodePoint,
                               mountPoint: mountPoint,
                               copyInsteadMoveAfterSuccess: true,
                               priority: .default)
            .map { (uploadKey, progress, fileToken, status) -> MomentsUploadInfo in
                var uploadStatus: MomentsUploadStatus = .uploading
                if status == .cancel {
                    uploadStatus = .cancel
                } else if status == .failed {
                    uploadStatus = .failed
                } else if status == .success {
                    uploadStatus = .success
                }
                return MomentsUploadInfo(uploadKey: uploadKey, progress: progress, fileToken: fileToken, uploadStatus: uploadStatus)
            }
        #else
        nil
        #endif

    }
}
