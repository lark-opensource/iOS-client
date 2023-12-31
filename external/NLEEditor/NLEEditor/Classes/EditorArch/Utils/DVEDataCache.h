//
//  DVEDataCache.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VEAmazingFeature.h>

#define kUserParmForVEVC  @"kUserParmForVEVC"
#define kUserParmForVEVCFPS  @"kUserParmForVEVCFPS"
#define kUserParmForVEVCPresent @"kUserParmForVEVCPresent"
#define kUserParmForVEVCPresentIndex @"kUserParmForVEVCPresentIndex"

NS_ASSUME_NONNULL_BEGIN


@interface DVEDataCache : NSObject

+ (void)setExportFPSSelectIndex:(NSInteger)index;
+ (NSInteger)getExportFPSIndex;

+ (void)setExportPresentSelectIndex:(NSInteger)index;
+ (NSInteger)getExportPresentIndex;

+ (void)setExportPresent:(NSInteger)index;
+ (NSInteger)getExportPresent;

@end

NS_ASSUME_NONNULL_END
