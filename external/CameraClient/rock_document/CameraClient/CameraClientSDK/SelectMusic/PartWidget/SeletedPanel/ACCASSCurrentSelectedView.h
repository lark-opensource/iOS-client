//
//  ACCASSCurrentSelectedView.h
//  CameraClient
//
//  Created by Chen Long on 2020/9/15.
//

#import <CreationKitArch/ACCMusicModelProtocol.h>

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>


NS_ASSUME_NONNULL_BEGIN

@interface ACCASSCurrentSelectedView : UIView

@property (nonatomic, copy, nullable) BOOL (^enableClipBlock)(id<ACCMusicModelProtocol> music);
@property (nonatomic, copy, nullable) void (^didClickClipButton)(id<ACCMusicModelProtocol> music);
@property (nonatomic, copy, nullable) void (^didClickDeleteButton)(id<ACCMusicModelProtocol> music);
@property (nonatomic, copy, nullable) void (^didStartPlayMusic)(void);

@property (nonatomic, assign) HTSAudioRange audioRange;

- (instancetype)initWithMusic:(id<ACCMusicModelProtocol>)music NS_DESIGNATED_INITIALIZER;

- (void)stop;
- (void)updateCancelButtonToDistouchableColor;
- (void)hideClipActionBtn;
- (void)hideDeleteActionBtn;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
