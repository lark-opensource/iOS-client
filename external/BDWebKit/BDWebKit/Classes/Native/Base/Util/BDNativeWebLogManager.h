//
//  BDNativeWebLogManager.h
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/7/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define __BDNativeFILENAME__ (strrchr(__FILE__,'/')+1)

#define BDNativeInfo(FORMAT, ...) [[BDNativeWebLogManager sharedInstance] printLog:[NSString stringWithFormat:@"BDNativeTag fileName:%@ funcName:%@ log:%@",[NSString stringWithUTF8String:__BDNativeFILENAME__],[NSString stringWithUTF8String:__FUNCTION__],[NSString stringWithFormat:FORMAT, ##__VA_ARGS__]]]

typedef void(^BDNativeLogBolock)(NSString * log);

@interface BDNativeWebLogManager : NSObject

+ (instancetype)sharedInstance;

- (void)configLogBlock:(BDNativeLogBolock)logBlock;

- (void)printLog:(NSString *)log;

@end

NS_ASSUME_NONNULL_END
