//
//  WikiImageAssets.swift
//  LarkAssetsBrowser
//
//  Created by Hayden Wang on 2022/2/10.
//

import Foundation
import UIKit
import ByteWebImage
import LarkAssetsBrowser
import RxSwift
import LarkContainer

public final class WikiWebImageAsset: LKAsset {

    public var url: String

    public var resourceType: LKAssetType { .sync }

    public var associatedPageType: LKGalleryPage.Type { LKAssetBaseImagePage.self }

    public init(url: String) {
        self.url = url
    }

    public func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetBaseImagePage else { return }
        let prevImage = page.imageView.image
        page.assetIdentifier = url
        page.showLoading()
        page.imageView.bt.setImage(with: URL(string: url), completionHandler: { [weak self, weak page] _ in
            page?.hideLoading()
            if page?.assetIdentifier != self?.url {
                page?.imageView.image = prevImage
            }
        })
    }
}

public final class WikiAvatarImageAsset: LKAsset {

    public var key: String?
    public var entityId: String?

    public var resourceType: LKAssetType { .sync }

    public var associatedPageType: LKGalleryPage.Type { LKAssetBaseImagePage.self }

    public init(key: String?, entityId: String?) {
        self.key = key
        self.entityId = entityId
    }

    public func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetBaseImagePage else { return }
        let prevImage = page.imageView.image
        page.showLoading()
        page.assetIdentifier = key
        page.imageView.bt.setLarkImage(with: .avatar(key: key ?? "", entityID: entityId ?? ""), completion: { [weak self, weak page] _ in
            page?.hideLoading()
            if page?.assetIdentifier != self?.key {
                page?.imageView.image = prevImage
            }
        })
//        page.imageView.bt.setLarkImage(with: .avatar(key: key ?? "", entityID: entityId ?? ""))
    }
}

public final class WikiDriveImageAsset: LKAsset, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy private var dependency: SearchCoreDependency?

    private let disposeBag = DisposeBag()

    public var token: String

    public var resourceType: LKAssetType { .sync }

    public var associatedPageType: LKGalleryPage.Type { LKAssetBaseImagePage.self }

    public init(resolver: LarkContainer.UserResolver, token: String) {
        self.userResolver = resolver
        self.token = token
    }

    public func displayAsset(on assetPage: LKGalleryPage) {
        guard let page = assetPage as? LKAssetBaseImagePage else { return }
        // fetch drive image and set to imageView.
        page.showLoading()
        page.assetIdentifier = token
        dependency?.getImage(withToken: token)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak page] result in
                page?.hideLoading()
                guard page?.assetIdentifier == self?.token else { return }
                switch result {
                case .success(let image, _):
                    page?.imageView.image = image
                case .failed(let error, _):
                    // load image failed.
                    break
                }
            })
            .disposed(by: disposeBag)
    }
}
