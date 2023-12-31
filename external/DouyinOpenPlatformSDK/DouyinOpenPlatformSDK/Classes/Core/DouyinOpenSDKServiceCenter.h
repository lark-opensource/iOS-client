//
//  DouyinOpenSDKServiceCenter.h
//
//  Created by Spiker on 2019/7/9.
//

#import <Foundation/Foundation.h>
#import "DouyinOpenSDKURLServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DouyinOpenSDKServiceCenter : NSObject

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)p_registerServiceClass:(Class<DouyinOpenSDKURLServiceProtocol>)servicer;

+ (instancetype)sharedInstance;

/// 是否为 UniversalLink
+ (BOOL)isUniversalLinkWithOpenUrl:(NSString *)openUrl;

/// appType 转为字符串，上报用
+ (NSString *_Nonnull)hostStringFromAppType:(DouyinOpenSDKTargetAppType)appType schemaUrl:(NSString *_Nonnull)schemaUrl;

@property (nonatomic, copy) NSDictionary <NSString *, id<DouyinOpenSDKURLServiceProtocol>>*name2Service;
@property (nonatomic, copy) NSDictionary <NSString *, id<DouyinOpenSDKURLServiceProtocol>>*reqCls2Service;
@property (nonatomic, strong) NSMutableDictionary <NSString *, DouyinOpenSDKRequestCompletedBlock>* reqID2CallBack;

@end

NS_ASSUME_NONNULL_END
