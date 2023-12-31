//
//  AWEVoiceChangerSelectView.h
//  Pods
//
//  Created by chengfei xiao on 2019/5/22.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>


NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@interface AWEVoiceChangerSelectView : UIView

@property (nonatomic,   strong) UICollectionView *collectionView;
@property (nonatomic,     copy) void (^didSelectVoiceEffectHandler)(IESEffectModel *voiceEffect, NSError * _Nullable error);
@property (nonatomic,     copy) void (^didTapVoiceEffectHandler)(IESEffectModel *voiceEffect, NSError * _Nullable error);
@property (nonatomic, copy) void (^clearVoiceEffectHandler)(void);
@property (nonatomic,   assign) BOOL isPreprocessing;//VESDK变声接口是同步的
@property (nonatomic, readonly) NSIndexPath *selectedIndexPath;
@property (nonatomic, readonly) NSMutableArray <IESEffectModel *> *effectList;

- (instancetype)initWithFrame:(CGRect)frame publishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)updateWithVoiceEffectList:(NSArray <IESEffectModel *>*)effectList recoverWithVoiceID:(NSString * _Nullable)recoverEffectID;

- (void)resetSelectedIndex;
- (void)reloadData;
- (void)selectNoneItemIfNeeded;
@end

NS_ASSUME_NONNULL_END
