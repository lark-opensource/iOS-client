//
//  BDTTNetAdapter.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebViewConfiguration;

@interface BDTTNetAdapter : NSObject

@property (nonatomic, assign, class) BOOL isAsyncWhenHandleSchemeTask;
@property (nonatomic, strong, class) NSArray<NSString *> *safeHostList;

@end

NS_ASSUME_NONNULL_END
