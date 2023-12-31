//
//  BDUGQQZoneContentItem.h
//  Pods
//
//  Created by 张 延晋 on 16/06/03.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeQQZone;

@interface BDUGQQZoneContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUr
                   thumbImage:(UIImage * _Nullable)thumbImage
                     imageUrl:(NSString * _Nullable)imageUrl
                     shareTye:(BDUGShareType)defaultShareType;;

@end

NS_ASSUME_NONNULL_END
