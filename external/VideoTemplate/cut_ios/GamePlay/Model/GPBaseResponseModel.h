//
//  GPBaseResponseModel.h
//  VideoTemplate
//
//  Created by bytedance on 2021/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPBaseResponseModel : NSObject

@property (nonatomic, strong) NSNumber *statusCode;
@property (nonatomic, strong) NSNumber *timestamp;
@property (nonatomic, copy) NSString *statusMsg;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, strong) NSError *error;

@end

NS_ASSUME_NONNULL_END
