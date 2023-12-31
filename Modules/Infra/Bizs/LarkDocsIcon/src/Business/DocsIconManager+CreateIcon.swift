//
//  DocsIconManager+CreateIcon.swift
//  LarkDocsIcon
//
//  Created by ByteDance on 2023/6/30.
//

import Foundation
import RxSwift

extension DocsIconManager {
    
    func createLocalIcon(iconInfo: String,
                         shape: IconShpe = .CIRCLE,
                         container: ContainerInfo? = nil) -> Single<UIImage> {
        
        return Single.create { single in
            
            //1.解析 iconInfo，和判断版本号使用本的还是当前的
            let iconEntry = self.judgeDocsIconVersion(iconInfo: iconInfo)
            
            if let iconEntry = iconEntry {
                
                if self.iconFG?.suiteCustomIcon ?? false { //fg开，才会走自定义表情的逻辑
                    //2. 判断使用图片类型
                    switch iconEntry.type {
                    case .none: // 使用默认图片
                        single(.success(iconEntry.getDefultIcon(shape: shape, container: container)))
                    case .unicode: //生成emoji图片
                        single(.success(iconEntry.getEmojiIcon(shape: shape, container: container)))
                    case .image: // 非emji表情，需要进行下载icon
                        single(.error(DocsIconError.iconInfoNeedDownload(info: iconEntry)))
                    case .word: // 文档图标组件暂时不支持返回文字图标，后续有需求跟着需求改造
                        single(.success(iconEntry.getDefultIcon(shape: shape, container: container)))
                    @unknown default:
                        single(.success(iconEntry.getDefultIcon(shape: shape, container: container)))
                    }
                } else { // fg 关，只走默认原来的图标
                    single(.success(iconEntry.getDefultIcon(shape: shape, container: container)))
                }
                
            } else {
                //3. 走url解析逻辑
                DocsIconLogger.logger.info("iconInfoParseError")
                single(.error(DocsIconError.iconInfoParseError))
            }
            return Disposables.create()
        }
    }
    
    //判断meta版本号大小
    private func judgeDocsIconVersion(iconInfo: String) -> DocsIconInfo? {
        
        //1. 解析失败，或者token为空
        let iconEntry = DocsIconInfo.createDocsIconInfo(json: iconInfo)
        guard let token = iconEntry?.token, !token.isEmpty else {
            return iconEntry
        }
        
        //2. 查询本地mata信息
        guard let localMetaInfo = self.iconCache?.getMetaInfoForKey(Key: token) else {
            //本地为空 缓存起来
            self.iconCache?.saveMetaInfo(docsToken: token, iconInfo: iconInfo)
            return iconEntry
        }
        
        //3. 本地meta解析失败
        guard let localEntry = DocsIconInfo.createDocsIconInfo(json: localMetaInfo) else {
            //缓存起来
            self.iconCache?.saveMetaInfo(docsToken: token, iconInfo: iconInfo)
            return iconEntry
        }
        
        //4. 返回版本号大的
        if (localEntry.version ?? 0) > (iconEntry?.version ?? 0) {
            return localEntry
        } else {
            //5. 缓存起来
            self.iconCache?.saveMetaInfo(docsToken: token, iconInfo: iconInfo)
            return iconEntry
        }
    }
}
