//
//  HMDHTTPResponseInfo.h
//  Heimdallr
//
//  Created by zhangyuzhong on 2022/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDHTTPResponseInfo : NSObject

@property (nonatomic, assign) NSTimeInterval endTime;
@property (nonatomic, copy) NSString *responseScene;
@property (nonatomic, assign, readwrite) NSInteger isForeground;
@property (nonatomic, assign) CFTimeInterval inAppTime;

@end

NS_ASSUME_NONNULL_END
