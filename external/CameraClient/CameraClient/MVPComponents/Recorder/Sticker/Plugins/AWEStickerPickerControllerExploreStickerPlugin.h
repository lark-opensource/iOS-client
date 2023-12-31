//
//  AWEStickerPickerControllerExploretickerPlugin.h
//  Indexer
//
//  Created by wanghongyu on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerControllerPluginProtocol.h>
#import "AWEStickerViewLayoutManagerProtocol.h"

@class ACCPropViewModel;
@interface AWEStickerPickerControllerExploreStickerPlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, weak, nullable) id<AWEStickerViewLayoutManagerProtocol> layoutManager;

- (instancetype)initWithServiceProvider:(nonnull id<IESServiceProvider>)serviceProvider
                              viewModel:(nonnull ACCPropViewModel *)viewModel;


@end

