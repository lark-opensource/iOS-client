//
//  DocThumbnailImageViewAligned.swift
//  LarkMessageCore
//
//  Created by Weston Wu on 2020/7/2.
//

import Foundation
import UIKit
import UIImageViewAlignedSwift
import RxSwift

public final class DocThumbnailImageViewAligned: UIImageViewAligned {
    private let reuseBag = DisposeBag()
    private var ongoingResourceID: String?

    func needUpdate(with resourceID: String) -> Bool {
        ongoingResourceID != resourceID
    }

    func update(resourceID: String,
                thumbnailSource: Observable<UIImage>,
                completion: ((Result<UIImage, Error>) -> Void)? = nil) {
        guard needUpdate(with: resourceID) else { return }
        ongoingResourceID = resourceID
        thumbnailSource.subscribe(onNext: { [weak self] image in
            let task: () -> Void = {
                guard let self = self else { return }
                guard resourceID == self.ongoingResourceID else {
                    return
                }
                self.image = image
                completion?(.success(image))
            }
            if Thread.current.isMainThread {
                task()
            } else {
                DispatchQueue.main.async(execute: task)
            }
        }, onError: { [weak self] error in
            let task: () -> Void = {
                guard let self = self else { return }
                guard resourceID == self.ongoingResourceID else {
                    return
                }
                self.ongoingResourceID = nil
                completion?(.failure(error))
            }
            if Thread.current.isMainThread {
                task()
            } else {
                DispatchQueue.main.async(execute: task)
            }
        }, onCompleted: { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard resourceID == self.ongoingResourceID else {
                    return
                }
                self.ongoingResourceID = nil
            }
        })
        .disposed(by: reuseBag)
    }
}
