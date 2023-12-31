//
//  DVEKeyFrameItem.h
//  DVETrackKit
//
//  Created by bytedance on 2021/8/25.
//

#import <UIKit/UIKit.h>
#import <DVEFoundationKit/NLETrackSlot_OC+DVE.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEKeyFrameItem : UIButton

@property (nonatomic, strong) NLETrackSlot_OC *keyFrameSlot;

- (instancetype)initWithKeyFrame;

@end

NS_ASSUME_NONNULL_END
