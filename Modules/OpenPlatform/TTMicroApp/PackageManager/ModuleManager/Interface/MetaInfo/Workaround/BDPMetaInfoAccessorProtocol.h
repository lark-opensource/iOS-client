//
//  BDPMetaInfoAccessorProtocol.h
//  Timor
//
//  Created by houjihu on 2020/6/17.
//

#ifndef BDPMetaInfoManagerProtocol_h
#define BDPMetaInfoManagerProtocol_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPModel;

/// 请千万不要在BDPStorageManager和数据库迁移（GadgetMetaMigration）以外调用这些方法，如果强行调用，请自行负责新老版本的FG适配，或者编写case study做复盘，然后revert掉代码
/// 应用元数据 数据库管理类 小程序老版本特化使用，现在请使用 MetaLocalAccessor
@protocol BDPMetaInfoAccessorProtocol <NSObject>
/// 释放数据库实例
- (void)closeDBQueue;
/// 获取所有老meta数据 仅迁移meta使用
- (NSArray <NSDictionary *> *)getAllModelData;
@end

NS_ASSUME_NONNULL_END

#endif /* BDPMetaInfoManagerProtocol_h */
