//
//  TSPKDelayDetectSchduler.h
//  TSPrivacyKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/1/17.
//

#import <Foundation/Foundation.h>

@protocol TSPKDelayDetectDelegate <NSObject>
@required

- (void)executeDetectWithActualTimeGap:(NSTimeInterval)actualTimeGap;

@optional

- (BOOL)isContinueExecuteAction;
- (nullable NSString *)getComparePage;

@end

@interface TSPKDelayDetectModel : NSObject

@property (nonatomic, assign) NSTimeInterval detectTimeDelay;
@property (nonatomic, assign) BOOL isAnchorPageCheck;
@property (nonatomic, assign) BOOL isCancelPrevDetectWhenStartNewDetect;

@end

@interface TSPKDelayDetectSchduler : NSObject

- (nullable instancetype)initWithDelayDetectModel:(nonnull TSPKDelayDetectModel *)delayDetectModel
                                         delegate:(nonnull id <TSPKDelayDetectDelegate>)delegate;

- (void)startDelayDetect;
- (void)stopDelayDetect;

- (BOOL)isDelaying;

- (NSTimeInterval)timeDelay;

@end
