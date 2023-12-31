//
//  BDUGWechatTimelineContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeWechatTimeLine;

@interface BDUGWechatTimelineContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSString *videoString;
@property (nonatomic, copy, nullable) NSDictionary *extraInfo;

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUrl
                   thumbImage:(UIImage * _Nullable)thumbImage
                    defaultShareType:(BDUGShareType)defaultShareType;

@end

NS_ASSUME_NONNULL_END
