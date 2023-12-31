//
//  ACCMeasureOnceItem.h
//  Pods
//
//  Created by 郝一鹏 on 2019/8/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMeasureOnceItem : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign) NSTimeInterval timestamp;

- (instancetype)initWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
