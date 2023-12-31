//
//  GIFDataSource.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/12/10.
//

import Foundation

enum GIFParseError: Error {
    case invalidFilename
    case noImages
    case noProperties
    case noGifDictionary
    case noTimingInfo
}

extension GIFParseError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidFilename:
            return "Invalid file name"
        case .noImages, .noProperties, .noGifDictionary, .noTimingInfo:
            return "Invalid gif file "
        }
    }
}


protocol GIFDataSource {
    var needDownsample: Bool { get set }
    var renderFrame: ((Result<UIImage, Error>) -> Void)? { get set }
    func start()
    func stop()
}
