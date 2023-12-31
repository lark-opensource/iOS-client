//
//  ACCCutSameStylePreviewFragment.h
//  CameraClient-Pods-Aweme
//
//  Created by xulei on 2020/5/19.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCutSameStylePreviewFragmentProtocol <NSObject>

@property (nonatomic, assign) CMTime start;
@property (nonatomic, assign) CMTime duration;//config by template or loki,means how long did the fragment should crop
@property (nonatomic, assign) CGFloat lowerLeftX;//ratio
@property (nonatomic, assign) CGFloat lowerLeftY;
@property (nonatomic, assign) CGFloat lowerRightX;
@property (nonatomic, assign) CGFloat lowerRightY;
@property (nonatomic, assign) CGFloat upperLeftX;
@property (nonatomic, assign) CGFloat upperLeftY;
@property (nonatomic, assign) CGFloat upperRightX;
@property (nonatomic, assign) CGFloat upperRightY;

@end

NS_ASSUME_NONNULL_END
