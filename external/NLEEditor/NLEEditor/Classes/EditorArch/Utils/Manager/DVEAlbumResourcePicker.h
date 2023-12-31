//
//  DVEAlbumResourcePicker.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/23.
//

#if ENABLE_DVEALBUM

#import <Foundation/Foundation.h>
#import "DVEVCContext.h"
#import "DVEAlbumResourcePickerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEAlbumResourcePicker : NSObject<DVEResourcePickerProtocol>

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext;

@end

NS_ASSUME_NONNULL_END

#endif
