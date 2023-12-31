//
//  ACCImageAlbumEditorMacro.h
//  CameraClient
//
//  Created by imqiuhang on 2021/2/25.
//

#ifndef ACCImageAlbumEditorMacro_h
#define ACCImageAlbumEditorMacro_h

#define  ACCImageEditModeViewUsingCustomerInitOnly \
- (instancetype)init NS_UNAVAILABLE; \
+ (instancetype)new  NS_UNAVAILABLE; \
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE; \
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE; \


#define ACCImageEditModeAssertUnsupportFeature \
ACCImageEditModeAssertUnsupportFeatureForReason(@"");

#define ACCImageEditModeAssertUnsupportFeatureForReason(fmt, ...) \
NSAssert(NO, @"unsupported feature (%s) for image eidt mode, please check, reason: %@", __func__, [NSString stringWithFormat:fmt, ##__VA_ARGS__]);

#endif /* ACCImageAlbumEditorMacro_h */
