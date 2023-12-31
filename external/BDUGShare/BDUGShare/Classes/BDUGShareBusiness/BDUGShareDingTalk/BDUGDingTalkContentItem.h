//
//  BDUGDingTalkContentItem.h
//  Pods
//
//  Created by 张 延晋 on 17/01/09.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeDingTalk;

@interface BDUGDingTalkContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithTitle:(NSString * _Nullable)title
                         desc:(NSString * _Nullable)desc
                   webPageUrl:(NSString * _Nullable)webPageUrl
                   thumbImage:(UIImage * _Nullable)thumbImage
                    defaultShareType:(BDUGShareType)defaultShareType;

@end

NS_ASSUME_NONNULL_END
