//
//  ACCStickerPannelDataHelper.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCStickerPannelDataResponseStatus) {
    ACCStickerPannelDataResponseStatusNormal,
    ACCStickerPannelDataResponseStatusRecommendFailed,
    ACCStickerPannelDataResponseStatusLokiFailed,
};

@class IESInfoStickerModel, IESInfoStickerCategoryModel;

@interface ACCStickerPannelDataRequest : NSObject

@property (nonatomic, copy) NSString *uploadURI;

@property (nonatomic, copy) NSString *creationId;

@property (nonatomic, copy) NSString *customPanelName;

@property (nonatomic, copy) NSArray<NSString *> *filterTags;

@end

@interface ACCStickerPannelDataResponse : NSObject

@property (nonatomic, assign) ACCStickerPannelDataResponseStatus status;

@property (nonatomic, copy) NSArray<IESInfoStickerModel *> *effects;

@property (nonatomic, copy) NSArray<IESInfoStickerCategoryModel *> *categories;

@end

@interface ACCStickerPannelDataHelper : NSObject

+ (void)downloadInfoSticker:(IESInfoStickerModel *)sticker trackParams:(NSDictionary *)trackParams progressBlock:(void(^)(CGFloat progress))progressBlock completion:(void(^)(NSError *, NSString *))completion;

+ (void)fetchInfoStickerPannelData:(ACCStickerPannelDataRequest *)params completion:(void(^)(BOOL, ACCStickerPannelDataResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
