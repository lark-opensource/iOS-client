//
//  LarkIconManager+DownloadIcon.swift
//  LarkIcon
//
//  Created by ByteDance on 2023/12/14.
//

import Foundation
import LarkEnv
import RxSwift
import ByteWebImage

extension LarkIconManager {
    ///域名方案整体结论：
    ///图片存储到im侧，域名复用 「User.settingsConfig.biz_domain_config.cdn」（如下图），和已有的 emoji.png 存储方式保持一致
    
    /// 域名-Path-图片名，Path 的规则如下： 从ccm_custom_icon_config setting获取：https:// cloud-boe.bytedance.net/appSettings-v2/detail/config/179397/detail/status
    /// 飞书：obj/lark-reaction-cn
    /// Lark：obj/lark-reaction-va
    /// BOE：obj/lark-test
    // 🌰：sf1-ttcdn-tosxxxxxxorg /obj/lark-test/blue_aperture.png
    private func spliceDownLoadUrl(iconKey: String?) -> String? {
        
        //图片key为空
        guard let iconKey = iconKey, !iconKey.isEmpty else {
            LarkIconLogger.logger.error("spliceDownLoadUrl iconKey error: \(String(describing: iconKey))")
            return nil
        }
        
        //获取域名
        let domain = LarkIconDomain.cdn
        guard !domain.isEmpty else {
            LarkIconLogger.logger.error("spliceDownLoadUrl domain isEmpty")
            return nil
        }
        
        //获取path配置 看下这里为什么拉不到
        let bucketPath = iconSetting?.bucketPath ?? ""
        guard !bucketPath.isEmpty else {
            LarkIconLogger.logger.error("spliceDownLoadUrl bucketPath isEmpty")
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
    
    
    func createDownLoadIcon() -> Observable<LIResult> {
        
        //先返回占位图
        let defultIconOb = Observable.just(self.createDefultIcon())
        guard let iconKey = self.iconKey, !iconKey.isEmpty else {
            return defultIconOb
        }
        
        let downLoadIconOb = self.downloadIcon(iconKey: iconKey).flatMap { result -> Observable<LIResult> in
            guard let image = result.image else {
                return .just(result)
            }
            
            //下载的图片进行生成绘制
            var scale: CGFloat? = nil
            var layer = self.iconExtend.layer
            if case .CIRCLE = self.iconExtend.shape {
                scale = self.circleScale
            } else { //方形和圆角则不处理背景色
                layer?.backgroundColor = nil
            }
            
            let resultImage = LarkIconBuilder.createImageWith(originImage: image,
                                                              scale: scale,
                                                              iconLayer: layer,
                                                              iconShape: self.iconExtend.shape,
                                                              foreground: self.iconExtend.foreground)
            
            return .just((image: resultImage, error: result.error))
        }
        
        return defultIconOb.concat(downLoadIconOb)
    }
    
    
    
    private func downloadIcon(iconKey: String) -> Observable<LIResult> {
        
        return Observable.create { [weak self] observer -> Disposable in
            
            let url = self?.spliceDownLoadUrl(iconKey: iconKey)
            if let url = url {
                LarkImageService.shared.setImage(with: .default(key: url), completion: { imageResult in
                    switch imageResult {
                    case .success(let result):
                        if let image = result.image {
                            observer.onNext((image, nil))
                        } else {
                            observer.onNext((nil, IconError.downLoadIconNil))
                            LarkIconLogger.logger.error("downloadIcon result image nil")
                        }
                    case .failure(let error):
                        observer.onNext((nil, error))
                        LarkIconLogger.logger.error("downloadIcon error: \(error)")
                    }
                    observer.onCompleted()
                })
            } else {
                observer.onNext((nil, IconError.downLoadIconUrlError))
            }
            return Disposables.create()
        }
    }
}
