//
//  MessengerDependency+SearchCore.swift
//  MessengerMod
//
//  Created by Patrick on 2022/1/25.
//

import Foundation
import RxSwift
import Swinject
import LarkMessengerInterface
import LarkSearchCore
import LarkContainer
#if CCMMod
import SpaceInterface
import CCMMod
import ByteWebImage
#endif

final class SearchCoreDependencyImpl: SearchCoreDependency {
    private let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    func getImage(withToken token: String) -> Observable<SearchCoreImageResult> {
        #if CCMMod

        let downloadCacheService = try? resolver.resolve(type: SpaceDownloadCacheProtocol.self)
        if let data = downloadCacheService?.data(key: token, type: .image) {
            let picSize = data.count
            guard let resultImage = try? ByteImage(data) else {
                return .just(.failed(.noImage, token))
            }
            return .just(.success(resultImage, token))
        }
        let downloader = try? resolver.resolve(assert: DocCommonDownloadProtocol.self)
        let context = DocCommonDownloadRequestContext(fileToken: token,
                                                      mountNodePoint: "",
                                                      mountPoint: "asl_image",
                                                      priority: .default,
                                                      downloadType: .image,
                                                      localPath: nil,
                                                      isManualOffline: false)
        guard let downloader else { return .empty() }
        return downloader.download(with: context)
            .flatMap { context -> Observable<SearchCoreImageResult> in
                var picSize: Int = -1
                let status = context.downloadStatus
                if status == .success || status == .failed {
                    if status == .success, let data = downloadCacheService?.data(key: token, type: .image) {
                        picSize = data.count
                        guard let resultImage = try? ByteImage(data) else {
                            return .just(.failed(.noImage, token))
                        }
                        return .just(.success(resultImage, token))
                    } else {
                        return .just(.failed(.downloadFailed, token))
                    }
                }
                return .empty()
            }
        #endif
        return .empty()
    }
}
