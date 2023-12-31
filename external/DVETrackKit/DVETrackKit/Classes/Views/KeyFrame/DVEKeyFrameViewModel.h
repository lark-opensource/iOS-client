//
//  DVEKeyFrameViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/8/26.
//

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"
#import "DVEKeyFrameProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEKeyFrameViewModel : NSObject<DVEKeyFrameDateSource>

@property (nonatomic, assign) BOOL isShowKeyFrame;
@property (nonatomic, strong) NLETrackSlot_OC *slot;
@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithContext:(DVEMediaContext *)context
                          frame:(CGRect)frame
                 isShowKeyFrame:(BOOL)isShowKeyFrame
                           slot:(nonnull NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
