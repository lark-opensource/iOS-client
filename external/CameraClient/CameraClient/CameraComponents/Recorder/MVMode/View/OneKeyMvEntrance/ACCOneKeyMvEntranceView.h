//
//  ACCOneKeyMvEntranceView.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/11.
//

#import <UIKit/UIKit.h>

@protocol ACCOneKeyMvEntranceViewDelegate <NSObject>

@optional
- (void)jumpToAlbumPage:(nullable NSString *)enterMethod;

@end

@interface ACCOneKeyMvEntranceView : UIView

@property (nonatomic, weak, nullable) id<ACCOneKeyMvEntranceViewDelegate> delegate;

@end
