//
//  ACCTextRecommendModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/8/1.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

typedef NS_OPTIONS(NSUInteger, AWEModernTextRecommendMode) {
    AWEModernTextRecommendModeNone = 0,
    AWEModernTextRecommendModeLib = 1,
    AWEModernTextRecommendModeRecommend = 2,
    AWEModernTextRecommendModeBoth = 3
};

@interface ACCTextStickerRecommendItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSNumber *titleId; // 内容id
@property (nonatomic, copy, nullable) NSString *content; // 推荐返回的具体内容
@property (nonatomic, assign) BOOL exposured;

@end

@interface ACCTextStickerLibItem : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy, nullable) NSArray<NSString *> *titles;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, assign) BOOL exposured;

@end
