//
//  DVELiteCollectionPanel.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/11.
//

#import "DVEBaseView.h"
#import "DVEEffectValue.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVEPickerUIConfigurationProtocol;

@interface DVELiteCollectionPanel : DVEBaseView

@property (nonatomic, strong) UIView *bottomContainerView;

@property (nonatomic, copy) dispatch_block_t dismissBlock;

@property (nonatomic, copy) NSString *titleText;

@property (nonatomic, copy) NSString *resetButtonImageName;

@property (nonatomic, assign) CGFloat panelHeight;

@property (nonatomic, strong, nullable) DVEEffectValue *currentEffect;

- (instancetype)initWithFrame:(CGRect)frame
                     uiConfig:(id<DVEPickerUIConfigurationProtocol>)uiConfig
                    vcContext:(DVEVCContext *)vcContext NS_REQUIRES_SUPER;

- (void)updateEffectModelArray:(NSArray<DVEEffectValue *> *)effectModelArray
                   errorString:(NSString * _Nullable)errorString;

- (NSArray *)currentEffectArrayInfo;

- (void)updateEffectIndensity:(BOOL)needCommit NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
