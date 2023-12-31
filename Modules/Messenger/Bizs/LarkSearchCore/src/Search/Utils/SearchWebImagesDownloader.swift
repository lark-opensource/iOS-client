//
//  SearchWebImagesDownloader.swift
//  LarkSearchCore
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation
import UIKit
import ByteWebImage
import ThreadSafeDataStructure

public final class SearchWebImagesDownloader {
    private let imageKeys: [String]
    private var downloadResult: SafeArray<(String, UIImage?)> = [] + .readWriteLock

    public init(with imageKeys: [String]) {
        self.imageKeys = imageKeys
    }

    public func download(completion: @escaping ([(String, UIImage?)]) -> Void) {
        for imageKey in imageKeys {
            LarkImageService.shared.setImage(with: .default(key: imageKey), completion: {[weak self] imageResult in
                guard let self = self else { return }
                switch imageResult {
                case .success(let data):
                    self.downloadResult.append((imageKey, data.image))
                case .failure:
                    self.downloadResult.append((imageKey, nil))
                }
                if self.downloadResult.count == self.imageKeys.count {
                    completion(self.downloadResult.getImmutableCopy())
                }
            })
        }
    }
}
