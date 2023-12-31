//
//  DocsIconManager+IconBuilder.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/11/16.
//

import Foundation
import RxSwift
import UniverseDesignColor
import UniverseDesignTheme
import ByteWebImage
import LarkIcon


extension DocsIconManager {
    
    // 新api设计
    // 使用例子：
    // 文档业务使用：
    // loadIconImageAsync(iconBuild: IconBuilder(bizIconType: .docsWithUrl(iconInfo: xxx, url: xxx, container: xxx)))
    //
    // 标准图标接入，例如TODO业务
    // loadIconImageAsync(iconBuild: IconBuilder(bizIconType: .iconInfo(iconType: xxx, iconKey: "xxx"), iconExtend: IconExtend(placeHolderImage: xxxx))
    
    public func loadIconImageAsync(iconBuild: IconBuilder) -> Observable<UIImage> {
        
        switch iconBuild.bizIconType {
        case .docsWithUrl(iconInfo: let iconInfo, url: let url,container: let docsContainer):
            return self.getDocsIconImageAsync(iconInfo: iconInfo ?? "",
                                              url: url,
                                              shape: iconBuild.iconExtend.shape,
                                              container: docsContainer)
            
        case .docsWithToken(iconInfo: let iconInfo, token: let token, type: let type, container: let docsContainer):
            return self.getDocsIconImageAsync(iconInfo: iconInfo ?? "",
                                              token: token,
                                              docsType: type,
                                              shape: iconBuild.iconExtend.shape,
                                              container: docsContainer)
            
        case .iconInfo(iconType: let iconType, iconKey: let iconKey, textColor: let textColor):
            return self.getIconImageAsync(iconType: IconType(rawValue: iconType),
                                          iconKey: iconKey,
                                          textColor: textColor,
                                          iconExtend: iconBuild.iconExtend)
        }
        
    }
}

extension DocsIconManager {
    
    private func getDefultBackgroundColor() -> UIColor {
        let lightColor = UDColor.N50.alwaysLight
        return lightColor & lightColor.withAlphaComponent(0.2)
    }
    
    //通过type + key构建图标
    private func getIconImageAsync(iconType: IconType, iconKey: String, textColor: String? = nil, iconExtend: IconExtend) -> Observable<UIImage> {
        
        
        //2. 判断使用图片类型
        switch iconType {
        case .none, .word: // 使用默认图片, 文档图标组件暂时不支持word，暂时先返回默认图标
            
            guard let image = iconExtend.placeHolderImage else {
                return .empty()
            }
            
            let resultImage = getDefultIcon(defultIcon: image, iconExtend: iconExtend)
            return .just(resultImage)
            
        case .unicode: //生成emoji图片
            //字符串转emoji，转失败了用兜底的图标
            guard let emoji = EmojiUtil.scannerStringChangeToEmoji(key: iconKey), !emoji.isEmpty else {
                DocsIconLogger.logger.warn("scannerStringChangeToEmoji is nil, key:\(iconKey), use defult icon")
                
                if let image = iconExtend.placeHolderImage {
                    let resultImage = self.getDefultIcon(defultIcon: image, iconExtend: iconExtend)
                    return .just(resultImage)
                }
                
                return .empty()
            }
            
            switch iconExtend.shape {
            case .CIRCLE:
                
                let backgroundColor = iconExtend.backgroundColor ?? self.getDefultBackgroundColor()
                let lightMode = DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                                       isShortCut: false,
                                                                       backgroudColor: backgroundColor.alwaysLight)
                let darkMode = DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                                      isShortCut: false,
                                                                      backgroudColor: backgroundColor)
                let resultImage = lightMode & darkMode
                return .just(resultImage)
                
            case .SQUARE, .OUTLINE:
                let resultImage = DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                                         isShortCut:  false)
                return .just(resultImage)
            }
            
        case .image:  // 非emji表情，需要进行下载icon
            return self.downloadIcon(iconKey: iconKey, iconExtend: iconExtend)
        }
        
        
        
    }
    
    //默认图标 + 图标形状处理
    func getDefultIcon(defultIcon: UIImage, iconExtend: IconExtend) -> UIImage {
        
        switch iconExtend.shape {
        case .CIRCLE:
            let backgroundColor = iconExtend.backgroundColor ?? self.getDefultBackgroundColor()
            
            let lightMode = DocsIconCreateUtil.creatImage(image: defultIcon,
                                                          isShortCut: false,
                                                          backgroudColor: backgroundColor.alwaysLight)
            let darkMode = DocsIconCreateUtil.creatImage(image: defultIcon,
                                                         isShortCut: false,
                                                         backgroudColor: backgroundColor.alwaysDark)
            let resultImage = lightMode & darkMode
            
            return resultImage
            
            
        case .SQUARE, .OUTLINE:
            let resultImage = DocsIconCreateUtil.creatImage(image: defultIcon,
                                                            isShortCut: false)
            return resultImage
        }
        
    }
    
    // 下载图标
    private func downloadIcon(iconKey: String,
                              iconExtend: IconExtend) -> Observable<UIImage> {
        
        return Observable.create { [weak self] observer -> Disposable in
            
            guard let self else {
                return Disposables.create()
            }
            if let placeHolderImage = iconExtend.placeHolderImage {
                //先返回占位图
                observer.onNext(self.getDefultIcon(defultIcon: placeHolderImage, iconExtend: iconExtend))
            }
            
            
            let url = self.spliceDownLoadUrl(iconKey: iconKey)
            if let url = url {
                LarkImageService.shared.setImage(with: .default(key: url), completion: { imageResult in
                    switch imageResult {
                    case .success(let result):
                        if let image = result.image {
                            let iconImage = self.getDefultIcon(defultIcon: image, iconExtend: iconExtend)
                            observer.onNext(iconImage)
                        } else {
                            DocsIconLogger.logger.error("downloadIcon result image nil")
                        }
                    case .failure(let error):
                        DocsIconLogger.logger.error("downloadIcon error: \(error)")
                    }
                    observer.onCompleted()
                })
            }
            return Disposables.create()
        }
    }
    
}
