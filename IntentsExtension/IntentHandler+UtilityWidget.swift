//
//  IntentHandler+UtilityWidget.swift
//  IntentsExtension
//
//  Created by Hayden Wang on 2022/4/7.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import Intents
import LarkWidget
import UIKit
import IntentsUI

extension IntentHandler: LarkUtilityConfigurationIntentHandling {

    func provideAvailableToolsOptionsCollection(for intent: LarkUtilityConfigurationIntent,
                                                searchTerm: String?,
                                                with completion: @escaping (INObjectCollection<INUtilityTool>?, Error?) -> Void) {
        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)
        // 从 UtilityWidgetData 中加载选项
        let widgetData = utilityWidgetData
        let addedTools = intent.availableTools ?? []
        let section1: [INUtilityTool] = widgetData.quickTools
            .map({ $0.toINUtilityTool() })
            .filterAvailableTools(addedTools: addedTools, searchTerm: searchTerm)
        let section2: [INUtilityTool] = widgetData.navigationTools
            .map({ $0.toINUtilityTool() })
            .filterAvailableTools(addedTools: addedTools, searchTerm: searchTerm)
        let section3: [INUtilityTool] = widgetData.workplaceTools
            .map({ $0.toINUtilityTool() })
            .filterAvailableTools(addedTools: addedTools, searchTerm: searchTerm)
        completion(INObjectCollection(sections: [
            INObjectSection(title: BundleI18n.LarkWidget.Lark_Widget_iOS_SelectFeature_ShortcutFeature_Title, items: section1),
            INObjectSection(title: BundleI18n.LarkWidget.Lark_Widget_iOS_SelectFeature_ShortcutApp_Title, items: section2),
            INObjectSection(title: BundleI18n.LarkWidget.Lark_Widget_iOS_SelectFeature_Workplace_Title, items: section3)
        ]), nil)
    }

    func defaultAvailableTools(for intent: LarkUtilityConfigurationIntent) -> [INUtilityTool]? {
        // 更新 Widget 中使用到的 host、language 等信息
        WidgetAuthInfo.updateEnvironmentVariables(with: authInfo)
        // 默认选项（Search、Scan、Workplace），优先从 App 数据中更新，如果没有再取本地数据
        let widgetData = utilityWidgetData
        let allTools = widgetData.quickTools + widgetData.navigationTools + widgetData.workplaceTools
        let search = allTools.first(where: { $0.identifier == UtilityTool.search.identifier }) ?? .search
        let scan = allTools.first(where: { $0.identifier == UtilityTool.scan.identifier }) ?? .scan
        let workplace = allTools.first(where: { $0.identifier == UtilityTool.workplace.identifier }) ?? .workplace
        return [search, scan, workplace].map {
            $0.toINUtilityTool()
        }
    }
}

// MARK: - UtilityTool Extension

extension UtilityTool {

    func toINUtilityTool() -> INUtilityTool {
        let tool = INUtilityTool(identifier: identifier, display: name)
        tool.name = name
        tool.colorKey = colorKey
        tool.iconKey = iconKey
        tool.appLink = appLink
        tool.resourceKey = resourceKey
        tool.key = key
        /*
        // 必须使用 data 的方式，使用 init(uiImage:) 会无法显示列表
        if let image = iconImage?.withRoundedCorners(), let cgImage = image.cgImage {
            tool.displayImage = INImage(cgImage: cgImage)
        }
         */
        tool.displayImage = iconINImage
        return tool
    }

    var iconImage: UIImage? {
        var image: UIImage?
        if !resourceKey.isEmpty {
            image = UIImage(named: resourceKey)
        } else if !iconKey.isEmpty {
            image = UIImage(named: "tool_\(iconKey)")
        }
        return image ?? UIImage(named: "default_utility_icon")
    }

    var iconINImage: INImage? {
        var image: INImage?
        if !resourceKey.isEmpty {
            image = INImage(named: resourceKey)
        } else if !iconKey.isEmpty {
            image = INImage(named: "tool_\(iconKey)")
        }
        return image ?? INImage(named: "default_utility_icon")
    }
}

// MARK: - INUtilityTool Extension

extension Array where Element == INUtilityTool {

    /// 从列表中过滤掉已选择的数据，并通过搜索关键词筛选
    func filterAvailableTools(addedTools: [INUtilityTool], searchTerm: String?) -> [INUtilityTool] {
        return filter { tool in
            // 过滤掉已经添加的项目
            guard !addedTools.map({ $0.identifier }).contains(tool.identifier) else {
                return false
            }
            // 过滤出包含搜索关键词的项目
            guard let searchTerm = searchTerm?.trimmingCharacters(in: .whitespacesAndNewlines), !searchTerm.isEmpty else {
                return true
            }
            return tool.displayString.contains(searchTerm)
        }
    }
}

// MARK: - Image Extension

extension UIImage {

    public func tinted(_ color: UIColor,
                       renderingMode: UIImage.RenderingMode = .automatic) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage?.withRenderingMode(renderingMode) ?? UIImage()
    }

    // image with rounded corners
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 4
        let cornerRadius: CGFloat
        if let radius = radius, radius > 0 && radius <= maxRadius {
            cornerRadius = radius
        } else {
            cornerRadius = maxRadius
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
