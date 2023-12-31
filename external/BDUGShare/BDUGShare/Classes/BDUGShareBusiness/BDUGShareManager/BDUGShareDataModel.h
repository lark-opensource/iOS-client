//
//  BDUGShareDataModel.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/8.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BDUGShareMethod)
{
    BDUGShareMethodDefault = 0,
    BDUGShareMethodSystem,
    BDUGShareMethodToken,
    BDUGShareMethodImage,
    BDUGShareMethodVideo,
};

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareDataItemTokenInfoModel : NSObject

@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *tip;
@property (nonatomic, copy, nullable) NSString *title;

- (BOOL)tokenInfoValide;

@end

@interface BDUGShareDataItemModel : NSObject

#pragma mark - origin server data

@property (nonatomic, copy, nullable) NSString *channel;
@property (nonatomic, copy, nullable) NSString *method;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *desc;
@property (nonatomic, copy, nullable) NSString *imageUrl;
@property (nonatomic, copy, nullable) NSString *thumbImageUrl;
@property (nonatomic, copy, nullable) NSString *shareUrl;
@property (nonatomic, copy, nullable) NSString *videoURL;
@property (nonatomic, strong, nullable) BDUGShareDataItemTokenInfoModel *tokenInfo;
@property (nonatomic, copy, nullable) NSString *appId;

#pragma mark - processed data

@property (nonatomic, assign) BDUGShareMethod shareMethod;
@property (nonatomic, copy, nullable) NSString *sharePlatformActivityType;

+ (NSDictionary *)inServerControllItemTypeDict;

+ (NSDictionary *)channelTypeDict;

@end

@interface BDUGShareDataModel : NSObject

@property (nonatomic, strong, nullable) NSArray <BDUGShareDataItemModel *> *infoList;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
