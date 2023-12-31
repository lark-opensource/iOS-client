//
//  BDPStorageModule.h
//  Timor
//
//  Created by houjihu on 2020/3/24.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPStorageModule : NSObject <BDPStorageModuleProtocol>

/// 模块管理对象
@property (nonatomic, weak) BDPModuleManager *moduleManager;

@end

NS_ASSUME_NONNULL_END
