//
//  BDUGCopyContentItem.h
//  Pods
//
//  Created by 延晋 张 on 16/6/7.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityContentItemTypeCopy;

@interface BDUGCopyContentItem : BDUGShareBaseContentItem

@property (nonatomic, copy, nullable) NSString *specificCopyString;

- (instancetype)initWithDesc:(NSString *)desc;

@end

NS_ASSUME_NONNULL_END
