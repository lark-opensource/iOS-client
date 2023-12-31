//
//  FBRetainCycleAlogDelegate.h
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FBFinderAlogProtocol <NSObject>
- (void)findInstanceStrongPropertyAlog:(NSString *)alog;
@end

@interface FBRetainCycleAlogDelegate : NSObject
@property(nonatomic,weak) id<FBFinderAlogProtocol> delegate;
+ (instancetype)sharedDelegate;
@end

NS_ASSUME_NONNULL_END
