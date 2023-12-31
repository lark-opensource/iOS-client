//
//  ACCEventAttribute.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>

@interface ACCEventAttribute : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id value;

+ (instancetype)attributeNamed:(NSString *)name;

/**
 链式调用设置value
 */
- (ACCEventAttribute *(^)(id))equalTo;


/**
 block方式设置value

 @param block  block
 */
- (void)equalTo:(id(^)(ACCEventAttribute *attribute))block;
@end

