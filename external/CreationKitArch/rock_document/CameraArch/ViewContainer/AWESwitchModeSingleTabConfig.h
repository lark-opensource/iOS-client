//
//  AWESwitchModeSingleTabConfig.h
//  CameraClient
//
//  Created by geekxing on 2019/12/1.
//

#import <Foundation/Foundation.h>
#import "AWESwitchRecordModelDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWESwitchModeSingleTabConfig : NSObject

@property (nonatomic, assign) NSInteger recordModeId;
@property (nonatomic, assign) BOOL showRedDot;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *imageName; ///< local
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSArray<NSString *> *imageURLArray; ///< remote

@end

NS_ASSUME_NONNULL_END
