//
//  DocsIconManager+DownloadIcon.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/30.
//

import Foundation
import RxSwift
import ByteWebImage
import LarkEnv
import LarkIcon
import LarkContainer
import UniverseDesignIcon

extension DocsIconManager {
    
    ///域名方案整体结论：
    ///图片存储到im侧，域名复用 「User.settingsConfig.biz_domain_config.cdn」（如下图），和已有的 emoji.png 存储方式保持一致

    /// 域名-Path-图片名，Path 的规则如下： 从ccm_custom_icon_config setting获取：https:// cloud-boe.bytedance.net/appSettings-v2/detail/config/179397/detail/status
    /// 飞书：obj/lark-reaction-cn
    /// Lark：obj/lark-reaction-va
    /// BOE：obj/lark-test
    // 🌰：sf1-ttcdn-tosxxxxxxorg /obj/lark-test/blue_aperture.png
    func spliceDownLoadUrl(iconKey: String?) -> String? {
        
        //图片key为空
        guard let iconKey = iconKey, !iconKey.isEmpty else {
            DocsIconLogger.logger.error("spliceDownLoadUrl iconKey error: \(String(describing: iconKey))")
            return nil
        }
        
        //获取域名
        let domain = DocsIconDomain.cdn
        guard !domain.isEmpty else {
            DocsIconLogger.logger.error("spliceDownLoadUrl domain isEmpty")
            return nil
        }
        
        //获取path配置 看下这里为什么拉不到
        let bucketPath = iconSetting?.bucketPath ?? ""
        guard !bucketPath.isEmpty else {
            DocsIconLogger.logger.error("spliceDownLoadUrl bucketPath isEmpty")
            return nil
        }
        
        //拼接图片url待改成
        var scheme = "https"
        if EnvManager.env.type == .staging { //boe环境用http请求
            scheme = "http"
        }
        let iconUrl = "\(scheme)://\(domain)/\(bucketPath)/\(iconKey)"
        
        return iconUrl
    }
    
    func downloadIcon(iconInfo: DocsIconInfo,
                      shape: IconShpe = .CIRCLE,
                      container: ContainerInfo? = nil) -> Observable<UIImage> {
        
        //不是图片类型
        guard iconInfo.type == .image else {
            DocsIconLogger.logger.error("downloadIcon type error: \(iconInfo.type)")
            return .empty()
        }
        
        //反向fg， FG 为false 接入使用larkIcon
        //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        if !(featureGating?.larkIconDisable ?? true) {
            guard let iconManager = self.larkIconManager else {
                return .empty()
            }
            let isShortCut = container?.isShortCut ?? false
            let shortCutImage: UIImage? = isShortCut ? UDIcon.wikiShortcutarrowColorful : nil
            let iconExtend = LarkIconExtend(shape: self.getDownLoadIconShape(shape: shape),
                                            layer: IconLayer(backgroundColor: iconInfo.iconBackgroundColor),
                                            foreground: IconForeground(foregroundImage: shortCutImage))
            
            return iconManager.builder(iconType: .image, iconKey: iconInfo.key, iconExtend: iconExtend).map { result in
                return result.image ?? DocsIconInfo.defultUnknowIcon(docsType: iconInfo.objType, shape: shape, container: container)
            }
            
        }
        
        //后续larkIconDisable fg删掉，后面的代码也删除
        return Observable.create { [weak self] observer -> Disposable in
            
            //先返回占位图
            observer.onNext(DocsIconInfo.defultUnknowIcon(docsType: iconInfo.objType, shape: shape, container: container))
            
            let url = self?.spliceDownLoadUrl(iconKey: iconInfo.key)
            if let url = url {
                LarkImageService.shared.setImage(with: .default(key: url), completion: { imageResult in
                    switch imageResult {
                    case .success(let result):
                        if let image = result.image {
                            let iconImage = iconInfo.getDownLoadIcon(image: image, shape: shape, container: container)
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
    
    //判断和转换图标形状
    func getDownLoadIconShape(shape: IconShpe = .CIRCLE) -> LarkIconShape  {
        
        switch shape {
        case .CIRCLE:
            //FG 为true 才显示圆形图标底色
            //fg使用，后续会比较快的去掉该fg，就没有用户态的问题
            let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
            if featureGating?.circleBackgroundColor ?? false {
                return .CIRCLE
                
            } else { // FG为false：无圆形图标底色
                return .SQUARE
            }
            
        case .SQUARE, .OUTLINE:
            return .SQUARE
        }
    }
}
