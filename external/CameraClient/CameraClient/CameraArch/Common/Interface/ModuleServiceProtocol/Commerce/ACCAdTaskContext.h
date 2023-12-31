//
//  ACCAdTaskContext.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAdTaskContextProtocol <NSObject>

@property (nonatomic, copy) NSString *webURL;
@property (nonatomic, copy) NSString *openURL;

@end


@interface ACCAdTaskContext : NSObject<ACCAdTaskContextProtocol>

@end

NS_ASSUME_NONNULL_END
