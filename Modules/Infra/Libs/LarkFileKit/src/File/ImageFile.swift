//
//  ImageFile.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/21.
//

import UIKit
import Foundation

extension UIImage: ReadableWritable {
    /// Returns an image from the given path.
    ///
    /// - Parameter path: The path to be returned the image for.
    /// - Throws: FileKitError.ReadFromFileFail
    ///
    public class func read(from path: Path) throws -> Self {
        try FileTracker.track(path, operation: .fileRead) {
            guard let contents = self.init(contentsOfFile: path.safeRawValue) else {
                throw FileKitError.readFromFileFail(path: path,
                                                    error: FileKitError.ReasonError.conversion(UIImage.self))
            }
            return contents
        }
    }

    public func write(to path: Path, atomically useAuxiliaryFile: Bool) throws {
        try FileTracker.track(path, operation: .fileWrite) {
            try (self.pngData() ?? Data()).write(to: path, atomically: useAuxiliaryFile)
        }
    }
}
