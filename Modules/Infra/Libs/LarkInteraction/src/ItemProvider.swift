//
//  ItemProvider.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import Foundation
import MobileCoreServices

public extension NSItemProvider {
    /// NSItemProvider  全名, 如果文件名为空则使用 UUID 作为默认文件名
    var fullSuggestedName: String {
        var suggestedName = self.suggestedName ?? ""

        /// 如果文件名带后缀，直接返回
        if suggestedName.split(separator: ".").count > 1 {
            return suggestedName
        }

        if suggestedName.isEmpty {
            suggestedName = UUID().uuidString
        }
        var fileExtension: String?
        for uti in self.registeredTypeIdentifiers {
            if let extensionPath = UTTypeCopyPreferredTagWithClass(
                uti as CFString,
                kUTTagClassFilenameExtension
                )?.takeRetainedValue() {
                    fileExtension = extensionPath as String
                    break
            }
        }

        if let fileExtension = fileExtension, !fileExtension.isEmpty {
            return suggestedName + "." + fileExtension
        }
        return suggestedName
    }
}

public final class ItemProviderWriting: NSObject, NSItemProviderWriting {
    public static var writableTypeIdentifiersForItemProvider: [String] = [UTI.Data]

    public var writableTypeIdentifiersForItemProvider: [String]

    public var  visibilityForRepresentation: NSItemProviderRepresentationVisibility

    public var downloadBlock: (String, @escaping (Data?, Error?) -> Void) -> Progress?

    public init(
        supportUTI: [String],
        visibilityForRepresentation: NSItemProviderRepresentationVisibility = .all,
        downloadBlock: @escaping (String, @escaping (Data?, Error?) -> Void) -> Progress?
    ) {
        self.writableTypeIdentifiersForItemProvider = supportUTI
        self.visibilityForRepresentation = visibilityForRepresentation
        self.downloadBlock = downloadBlock
    }

    public static func itemProviderVisibilityForRepresentation(
        withTypeIdentifier typeIdentifier: String
    ) -> NSItemProviderRepresentationVisibility {
        return .all
    }

    public func itemProviderVisibilityForRepresentation(
        withTypeIdentifier typeIdentifier: String
    ) -> NSItemProviderRepresentationVisibility {
        return self.visibilityForRepresentation
    }

    public func loadData(
        withTypeIdentifier typeIdentifier: String,
        forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void
    ) -> Progress? {
        return self.downloadBlock(typeIdentifier, completionHandler)
    }
}
