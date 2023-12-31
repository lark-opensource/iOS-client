//
//  AWEVoiceChangePannel.h
//  Pods
//
//  Created by chengfei xiao on 2019/5/22.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "AWEVoiceChangerSelectView.h"
#import <CreativeKit/ACCPanelViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel, AWEVideoPublishViewModel;

@interface AWEVoiceChangePannel : UIView <ACCPanelViewProtocol>

@property (nonatomic, readonly) AWEVoiceChangerSelectView *voiceSelectView;
@property (nonatomic,     copy) void (^dismissHandler)(void);
@property (nonatomic,     copy) void (^didSelectVoiceHandler)(IESEffectModel * _Nullable voiceEffect,NSError * _Nullable error);
@property (nonatomic,     copy) void (^didTapVoiceHandler)(IESEffectModel * _Nullable voiceEffect,NSError * _Nullable error);
@property (nonatomic, copy) void (^clearVoiceEffectHandler)(void);
@property (nonatomic,   assign) BOOL showing;
@property (nonatomic,   strong) NSMutableDictionary *preProcessCacheDic;

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)pannelDidShow;

@end

NS_ASSUME_NONNULL_END
