//
//  BDUGShareBaseContentItem.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/16.
//

#import <Foundation/Foundation.h>
#import "BDUGActivityContentItemProtocol.h"

@class BDUGShareDataItemModel;

NS_ASSUME_NONNULL_BEGIN

@interface BDUGShareBaseContentItem : NSObject <BDUGActivityContentItemShareProtocol>

//埋点用，业务方不用关心。
@property (nonatomic, copy, nullable) NSString *panelType;

//client extra
@property (nonatomic, strong, nullable) NSDictionary *clientExtraData;

@property (nonatomic, weak, nullable) UIViewController *presentVC;

- (void)convertfromModel:(BDUGShareDataItemModel * _Nullable)model;

- (void)convertFromAnotherContentItem:(BDUGShareBaseContentItem * _Nullable)contentItem;

- (BOOL)imageShareValid;

- (BOOL)videoShareValid;

@end

NS_ASSUME_NONNULL_END
