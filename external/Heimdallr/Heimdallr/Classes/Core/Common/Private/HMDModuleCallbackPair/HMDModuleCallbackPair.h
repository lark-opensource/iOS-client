//
//  HMDModuleCallbackPair.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/17.
//

#import <Foundation/Foundation.h>
#import "Heimdallr.h"
#import "Heimdallr+ModuleCallback.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDModuleCallbackPair : NSObject <NSCopying>

@property(nonatomic, nonnull, readonly) NSString *moduleName;

@property(nonatomic, nonnull, readonly) HMDModuleCallback callback;

- (instancetype)initWithModuleName:(NSString *)moduleName callback:(HMDModuleCallback)callback;

- (void)invokeCallbackWithModule:(id<HeimdallrModule> _Nullable)module isWorking:(BOOL)isWorking;

- (BOOL)isEqual:(id)object;

- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END
