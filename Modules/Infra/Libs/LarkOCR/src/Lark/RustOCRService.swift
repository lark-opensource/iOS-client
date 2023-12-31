//
//  RustOCRService.swift
//  LarkOCR
//
//  Created by 李晨 on 2022/9/4.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import RxSwift
import LarkRustClient
import LarkContainer
import LKCommonsLogging
import SwiftProtobuf
import LarkStorage

public final class RustOCRService: ImageOCRService, UserResolverWrapper {

    public static let MessageIDKey = "ocr.message.id"
    public static let DownloadSceneKey = "ocr.download.scene"

    @ScopedProvider var client: RustService?

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    public func recognition(source: ImageOCRSource, extra: [String: Any]) -> Observable<ImageOCRResult> {
        switch source {
        case .image(let uIImage):
            return recognition(image: uIImage, extra: extra)
        case .key(let imageKey):
            return recognition(imageKey: imageKey, extra: extra)
        }
    }

    func recognition(imageKey: String, extra: [String: Any]) -> Observable<ImageOCRResult> {
        var request = Media_V1_UploadImageOCRRequest()
        request.fileKey = imageKey
        if let messageID = extra[RustOCRService.MessageIDKey] as? String {
            request.messageID = messageID
        }
        if let scene = extra[RustOCRService.DownloadSceneKey] as? Media_V1_DownloadFileScene {
            request.scene = scene
        } else {
            request.scene = .chat
        }
        return client?.async(message: request).map { (result: Media_V1_UploadImageOCRResponse) -> ImageOCRResult in
            return Self.transformToOCRResult(data: result.data)
        } ?? .empty()
    }

    func recognition(image: UIImage, extra: [String: Any]) -> Observable<ImageOCRResult> {
        var request = Media_V1_UploadImageOCRRequest()
        request.path = self.saveImageToTmpPath(image: image)
        return client?.async(message: request).map { (result: Media_V1_UploadImageOCRResponse) -> ImageOCRResult in
            return Self.transformToOCRResult(data: result.data)
        } ?? .empty()
    }

    static func transformToOCRResult(data: Data) -> ImageOCRResult {
        var options = BinaryDecodingOptions()
        options.discardUnknownFields = true
        guard let response = try? ServerPB_Pan_ImageOCRResponse(serializedData: data, options: options),
              !response.lines.isEmpty else {
            return ImageOCRResult(imageSize: .zero, lines: [], regions: [], entities: [])
        }
        let imageSize = CGSize(width: CGFloat(response.width), height: CGFloat(response.height))
        var lineIndex = 0
        var lines = response.lines.map { line -> ImageOCRResult.Line in
            let rect = line.rect
            let points = rect.points
            let rectModel = ImageOCRResult.Rect(
                topLeft: CGPoint(x: CGFloat(points[0].x), y: CGFloat(points[0].y)),
                bottomLeft: CGPoint(x: CGFloat(points[3].x), y: CGFloat(points[3].y)),
                bottomRight: CGPoint(x: CGFloat(points[2].x), y: CGFloat(points[2].y)),
                topRight: CGPoint(x: CGFloat(points[1].x), y: CGFloat(points[1].y))
            )
            let index = lineIndex
            lineIndex += 1
            return ImageOCRResult.Line(index: index, rect: rectModel, string: line.text, regionIndex: 0, entities: [])
        }

        var regions = response.regions.enumerated().map { i, region -> ImageOCRResult.Region in
            let regionLines = region.lineIds.map { index -> ImageOCRResult.Line in
                var line = lines[Int(index)]
                line.regionIndex = i
                lines[Int(index)] = line
                return line
            }
            return ImageOCRResult.Region(string: region.text, lines: regionLines, entities: [])
        }

        let entities: [ImageOCRResult.Entity] = response.typeToEntities.flatMap { key, values -> [ImageOCRResult.Entity] in
            var entities: [ImageOCRResult.Entity] = []
            var type: ImageOCRResult.Entity.EntityType = .unknown
            if key == ServerPB_Pan_ImageOCRResponse.EntityType.phone.rawValue {
                type = .phone
            } else if key == ServerPB_Pan_ImageOCRResponse.EntityType.url.rawValue {
                type = .url
            }
            values.list.forEach { value in
                var entityLines: [(Int, ImageOCRResult.Entity.Range)] = []
                value.lineMsgs.forEach { lineMsg in
                    entityLines.append((
                        Int(lineMsg.lineID),
                        .init(start: Int(lineMsg.lineRange.start), end: Int(lineMsg.lineRange.end))
                    ))
                }
                let entity = ImageOCRResult.Entity(
                    type: type,
                    string: value.text,
                    lines: entityLines,
                    regionIndex: Int(value.regionID),
                    regionRange: .init(
                        start: Int(value.regionRange.start),
                        end: Int(value.regionRange.end)
                    ),
                    extra: value.entityExt
                )

                // add entity to line
                entity.lines.forEach { index, _ in
                    var line = lines[index]
                    line.entities.append(entity)
                    lines[index] = line
                }
                // add entity to region
                var region = regions[entity.regionIndex]
                region.entities.append(entity)
                regions[entity.regionIndex] = region

                entities.append(entity)
            }
            return entities
        }

        return ImageOCRResult(
            imageSize: imageSize,
            lines: lines,
            regions: regions,
            entities: entities
        )
    }

    // swiftlint:disable shorthand_operator
    private func saveImageToTmpPath(image: UIImage) -> String {
        var tempDir = IsoPath.in(space: .global, domain: Domain.biz.messenger).build(.temporary)
        tempDir = tempDir + "OCRImage"
        try? tempDir.createDirectoryIfNeeded()
        var filePath = tempDir
        if let data = image.jpegData(compressionQuality: 0.9) {
            filePath = tempDir + "\(UUID().uuidString).jpg"
            try? filePath.createFileIfNeeded(with: data)
        } else if let data = image.pngData() {
            filePath = tempDir + "\(UUID().uuidString).png"
            try? filePath.createFileIfNeeded(with: data)
        } else {
            assertionFailure()
        }
        return filePath.absoluteString
    }
    // swiftlint:enable shorthand_operator
}
