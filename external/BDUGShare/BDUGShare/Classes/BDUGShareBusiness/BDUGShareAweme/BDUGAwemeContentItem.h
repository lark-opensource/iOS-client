//
//  BDUGAwemeContentItem.h
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeAweme;

@interface BDUGAwemeContentItem : BDUGShareBaseContentItem

/**
 透传参数
 */
@property (nonatomic, strong, nullable) NSDictionary *extraInfo;

/**
 透传DouyinOpenSDKShareReq的参数。
 */
@property (nonatomic, copy, nullable) NSString *state;

/// 对应视频的 #话题 功能，需要额外申请权限，字符长度不能超过 35
@property (nonatomic, copy, nullable) NSString *hashtag;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUrl
                   thumbImage:(UIImage * _Nullable)thumbImage
                     imageUrl:(NSString * _Nullable)imageUrl
                     shareTye:(BDUGShareType)defaultShareType;

@end

NS_ASSUME_NONNULL_END
