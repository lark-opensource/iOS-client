//
//  DocsIconManager.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/29.
//

import Foundation
import RxSwift
import UniverseDesignIcon
import LarkContainer
import LarkIcon

public class DocsIconManager: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver
        
    //缓存
    @ScopedProvider var iconCache: DocsIconCache?
    //url解析成token和type工具
    @ScopedProvider var iconUrlUtil: DocsUrlUtil?
    //fg
    @ScopedProvider var iconFG: DocsIconFeatureGating?
    //setting
    //后续larkIconDisable fg删掉，这个setting也删除
    @ScopedProvider var iconSetting: DocsIconSetting?
    //网络请求
    @ScopedProvider var iconRequest: DocsIconRequest?
    
    @ScopedProvider var larkIconManager: LarkIconManager?
    
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    ///异步获取icon图片
    ///支持通过url进行兜底显示
    public func getDocsIconImageAsync(iconInfo: String,
                                      url: String,
                                      shape: IconShpe = .CIRCLE,
                                      container: ContainerInfo? = nil) -> Observable<UIImage> {
        
        //判断的 显示 container 信息
        if let image = DocsIconInfo.getContainerImage(container: container)  {
            DocsIconLogger.logger.info("show container icon")
            return .just(image)
        }
        
        let localIconOb = createLocalIcon(iconInfo: iconInfo, shape: shape, container: container)
            .asObservable()
            .catchError { error in
                if let error = error as? DocsIconError {
                    switch error {
                        
                        //通过url解析
                    case .iconInfoParseError:
                        return self.parseDocsUrl(url, shape: shape, container: container)
                        //走下载逻辑
                    case .iconInfoNeedDownload(let iconEntry):
                        return self.downloadIcon(iconInfo: iconEntry,
                                                 shape: shape,
                                                 container: container)
                        
                    }
                }
                
                return .just(DocsIconInfo.defultUnknowIcon(shape: shape, container: container))
            }
        return localIconOb
        
    }
    ///异步获取icon图片
    ///支持通过token 和 type 进行兜底显示
    public func getDocsIconImageAsync(iconInfo: String,
                                      token: String,
                                      docsType: CCMDocsType,
                                      shape: IconShpe = .CIRCLE,
                                      container: ContainerInfo? = nil) -> Observable<UIImage> {
        
        //判断的 显示 container 信息
        if let image = DocsIconInfo.getContainerImage(container: container)  {
            DocsIconLogger.logger.info("show container icon")
            return .just(image)
        }
        
        let localIconOb = createLocalIcon(iconInfo: iconInfo, shape: shape, container: container)
            .asObservable()
            .catchError { error in
                
                if let error = error as? DocsIconError {
                    switch error {
                        //通过token解析
                    case .iconInfoParseError:
                        return self.parseDocsToken(token: token, type: docsType, shape: shape, container: container)
                        //走下载逻辑
                    case .iconInfoNeedDownload(let iconEntry):
                        return self.downloadIcon(iconInfo: iconEntry,
                                                 shape: shape,
                                                 container: container)
                    }
                }
                
                return .just(DocsIconInfo.defultUnknowIcon(docsType: docsType, shape: shape, container: container))
            }
        return localIconOb
        
    }
    
    //通过emoji key转换成一张emoji图片
    public static func changeEmojiKeyToImage(key: String) -> UIImage? {
        //字符串转emoji，转失败了用兜底的图标
        guard let emoji = EmojiUtil.scannerStringChangeToEmoji(key: key), !emoji.isEmpty else {
            DocsIconLogger.logger.warn("changeEmojiKeyToImage is nil, key:\(key), use defult icon")
            return nil
        }
        return DocsIconCreateUtil.creatImageWithEmoji(emoji: emoji,
                                                      isShortCut: false)
    }
    
    
}
