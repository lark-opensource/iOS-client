//
//  BDUGZhiFuBaoActivity.h
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import <Foundation/Foundation.h>
#import "BDUGActivityProtocol.h"
#import "BDUGZhiFuBaoContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypePostToZhiFuBao;

@interface BDUGZhiFuBaoActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong, nullable) BDUGZhiFuBaoContentItem * contentItem;

@end

NS_ASSUME_NONNULL_END
