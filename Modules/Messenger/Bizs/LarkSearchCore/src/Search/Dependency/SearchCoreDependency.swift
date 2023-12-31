//
//  SearchCoreDependency.swift
//  LarkSearchCore
//
//  Created by Patrick on 2022/1/25.
//

import Foundation
import RxSwift
import ByteWebImage

public enum SearchCoreImageResult {

    public enum ResultError: Error {
        case downloadFailed
        case noImage
    }

    case success(ByteImage, String)
    case failed(ResultError, String)
}

public protocol SearchCoreDependency {
    func getImage(withToken token: String) -> Observable<SearchCoreImageResult>
}
