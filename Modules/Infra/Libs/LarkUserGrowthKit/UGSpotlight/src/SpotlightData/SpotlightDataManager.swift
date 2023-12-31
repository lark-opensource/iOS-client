//
//  SpotlightDataManager.swift
//  UGSpotlight
//
//  Created by zhenning on 2021/3/25.
//

import UIKit
import Foundation
import LarkGuideUI
import LKCommonsLogging

public final class SpotlightDataManager {
    static let log = Logger.log(SpotlightReachPoint.self, category: "LarkUserGrowthKit.SpotlightDataManager")

    static func transformSpotlightPBToBubbleConfig(spotlightPB: UGSpotlightData?,
                                            targetSourceTypes: [TargetSourceType]) -> [BubbleItemConfig]? {
        guard let spotlightPB = spotlightPB else { return nil }
        let spotlightPBs = spotlightPB.spotlightMaterials.spotlights
        guard !spotlightPBs.isEmpty, !targetSourceTypes.isEmpty else {
            Self.log.error("transformSpotlightPBToBubbleConfig no spotlight / target views!",
                           additionalData: [
                            "spotlightPBs": "\(spotlightPBs)",
                            "targetSourceTypes": "\(targetSourceTypes)"
                           ])
            return nil
        }

        guard spotlightPBs.count == targetSourceTypes.count else {
            Self.log.error("transformSpotlightPBToBubbleConfig spotlight and target views count not match!",
                           additionalData: [
                            "spotlightPBs": "\(spotlightPBs)",
                            "targetSourceTypes": "\(targetSourceTypes)"
                           ])
            return nil
        }

        var bubbleItems: [BubbleItemConfig] = []
        spotlightPBs.enumerated().forEach { idx, pb in
            guard idx < targetSourceTypes.count else { return }
            let bubbleItem = createBubbleItemConfig(material: pb, targetSourceType: targetSourceTypes[idx])
            bubbleItems.append(bubbleItem)
        }
        return bubbleItems
    }

    // 创建气泡配置
    static func createBubbleItemConfig(material: SpotlightMaterial, targetSourceType: TargetSourceType) -> BubbleItemConfig {
        let content = material.content
        let targetAnchorCfg = material.targetAnchorConfig
        let offset: CGFloat? = targetAnchorCfg.hasOffset ? CGFloat(targetAnchorCfg.offset) : nil
        let arrowDirection: BubbleArrowDirection? = targetAnchorCfg.hasArrowDirection
            ? BubbleArrowDirection(rawValue: targetAnchorCfg.arrowDirection.rawValue) : nil
        let targetRectType: TargetRectType? = targetAnchorCfg.hasTargetRectType
            ? TargetRectType(rawValue: targetAnchorCfg.targetRectType.rawValue) : nil

        let textConfig = TextInfoConfig(title: content.title.content, detail: content.description_p.content)
        var bannerConfig: BannerInfoConfig?
        if content.hasImage, let data = content.image.data {
            switch data {
            case .rawImage(let rawImage):
                if let image = UIImage(data: rawImage.rawData) {
                    bannerConfig = BannerInfoConfig(imageType: .image(image))
                }
            case .cdnImage(let cdnImage):
                if let imageUrl = URL(string: cdnImage.url) {
                    // TODO: @lizijie.lizj
                    // 这里需要提前指定好 size , 为了气泡布局使用
                    // 期望引导组件可以提供给业务方一个异步加载图片的能力
                    bannerConfig = BannerInfoConfig(imageType: .gifImageURL((url: imageUrl, size: CGSize(width: 240, height: 150))))
                }
            @unknown default:
                break
            }

        }
        var bottomConfig: BottomConfig?
        let buttons = content.buttons
        if !buttons.isEmpty,
           let firstBtn = buttons.first {
            if buttons.count >= 2 {
                let secondBtn = buttons[1]
                // 左右按钮都有
                bottomConfig = BottomConfig(leftBtnInfo: ButtonInfo(title: firstBtn.text),
                                            rightBtnInfo: ButtonInfo(title: secondBtn.text))
            } else {
                // 只有右边按钮
                bottomConfig = BottomConfig(rightBtnInfo: ButtonInfo(title: firstBtn.text))
            }
        }

        let targetAnchor = TargetAnchor(targetSourceType: targetSourceType,
                                        offset: offset,
                                        arrowDirection: arrowDirection,
                                        targetRectType: targetRectType)
        let bubbleItemConfig = BubbleItemConfig(guideAnchor: targetAnchor,
                                                textConfig: textConfig,
                                                bannerConfig: bannerConfig,
                                                bottomConfig: bottomConfig)
        return bubbleItemConfig
    }

    static func transformSpotlightPBToMaskConfigData(spotlightPB: UGSpotlightData?) -> MaskConfig? {
        guard let spotlightPB = spotlightPB,
              spotlightPB.spotlightMaterials.hasSpotlightMaskConfig else { return nil }
        let maskConfigData = spotlightPB.spotlightMaterials.spotlightMaskConfig
        let maskInteractionForceOpen = maskConfigData.hasMaskInteractionForceOpen ? maskConfigData.maskInteractionForceOpen : nil
        var windowBackgroundColor: UIColor?
        if !maskConfigData.hasAlpha || CGFloat(maskConfigData.alpha) == 0 {
            windowBackgroundColor = UIColor.clear
        }
        let maskConfig = MaskConfig(shadowAlpha: maskConfigData.hasAlpha ? CGFloat(maskConfigData.alpha) : nil,
                                    windowBackgroundColor: windowBackgroundColor,
                                    maskInteractionForceOpen: maskInteractionForceOpen)
        return maskConfig
    }
}
