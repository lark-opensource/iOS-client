//
//  AWEStickerPickerControllerSecurityTipsPlugin.h
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/27.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"
#import "AWEStickerViewLayoutManagerProtocol.h"

@interface AWEStickerPickerControllerSecurityTipsPlugin : NSObject<AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, weak, nullable) id<AWEStickerViewLayoutManagerProtocol> layoutManager;

@end
