//
//  LVCutSameResourceManager.h
//  VideoTemplate-Pods-Aweme
//
//  Created by zhangyuanming on 2021/2/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVCutSameResourceManager : NSObject

+ (BOOL)replaceResourceAtPath:(NSString *)path
                       toPath:(NSString *)toPath
                        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
