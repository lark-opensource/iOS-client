//
//  DocsIconInfo+DownloadIcon.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/30.
//

import Foundation
import UniverseDesignColor
import LarkContainer
import UniverseDesignTheme
import LarkIcon

extension DocsIconInfo {
    
    //后续 larkIconDisable fg 去掉，这个方法也可以删除
    func getDownLoadIcon(image: UIImage,
                         shape: IconShpe = .CIRCLE,
                         container: ContainerInfo? = nil) -> UIImage  {
        
        switch shape {
        case .CIRCLE:
            //FG 为true 才显示圆形图标底色
            //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
            let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
            if featureGating?.circleBackgroundColor ?? false {
                let lightMode = DocsIconCreateUtil.creatImage(image: image,
                                                              isShortCut: container?.isShortCut ?? false,
                                                              backgroudColor: self.iconBackgroundColor.alwaysLight)
                let darkMode = DocsIconCreateUtil.creatImage(image: image,
                                                             isShortCut: container?.isShortCut ?? false,
                                                             backgroudColor: self.iconBackgroundColor.alwaysDark)
                return lightMode & darkMode
                
            } else { // FG为false：无圆形图标底色
                return DocsIconCreateUtil.creatImage(image: image,
                                                     isShortCut: container?.isShortCut ?? false)
            }
            
        case .SQUARE, .OUTLINE:
            return DocsIconCreateUtil.creatImage(image: image,
                                                 isShortCut: container?.isShortCut ?? false)
        }
    }
}
