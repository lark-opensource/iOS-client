//
//  AWECustomStickerLimitConfig.h
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/16.
//

#import <Foundation/Foundation.h>
#import <Mantle/MTLModel.h>
#import <Mantle/MTLJSONAdapter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECustomStickerLimitConfig : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) CGFloat gifSizeLimit;

@property (nonatomic, assign) CGFloat gifMaxLimit;

@property (nonatomic, assign) CGFloat uploadWidthLimit;

@property (nonatomic, assign) CGFloat uploadHeightLimit;

@end

NS_ASSUME_NONNULL_END
