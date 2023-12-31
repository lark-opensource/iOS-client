//
//  ACCDuetLayoutModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/15.
//

#import <Foundation/Foundation.h>

#import <Mantle/Mantle.h>
#import <TTVideoEditor/IESMMEffectConfig.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kACCDuetLayoutGuideTagUpDown;
FOUNDATION_EXTERN NSString * const kACCDuetLayoutGudieThreeScreen;
FOUNDATION_EXTERN NSString * const kACCDuetGreenScreenIsEverShot;

FOUNDATION_EXTERN NSString * const supportDuetLayoutNewUp;
FOUNDATION_EXTERN NSString * const supportDuetLayoutNewDown;
FOUNDATION_EXTERN NSString * const supportDuetLayoutNewLeft;
FOUNDATION_EXTERN NSString * const supportDuetLayoutNewRight;
FOUNDATION_EXTERN NSString * const supportDuetLayoutPictureInPicture;

//合拍布局是否支持左右或者上下切换
typedef NS_ENUM(NSUInteger, ACCDuetLayoutSwitchType) {
    ACCDuetLayoutSwitchTypeNone = 0,
    ACCDuetLayoutSwitchTypeLeftRight,
    ACCDuetLayoutSwitchTypeTopBottom,
};

@class IESEffectModel;

@interface ACCDuetLayoutTrackModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) ACCDuetLayoutSwitchType switchType;
@property (nonatomic, strong) NSArray *shootAtList;
@property (nonatomic, strong) NSArray *duetLayoutList;

@end

@interface ACCDuetLayoutModel : NSObject

@property (nonatomic, strong) IESEffectModel *effect;
@property (nonatomic, assign) ACCDuetLayoutSwitchType switchType;
@property (nonatomic, assign) BOOL toggled;//用户点击上下或者左右切换的标记，切换
@property (nonatomic, strong) VEComposerInfo *node;//布局面板需要的资源路径和tag信息
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, strong) ACCDuetLayoutTrackModel *trackModel;
@property (nonatomic, strong) NSString *duetLayout;

- (instancetype)initWithEffect:(IESEffectModel *)effect;
- (NSInteger)duetLayoutIndexOf:(NSString *)duetLayout;

@end

@interface ACCDuetLayoutFrameModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) NSInteger type;
@property (nonatomic, assign) CGFloat x1;
@property (nonatomic, assign) CGFloat y1;
@property (nonatomic, assign) CGFloat x2;
@property (nonatomic, assign) CGFloat y2;

+ (ACCDuetLayoutFrameModel * _Nullable)configDuetLayoutFrameModelWithString:(NSString *)layoutFrame;
+ (NSArray<NSString *> *)supportDuetLayoutFrameList;

@end

NS_ASSUME_NONNULL_END
