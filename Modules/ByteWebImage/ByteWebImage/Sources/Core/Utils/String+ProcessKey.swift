//
//  String+ProcessKey.swift
//  ByteWebImage
//
//  Created by Nickyo on 2022/9/7.
//

import Foundation

struct ImageProcessConfig {

    let downsample: CGSize

    let needCrop: Bool

    let crop: CGRect

    let transformID: String

    init(downsample: CGSize = .zero, needCrop: Bool = false, crop: CGRect = .zero, transformID: String = "") {
        self.downsample = downsample
        self.needCrop = needCrop
        self.crop = needCrop ? crop : .zero
        self.transformID = transformID
    }

    static var `default`: ImageProcessConfig {
        ImageProcessConfig()
    }
}

extension ImageProcessConfig: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(downsample)
        hasher.combine(needCrop)
        hasher.combine(crop)
        hasher.combine(transformID)
    }
}

extension CGPoint: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

extension CGSize: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
    }
}

extension CGRect: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin)
        hasher.combine(size)
    }
}

extension ImageWrapper where Base == String {

    private struct SuffixType: OptionSet {

        var rawValue: Int

        static let downsample = SuffixType(rawValue: 1 << 0)
        static let crop = SuffixType(rawValue: 1 << 1)
        static let transform = SuffixType(rawValue: 1 << 2)
        static let needCrop = SuffixType(rawValue: 1 << 3)
    }

    func processKey(config: ImageProcessConfig = .default) -> String {
        var string = ""
        var type: SuffixType = []
        if !config.transformID.isEmpty {
            string += "_\(config.transformID)"
            type.insert(.transform)
        }
        if config.needCrop {
            type.insert(.needCrop)
        }
        if config.crop != .zero {
            string += "_\(NSCoder.string(for: config.crop))"
            type.insert(.crop)
        }
        if config.downsample.width > 0, config.downsample.height > 0 {
            string += "_\(NSCoder.string(for: config.downsample))"
            type.insert(.downsample)
        }
        if string.isEmpty {
            return base
        }
        return "\(base)_bis\(string)_\(type.rawValue)_bie"
    }

    func parse() -> (String, ImageProcessConfig)? {
        guard base.hasSuffix("_bie") else {
            return nil
        }
        let list = base.split(separator: "_")
        var index = list.count - 2
        guard index >= 0, let typeValue = Int(list[index]) else {
            return nil
        }
        index -= 1
        let type = SuffixType(rawValue: typeValue)
        var downsample: CGSize = .zero
        var needCrop = false
        var crop: CGRect = .zero
        var transfromID: String = ""
        if index >= 0, type.contains(.downsample) {
            downsample = NSCoder.cgSize(for: String(list[index]))
            index -= 1
        }
        needCrop = type.contains(.needCrop)
        if index >= 0, type.contains(.crop) {
            crop = NSCoder.cgRect(for: String(list[index]))
            index -= 1
        }
        if index >= 0, type.contains(.transform) {
            transfromID = String(list[index])
            index -= 1
        }
        guard index > 0, list[index] == "bis" else {
            return nil
        }
        let url = String(base.prefix(upTo: list[index - 1].endIndex))
        return (url, ImageProcessConfig(downsample: downsample, needCrop: needCrop, crop: crop, transformID: transfromID))
    }
}
