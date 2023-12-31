//
//  DVECoreImportServiceProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/23.
//

#import <Foundation/Foundation.h>
#import "DVECoreProtocol.h"
#import "DVEResourcePickerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVECoreImportServiceProtocol <DVECoreProtocol>

// 点击 + 号
- (void)addResources:(NSArray<id<DVEResourcePickerModel>> *)resources;

- (void)addNLEMainVideoWithResources:(NSArray<id<DVEResourcePickerModel>> *)resources commit:(BOOL)commit;

// 画中画
- (NLETrackSlot_OC *)addSubTrackResource:(id<DVEResourcePickerModel>)resource;

// 替换
- (void)replaceResourceForSlot:(NLETrackSlot_OC *)slot
                 albumResource:(id<DVEResourcePickerModel>)albumResource;

@end

NS_ASSUME_NONNULL_END
