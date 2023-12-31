//
//  CALayerExtensions.swift
//  ByteViewCommon
//
//  Created by FakeGourmet on 2023/11/17.
//

import Foundation

public extension VCExtension where BaseType == CALayer {
    func copy() -> CALayer? {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: base, requiringSecureCoding: false),
              let new_layer = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CALayer.self, from: data) else {
            return nil
        }
        return new_layer
    }

    func toImage(scale: CGFloat = 1, isOpaque: Bool? = nil, bounds: CGRect? = nil) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        // nolint-next-line: magic number
        format.scale = scale
        format.opaque = isOpaque ?? base.isOpaque
        let render = UIGraphicsImageRenderer(bounds: bounds ?? base.bounds, format: format)
        let image = render.image { context in
            base.render(in: context.cgContext)
        }
        return image
    }
}
