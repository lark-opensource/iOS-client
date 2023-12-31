//
//  BDUGSMSContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeSMS;

@interface BDUGSMSContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSDictionary *callbackUserInfo;

- (instancetype)initWithDesc:(NSString *)desc;

@end

NS_ASSUME_NONNULL_END
