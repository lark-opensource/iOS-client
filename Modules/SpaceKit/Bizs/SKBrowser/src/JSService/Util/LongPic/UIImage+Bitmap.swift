//
//  UIImage+Bitmap.swift
//  TestLongPic
//
//  Created by 吴珂 on 2020/8/21.
//  Copyright © 2020 bytedance. All rights reserved.


import Foundation
import CoreImage
import MobileCoreServices
import SKUIKit

public struct WKImageHelper<Base> {
    var base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol WKImageHelperWrapper {
    associatedtype WrappedType
    var wk: WrappedType { get }
}

extension WKImageHelperWrapper {
    public var wk: WKImageHelper<Self> {
        WKImageHelper(self)
    }
}

extension UIImage: WKImageHelperWrapper {
    
}

typealias DecorateBlock = (_ context: CGContext, _ in: CGSize) -> Void

extension WKImageHelper where Base == UIImage {
     
     func scaleAndGetPixels(_ scale: Int = 2, decorateBlock: DecorateBlock? = nil, shouldDoDecorate: ((UnsafeMutablePointer<UInt8>) -> Bool)) -> UnsafeMutablePointer<UInt8>? {
         var scaleSize = self.base.size
         let useScale = min(SKDisplay.scale, CGFloat(scale))
         scaleSize.height = self.base.size.height * useScale
         scaleSize.width = self.base.size.width * useScale
         let dataSize = scaleSize.width * scaleSize.height * 4
         let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(dataSize))
         _ = autoreleasepool {
             Date.measure(prefix: "jacky scale image") {
                 let colorSpace = CGColorSpaceCreateDeviceRGB()
                 let context = CGContext(data: pixelData,
                                    width: Int(scaleSize.width),
                                    height: Int(scaleSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(scaleSize.width),
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                guard let cgImage = self.base.cgImage else { return }
                context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaleSize.width, height: scaleSize.height))
                
                if shouldDoDecorate(pixelData), let decorateBlock = decorateBlock, let context = context {
                    decorateBlock(context, scaleSize)
                }
                 
             }
         }
         return pixelData
     }
    
//    func scaleAndGetPixels(_ scale: CGFloat = 2) -> (UnsafeMutablePointer<UInt8>?, CGSize) {
//        var scaleSize = self.base.size
//        let useScale = min(UIScreen.main.scale, CGFloat(scale))
//        scaleSize.height = floor(self.base.size.height * useScale)
//        scaleSize.width = floor(self.base.size.width * useScale)
//        let dataSize = scaleSize.width * scaleSize.height * 4
//        let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(dataSize))
//        _ = autoreleasepool {
//            Date.measure(prefix: "scale image") {
//                let colorSpace = CGColorSpaceCreateDeviceRGB()
//                let context = CGContext(data: pixelData,
//                                   width: Int(scaleSize.width),
//                                   height: Int(scaleSize.height),
//                                   bitsPerComponent: 8,
//                                   bytesPerRow: 4 * Int(scaleSize.width),
//                                   space: colorSpace,
//                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//               guard let cgImage = self.base.cgImage else { return }
//               context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaleSize.width, height: scaleSize.height))
//            }
//        }
//       return (pixelData, scaleSize)
//    }
     
     func pixelData() -> UnsafeMutablePointer<UInt8>? {
        let size = self.base.size
         let dataSize = size.width * size.height * 4
         let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(dataSize))
         _ = autoreleasepool { //降低600m
             Date.measure(prefix: "export pixel data") {
                 let colorSpace = CGColorSpaceCreateDeviceRGB()
                 let context = CGContext(data: pixelData,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                 guard let cgImage = self.base.cgImage else { return }
                 context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
             }
         }
         
         return pixelData
    }
}
