//
//  WikiSpaceCustomIcon.swift
//  SKWorkspace
//
//  Created by majie.7 on 2023/8/23.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme


public class WikiSpaceCustomIcon: UILabel {
    
    // icon的背景色选取：通过取spaceId的后四位与颜色总数相模，取结果作为数组下标取准确的颜色
    // 设计稿：https://www.figma.com/file/G00Tn2sKlxdoIUCtCBVm4n/
    private let colorArray: [UIColor] = [
        UDColor.O400,
        UDColor.R400,
        UDColor.C400,
        UDColor.V400,
        UDColor.P400,
        UDColor.B400,
        UDColor.I400,
        UDColor.W400,
        UDColor.T400,
        UDColor.G400
    ]
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        layer.cornerRadius = frame.size.width / 4
        layer.masksToBounds = true
        layer.borderWidth = 1
        textAlignment = .center
        font = UIFont.systemFont(ofSize: frame.size.width / 1.77, weight: .medium)
    }
    
    public func getImage(spaceName: String, spaceId: String) -> UIImage? {
        text = getIconWord(spaceName: spaceName)
        let color = getIconColor(spaceId: spaceId)
        
        // 绘制Image
        var lightImage: UIImage?
        var darkImage: UIImage?
        
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)
        // 生成LM-Image
        textColor = color.alwaysLight
        backgroundColor = UDColor.bgFloat.alwaysLight
        layer.ud.setBorderColor(color.alwaysLight)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
        }
        
        lightImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // 生成DM-Image
        textColor = color.alwaysDark
        backgroundColor = UDColor.bgFloat.alwaysDark
        layer.ud.setBorderColor(color.alwaysDark)
        if let context = UIGraphicsGetCurrentContext() {
            layer.render(in: context)
        }
        darkImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let image = dynamicImage(light: lightImage, dark: darkImage)
        return image
    }
    
    // 处理icon的颜色展示
    private func getIconColor(spaceId: String) -> UIColor {
        // 颜色选择
        var colorIndex: Int = 0
        let maxSubSpaceIdCount: Int = 4
        if spaceId.isEmpty || spaceId.count < maxSubSpaceIdCount {
            // spaceId不满足从数组中取色的规则，则默认取数组中第一个颜色
            colorIndex = 0
        } else {
            // 取spaceId后四位与0xFFF，与颜色总数相模
            let subSpaceId = spaceId.suffix(maxSubSpaceIdCount)
            if let subSpaceIdInt = Int(subSpaceId) {
                colorIndex = (subSpaceIdInt & 0xFFF) % colorArray.count
            } else {
                colorIndex = 0
            }
        }
        return colorArray[colorIndex]
    }
    
    // 处理icon的内容展示
    private func getIconWord(spaceName: String) -> String {
        var text: String
        let string = spaceName.trim().capitalized
        let firstCharacter = string.first
        if let firstCharacter {
            text = String(firstCharacter)
        } else {
            // 知识库名称为空，不绘制文字
            text = ""
        }
        return text
    }
    
    private func dynamicImage(light: UIImage?, dark: UIImage?) -> UIImage? {
        if let dark = dark, let light = light {
            return UIImage.dynamic(light: light, dark: dark)
        }
        return light
    }
}
