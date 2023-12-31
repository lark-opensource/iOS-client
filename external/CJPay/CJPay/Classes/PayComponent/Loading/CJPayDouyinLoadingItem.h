//
//  CJPayDouyinLoadingItem.h
//  Pods
//
//  Created by 易培淮 on 2021/8/16.
//

#import <Foundation/Foundation.h>
#import "CJPayTopLoadingItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDouyinLoadingItem : CJPayTopLoadingItem

@property (nonatomic, copy) NSString *logoUrl;

- (NSString *)loadingTitle;
- (NSString *)loadingIcon;

@end

NS_ASSUME_NONNULL_END
