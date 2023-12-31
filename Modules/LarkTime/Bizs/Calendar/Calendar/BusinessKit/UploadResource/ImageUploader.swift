//
//  ImageUploader.swift
//  Calendar
//
//  Created by Rico on 2021/7/20.
//

import Foundation
import RxSwift
import LarkContainer

public final class ImageUploader: UserResolverWrapper {

    public var userResolver: UserResolver

    @ScopedInjectedLazy var api: CalendarRustAPI?

    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func uploadImage(data imageData: Data) -> Observable<String> {
        return api?.uploadImage(with: imageData) ?? .empty()
    }
}
