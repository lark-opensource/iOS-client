//
//  MomentsImageChecker.swift
//  Moment
//
//  Created by bytedance on 2021/11/16.
//

import Foundation
import UIKit
import ByteWebImage
import LarkSDKInterface
import LarkContainer
import LarkSetting

struct MomentsImageCompressConfig {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "moments_upload_image_compress")
    let targetLength: Int
    let targetQuality: Float
    init(settingService: SettingService?, defaultLength: Int, defaultQuality: Double) {
        var target_length: Int?
        var target_quality: Double?
        if let settings = try? settingService?.setting(with: Self.settingKey) as? [String: Any] {
            target_length = settings["target_length"] as? Int
            target_quality = settings["target_quality"] as? Double
        }
        self.targetLength = target_length ?? defaultLength
        self.targetQuality = Float(target_quality ?? defaultQuality)
    }
}

struct MomentsImageCheckResult {

    enum ErrorType {
        case size(Int64)
        case resolution(CGSize)
        case sizeAndResolution(Int64, CGSize)
    }

    let isPass: Bool
    let errorType: ErrorType?
    let item: SelectImageInfoItem
}

final class MomentsImageChecker {

    /// 检查是否符合规范
    func checkImageItems(_ items: [SelectImageInfoItem]) -> [MomentsImageCheckResult] {
        return items.map { item -> MomentsImageCheckResult in
            guard let imageSource = item.imageSource,
                    let data = imageSource.data,
                    item.originSize != .zero else {
                /// 无法判断 都按通过处理
                return MomentsImageCheckResult(isPass: true, errorType: nil, item: item)
            }
            let finalImageType = imageSource.sourceType
            let fileSizeResult = ImageUploadChecker.getFileSizeCheckResult(sourceImageType: finalImageType, finalImageType: finalImageType, fileSize: Int64(data.count))
            let imageSizeResult = ImageUploadChecker.getImageSizeCheckResult(sourceImageType: finalImageType, finalImageType: finalImageType, imageSize: item.originSize)
            if case .failure(let fileSizeError) = fileSizeResult, case .failure(let imageSizeError) = imageSizeResult,
                case .imageFileSizeExceeded(let limitFileSize) = fileSizeError, case .imagePixelsExceeded(let limitImageSize) = imageSizeError {
                return MomentsImageCheckResult(isPass: false, errorType: .sizeAndResolution(Int64(limitFileSize), limitImageSize), item: item)
            } else if case .failure(let fileSizeError) = fileSizeResult, case .imageFileSizeExceeded(let limitFileSize) = fileSizeError {
                return MomentsImageCheckResult(isPass: false, errorType: .size(Int64(limitFileSize)), item: item)
            } else if case .failure(let imageSizeError) = imageSizeResult, case .imagePixelsExceeded(let limitImageSize) = imageSizeError {
                return MomentsImageCheckResult(isPass: false, errorType: .resolution(limitImageSize), item: item)
            } else {
                return MomentsImageCheckResult(isPass: true, errorType: nil, item: item)
            }
        }
    }

    func transformResultsToTipString(_ results: [MomentsImageCheckResult]) -> String? {
        let failItems = results.filter { $0.isPass == false }
        var minSize: Int64?
        var minResolution: CGSize?
        if failItems.isEmpty {
            return nil
        }
        failItems.forEach { result in
            guard let errorType = result.errorType else {
                return
            }
            switch errorType {
            case .size(let size):
                if let lastSize = minSize {
                    minSize = min(lastSize, size)
                } else {
                    minSize = size
                }
            case .resolution(let resolution):
                if let lastResolution = minResolution {
                    minResolution = resolution.width * resolution.height > lastResolution.width * lastResolution.height ? lastResolution : resolution
                } else {
                    minResolution = resolution
                }
            case .sizeAndResolution(let size, let resolution):
                if let lastSize = minSize {
                    minSize = min(lastSize, size)
                } else {
                    minSize = size
                }
                if let lastResolution = minResolution {
                    minResolution = resolution.width * resolution.height > lastResolution.width * lastResolution.height ? lastResolution : resolution
                } else {
                    minResolution = resolution
                }
            }
        }
        /// 返回提示
        let countTips = BundleI18n.Moment.Moments_UploadImage_NumPhotosSizeOrResolutionOverNum_Toast1(failItems.count)
        if let minSize = minSize, let minResolution = minResolution {
            return countTips + BundleI18n.Moment.Moments_UploadImage_NumPhotosSizeOrResolutionOverNum_Toast2(describeSize(minSize), describeResolution(minResolution))
        } else if let minSize = minSize {
            return countTips + BundleI18n.Moment.Moments_UploadImage_NumPhotosSizeOverNum_Toast3(describeSize(minSize))
        } else if let minResolution = minResolution {
            return countTips + BundleI18n.Moment.Moments_UploadImage_NumPhotosResolutionOverNum_Toast4(describeResolution(minResolution))
        } else {
            return nil
        }
    }

    /// 只是去掉小数
    private func describeResolution(_ resolution: CGSize) -> String {
        return "\(Int(resolution.width))*\(Int(resolution.height))"
    }

    /// 直接转为整数
    private func describeSize(_ size: Int64) -> String {
        return "\(size / 1024 / 1024)"
    }
}
