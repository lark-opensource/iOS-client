//
//  BDLTimorLynxProtocol.h
//  BDLynx
//
//  Created by annidy on 2020/2/25.
//

#import <Foundation/Foundation.h>
#import "BDLynxModuleData.h"
#import "BDLyxnChannelConfig.h"
#import "LynxView.h"

NS_ASSUME_NONNULL_BEGIN

/// TimorLynx Subspec依赖的协议，宿主无需关心
@protocol BDLLynxModuleProtocol <NSObject>

- (Class<LynxModule>)lynxModule;

- (NSString *)scriptPath;

- (NSString *)versionString;

- (void)updateModuleData:(BDLynxModuleData *)data context:(id)context;

@end

NS_ASSUME_NONNULL_END
