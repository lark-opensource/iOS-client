//
//  BDUGZhiFuBaoContentItem.h
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeZhiFuBao;

@interface BDUGZhiFuBaoContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUrl
                   thumbImage:(UIImage * _Nullable)thumbImage
                     imageUrl:(NSString * _Nullable)imageUrl
                     shareTye:(BDUGShareType)defaultShareType;

@end

NS_ASSUME_NONNULL_END
