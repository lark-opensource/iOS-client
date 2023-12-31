//
//  ACCAdTrackContext.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAdTrackContextProtocol <NSObject>

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *logExtra;
@property (nonatomic, copy) NSString *refer;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, strong) NSNumber *creativeID;

@end



@interface ACCAdTrackContext : NSObject<ACCAdTrackContextProtocol>

@end

NS_ASSUME_NONNULL_END
