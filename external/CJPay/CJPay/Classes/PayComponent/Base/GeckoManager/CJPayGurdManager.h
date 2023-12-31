//
// Created by 易培淮 on 2020/12/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayGurdManager : NSObject


+ (instancetype)defaultService;

@property (nonatomic, copy, readonly) NSString *accessKey;
@property (nonatomic, copy, readonly) NSString *groupName;
@property (nonatomic, copy, readonly) NSArray<NSString *> *imgChannelList;
@property (nonatomic, assign) BOOL enableImg;
@property (nonatomic, assign) BOOL enableCDNImg;
@property (nonatomic, assign) BOOL enableGurdImg;

@end

NS_ASSUME_NONNULL_END
