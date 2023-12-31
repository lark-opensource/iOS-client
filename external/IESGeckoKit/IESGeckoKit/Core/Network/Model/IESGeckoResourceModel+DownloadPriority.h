//
//  IESGeckoResourceModel+DownloadPriority.h
//  IESGeckoKit
//
//  Created by liuhaitian on 2021/10/19.
//

#import <Foundation/Foundation.h>

#import "IESGeckoResourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdResourceModel (DownloadPriority)

- (void)updateDownloadPriorityWithDownloadPrioritiesMap:(NSDictionary<NSString *, NSNumber *> *)downloadPrioritiesMap;

@end

NS_ASSUME_NONNULL_END
