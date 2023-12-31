//
//  IESAdLandingChannelInterceptor.h
//  IESWebKit
//
//  Created by li keliang on 2019/6/12.
//

#import <Foundation/Foundation.h>
#import <BDWebKit/IESFalconManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESAdLandingChannelInterceptor : NSObject<IESFalconCustomInterceptor>

- (instancetype)initWithGurdAccessKey:(NSString *)gurdAccessKey NS_DESIGNATED_INITIALIZER;

@property (nonatomic) BOOL  enable;
@property (nonatomic, copy) NSString *channelQueryKey;

@end

NS_ASSUME_NONNULL_END
