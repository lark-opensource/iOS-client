//
//  LVTask.h
//  LVTemplate
//
//  Created by haoxian on 2019/11/15.
//

#ifndef LVTask_h
#define LVTask_h

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LVTask <NSObject>

- (NSString *)taskID;

@end

@protocol LVProgressTask <NSObject, LVTask>

typedef void(^LVTaskProgressCallback)(id<LVTask> obj, CGFloat progress);

@property (nonatomic, copy, nullable) LVTaskProgressCallback progressHandler;

@end

NS_ASSUME_NONNULL_END

#endif /* LVTask_h */
