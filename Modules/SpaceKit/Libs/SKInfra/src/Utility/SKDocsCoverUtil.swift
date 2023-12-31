//
//  SKDocsCoverUtil.swift
//  SKCommon
//
//  Created by chenhuaguan on 2022/1/11.
//

import SKFoundation
import SpaceInterface
import CoreGraphics
import SKUIKit

public class SKDocsCoverUtil {

    public static func getCoverType(width: CGFloat?, height: CGFloat?, scale: CGFloat?, useDisplayWidth: Bool?) -> DocCommonDownloadType {
        guard let widthValue = width, let heightValue = height else {
            DocsLogger.error("params error")
            return .defaultCover
        }
        DocsLogger.info("getCoverType, width=\(widthValue)，height=\(heightValue), scale=\(scale ?? -1), useDisplay=\(useDisplayWidth ?? false)")
        var displayWidthPX: CGFloat? //单位dx
        var displayHeightPX: CGFloat? //单位dx
        let screenScale = SKDisplay.scale
        if useDisplayWidth == true {
            displayWidthPX = CGFloat(widthValue) * screenScale
            displayHeightPX = CGFloat(heightValue) * screenScale
            debugPrint("getCoverType, useDisplayWidth,  UIScreen.scale=\(screenScale), displayWidthPX=\(displayWidthPX), displayHeightPX=\(displayHeightPX)")
        } else if scale == 1 {
            //如果scale=1，说明没有缩放过。
            displayWidthPX = CGFloat(widthValue)
            displayHeightPX = CGFloat(heightValue)
            debugPrint("getCoverType, scaleValue == 1, displayWidthPX=\(displayWidthPX), displayHeightPX=\(displayHeightPX)")
        } else if let scaleValue = scale, scaleValue > 0, scaleValue < 1 {
            displayWidthPX = CGFloat(widthValue * scaleValue) * screenScale
            displayHeightPX = CGFloat(heightValue * scaleValue) * screenScale
            debugPrint("getCoverType, scaleValue=\(scaleValue), displayWidthPX=\(displayWidthPX), displayHeightPX=\(displayHeightPX)")
        } else {
            return .defaultCover
        }
        return SKDocsCoverUtil.getCoverType(displayWidthPX: displayWidthPX, displayHeightPX: displayHeightPX)
    }

    private static func getCoverType(displayWidthPX: CGFloat?, displayHeightPX: CGFloat?) -> DocCommonDownloadType {
        guard let displayHeightPX = displayHeightPX, displayHeightPX > 0,
              let displayWidthPX = displayWidthPX, displayWidthPX > 0 else {
            return .defaultCover
        }
        let screenScale = SKDisplay.scale
        let windowSize = SKDisplay.activeWindowBounds.size
        let screenWidth = min(windowSize.width, windowSize.height)  //屏幕宽度
        let contentMaxWidth = screenWidth * 0.9  //以屏幕宽度90%作为最大展示宽度
        let contentMaxWidthPX = contentMaxWidth * screenScale // 单位px
        var realDisplayPx = displayWidthPX//单位px
        if displayWidthPX > contentMaxWidthPX {
            realDisplayPx = contentMaxWidthPX
        }
        var coverType: DocCommonDownloadType? = .defaultCover
        if realDisplayPx > CGFloat(CoverType.middleUp.rawValue) {
            coverType = DocCommonDownloadType.bigCover
        } else if realDisplayPx > CGFloat(CoverType.middle.rawValue) {
            coverType = DocCommonDownloadType.middleUp
        } else if realDisplayPx > CGFloat(CoverType.smallUp.rawValue) {
            coverType = DocCommonDownloadType.middle
        } else if realDisplayPx > CGFloat(CoverType.small.rawValue) {
            coverType = DocCommonDownloadType.smallUp
        } else {
            coverType = DocCommonDownloadType.small
        }
        let result = coverType ?? .defaultCover
        DocsLogger.info("getCoverType, screenWidth=\(screenWidth), contentMaxWidthPX=\(contentMaxWidthPX), realDisplayPx=\(realDisplayPx),UIScreen.scale=\(screenScale),result=\(result)")
        debugPrint("getCoverType, screenWidth=\(screenWidth), contentMaxWidthPX=\(contentMaxWidthPX), realDisplayPx=\(realDisplayPx),UIScreen.scale=\(screenScale),result=\(result)")
        return result
    }
}
