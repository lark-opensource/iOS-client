//
//  BDPMetaInfoAccessor.h
//  Timor
//
//  Created by houjihu on 2020/6/16.
//

#import <OPFoundation/BDPModuleEngineType.h>
#import "BDPMetaInfoAccessorProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 存储meta相关的信息 Meta新模块接入前的逻辑 小程序老版本特化使用，现在请使用 MetaLocalAccessor
@interface BDPMetaInfoAccessor: NSObject <BDPMetaInfoAccessorProtocol>

- (instancetype)initWithAppType:(BDPType)appType;

/// NS_UNAVAILABLE
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
