//
//  AWEARTextInputViewController.h
//  Pods
//
//  Created by 郝一鹏 on 2019/3/13.
//

#import "AWEStudioBaseViewController.h"
@class IESMMEffectMessage;

NS_ASSUME_NONNULL_BEGIN

@interface AWEARTextInputViewController : AWEStudioBaseViewController

@property (nonatomic, strong) IESMMEffectMessage *effectMessageModel;
@property (nonatomic, assign) NSUInteger maxTextCount;

@property (nonatomic, copy) void(^textChangedBlock)(NSString *, IESMMEffectMessage *);
@property (nonatomic, copy) void(^completionBlock)(BOOL);

- (void)refreshTextStateWithEffectMessageModel:(IESMMEffectMessage *)messageModel;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
