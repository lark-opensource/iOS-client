//
//  IESGurdPatch.h
//  IESGeckoKit
//
//  Created by xinwen tan on 2021/6/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdPatch : NSObject

+ (BOOL)checkFileMD5InDirs:(NSString *)dir1 dir2:(NSString *)dir2;

- (BOOL)patch:(NSString *_Nonnull)src
         dest:(NSString *_Nonnull)dest
        patch:(NSString *_Nonnull)patch
        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
