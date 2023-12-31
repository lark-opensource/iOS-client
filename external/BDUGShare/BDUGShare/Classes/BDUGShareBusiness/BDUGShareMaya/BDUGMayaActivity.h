//
//  TTShareMYActivity.h
//  TTShareService
//
//  Created by chenjianneng on 2019/3/15.
//

#import "BDUGActivityProtocol.h"
#import "BDUGMayaContentItem.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const BDUGActivityTypeShareMaya;

@interface BDUGMayaActivity : NSObject <BDUGActivityProtocol>

@property (nonatomic, strong) BDUGMayaContentItem *contentItem;

@end

NS_ASSUME_NONNULL_END
