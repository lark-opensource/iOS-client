//
//  Data+File.swift
//  LarkFileKit
//
//  Created by Supeng on 2020/9/21.
//

import Foundation

extension Data: ReadableWritable {
    /// Returns data read from the given path.
    public static func read(from path: Path) throws -> Data {
        try read(from: path, options: [])
    }

    /// Returns data read from the given path using Data.ReadingOptions.
    public static func read(from path: Path, options: Data.ReadingOptions) throws -> Data {
        try FileTracker.track(path, operation: .fileRead) {
            let result: Data
            do {
                result = try self.init(contentsOf: path.url, options: options)
            } catch {
                throw FileKitError.readFromFileFail(path: path, error: error)
            }
            return result
        }
    }

    /// Writes `self` to a path.
    ///
    /// - Parameter path: The path being written to.
    /// - Parameter useAuxiliaryFile: If `true`, the data is written to an
    ///                               auxiliary file that is then renamed to the
    ///                               file. If `false`, the data is written to
    ///                               the file directly.
    ///
    public func write(to path: Path, atomically useAuxiliaryFile: Bool) throws {
        let options: Data.WritingOptions = useAuxiliaryFile ? [.atomic] : []
        try self.write(to: path, options: options)
    }

    /// Writes `self` to a path.
    ///
    /// - Parameter path: The path being written to.
    /// - Parameter options: writing options.
    ///
    public func write(to path: Path, options: Data.WritingOptions) throws {
        try FileTracker.track(path, operation: .fileWrite) {
            do {
                try self.write(to: path.url, options: options)
            } catch {
                throw FileKitError.writeToFileFail(path: path, error: error)
            }
        }
    }
}
