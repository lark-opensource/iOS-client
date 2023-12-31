//
//  ACCPropRecommendMusicView.h
//  CameraClient
//
//  Created by xiaojuan on 2020/8/5.
//

#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropRecommendMusicView : UIView
@property (nonatomic, strong, readonly) UIButton *confirmButton;
@property (nonatomic, assign) BOOL hasTappedOnce; //If the view(bubble) has been touched once, it will never disappear until user tap screen to discard it.

- (void)updateWithMusicModel:(id<ACCMusicModelProtocol>)model bubbleTitle:(NSString *)bubbleTitle Image:(UIImage *)image creationID:(NSString *)creationID;

- (void)viewAppearEvent;

- (void)viewDidDismissEvent;

@end

NS_ASSUME_NONNULL_END
