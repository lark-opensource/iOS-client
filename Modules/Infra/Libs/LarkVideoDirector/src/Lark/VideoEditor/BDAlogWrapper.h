//
//  BDAlogWrapper.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/11/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// BDAlog 透传接口
@interface BDAlogWrapper : NSObject

+ (void)error:(NSString*)message;

+ (void)warn:(NSString*)message;

+ (void)info:(NSString*)message;

+ (void)debug:(NSString*)message;

@end

NS_ASSUME_NONNULL_END
