//
//  ACCRecordLayoutGuideProtocol.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecordLayoutGuideProtocol <NSObject>

- (CGFloat)containerHeight;

- (CGFloat)containerWidth;

- (CGFloat)recordButtonWidth;

- (CGFloat)recordButtonHeight;

- (CGFloat)recordButtonCenterY;

- (CGFloat)recordButtonBottomOffset;

@optional

- (CGFloat)recordButtonTopY;

- (CGFloat)selectMusicButtonCenterY;

- (CGFloat)selectMusicButtonHeight;

@end

NS_ASSUME_NONNULL_END
