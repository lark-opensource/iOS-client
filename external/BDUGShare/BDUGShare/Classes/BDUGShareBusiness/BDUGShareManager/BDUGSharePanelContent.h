//
//  BDUGSharePanelContent.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/21.
//

#import <Foundation/Foundation.h>
#import "BDUGShareBaseContentItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDUGSharePanelContent : NSObject

@property (nonatomic, strong, nullable) BDUGShareBaseContentItem * shareContentItem;

@property (nonatomic, copy, nullable) NSString *panelID;

@property (nonatomic, copy, nullable) NSString *resourceID;

@property (nonatomic, strong, nullable) NSDictionary *requestExtraData;

@property (nonatomic, strong, nullable) NSDictionary *clientExtraData;

@property (nonatomic, assign) BOOL disableRequestShareInfo;

@property (nonatomic, assign) BOOL useRequestCache;

#pragma mark - about panel

@property (nonatomic, copy, nullable) NSString *panelClassString;

@property (nonatomic, copy, nullable) NSString *cancelBtnText;

@property (nonatomic, assign) BOOL supportAutorotate;
@property (nonatomic, assign) UIInterfaceOrientationMask supportOrientation;

@end

NS_ASSUME_NONNULL_END
