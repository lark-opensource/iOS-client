//
//  BDUGToutiaoContentItem.h
//  TTShareService
//
//  Created by chenjianneng on 2019/3/15.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeShareToutiao;

@interface BDUGToutiaoContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSString *postExtra;

@end

NS_ASSUME_NONNULL_END
