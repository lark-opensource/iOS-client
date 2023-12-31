//
//  AWETextStickerViewDefine.h
//  CameraClient
//
//  Created by imqiuhang on 2021/3/18.
//

#ifndef AWETextStickerViewDefine_h
#define AWETextStickerViewDefine_h

#define  AWETextStcikerViewUsingCustomerInitOnly \
- (instancetype)init NS_UNAVAILABLE; \
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE; \
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE; \
+ (instancetype)new NS_UNAVAILABLE;


#endif /* AWETextStickerViewDefine_h */
