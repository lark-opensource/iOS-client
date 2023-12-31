//
//  ACCNewYearWishModuleEditView.h
//  Aweme
//
//  Created by 卜旭阳 on 2021/11/2.
//

#import <UIKit/UIKit.h>

@protocol ACCStickerPlayerApplying;
@class AWEVideoPublishViewModel, IESEffectModel;

@interface ACCNewYearWishModuleEditView : UIView

@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, copy, nullable) void(^onModuleSelected)(NSString *, NSInteger);
@property (nonatomic, copy, nullable) void(^onTrackEvent)(NSString *, NSDictionary *);
@property (nonatomic, copy, nullable) dispatch_block_t dismissBlock;
@property (nonatomic, weak, nullable) id<ACCStickerPlayerApplying> player;

- (void)performAnimation:(BOOL)show;

@end
