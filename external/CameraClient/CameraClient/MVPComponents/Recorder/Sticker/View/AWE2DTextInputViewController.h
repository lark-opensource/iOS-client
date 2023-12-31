//
//  AWE2DTextInputViewController.h
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by 赖霄冰 on 2019/4/14.
//

#import "AWEStudioBaseViewController.h"
@class IESMMEffectMessage;

NS_ASSUME_NONNULL_BEGIN

@interface AWE2DTextInputViewController : AWEStudioBaseViewController

@property (nonatomic, strong) IESMMEffectMessage *effectMessageModel;
@property (nonatomic, assign) NSUInteger remainingTextCount;

@property (nonatomic, copy) void(^textDidFinishEditingBlock)(NSString *, IESMMEffectMessage *);

- (void)refreshTextStateWithEffectMessageModel:(IESMMEffectMessage *)messageModel;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
