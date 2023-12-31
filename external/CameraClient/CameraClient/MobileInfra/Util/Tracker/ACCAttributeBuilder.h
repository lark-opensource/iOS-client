//
//  ACCAttributeBuilder.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import "ACCEventAttribute.h"

@interface ACCAttributeBuilder : NSObject

/**
 添加attribute
 */
- (ACCEventAttribute * (^)(NSString *))attribute;


/**
 attribute 装载

 @return  装载完成后的params
 */
- (NSDictionary *)install;
@end
