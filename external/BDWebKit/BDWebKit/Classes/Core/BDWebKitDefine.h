//
//  BDWebKitDefine.h
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#ifndef BDWebKitDefine_h
#define BDWebKitDefine_h

typedef NS_ENUM(NSUInteger, BDWebViewOfflineType) {
    BDWebViewOfflineTypeNone,
    BDWebViewOfflineTypeBetweenStartAndFinishLoad,// 推荐, WebView 请求开始到 Finsih 内使用 NSURLProtocol 拦截，Finish 之后的资源无法命中离线化
    BDWebViewOfflineTypeWholeLife,  // WebView 生命周期内使用 NSURLProtocol 拦截, 会有 Post Body 丢失问题
    BDWebViewOfflineTypeTaskScheme, // 推荐, TTNet 代理，开启之后内部文件流请求会失败, 推荐在 iOS 12.2 以上打开
    BDWebViewOfflineTypeAboutWk, // 暂不支持
    BDWebViewOfflineTypeChannelInterceptor, //针对资源域名不统一的落地页，指定资源目录，进行拦截
    BDWebViewOfflineTypeTaskSchemeResourLoader  // 等同BDWebViewOfflineTypeTaskScheme,但使用ResourceLoader完成离线化资源请求
};

#endif /* BDWebKitDefine_h */
