//
//  BDLynxImageLoader.h
//  BDLynx
//
//  Created by annidy on 2020/3/29.
//

#import <Foundation/Foundation.h>
#import "BDLImageLoaderProtocol.h"
#import "BDLynxBundle.h"

NS_ASSUME_NONNULL_BEGIN

/// 卡片图片资源加载器
@interface BDLynxImageLoader : NSObject <BDLImageLoaderProtocol>

/// 针对某个卡片的图片Fetcher
/// @param bundle bundle对象
/// @param cardID 卡片ID
- (instancetype)initWithBundle:(BDLynxBundle *)bundle cardID:(NSString *)cardID;

- (instancetype)initWithTemplateConfig:(BDLynxTemplateConfig *)config;

@end

NS_ASSUME_NONNULL_END
