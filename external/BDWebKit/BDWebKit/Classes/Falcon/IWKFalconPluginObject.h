//
//  IWKFalconPluginObject.h
//  IESWebKit
//
//  Created by li keliang on 2018/12/27.
//

#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, IWKFalconInnerHandle) {
    IWKFalconInnerHandleNone                = 0,
    IWKFalconInnerHandleWaitTimeforever = 1 << 0,
    IWKFalconInnerHandleFixAssociate    = 1 << 1,
};

@interface NSURLRequest (IWKFalconPlugin)

@property (nonatomic) BOOL IWK_skipFalcon;

@end

@interface IWKFalconPluginObject : IWKPluginObject<IWKClassPlugin>

@end

@interface WKWebView(QI) // 奇计划排查问题专用

@property (nonatomic) IWKFalconInnerHandle falcon_innerHandle;

@end

NS_ASSUME_NONNULL_END
