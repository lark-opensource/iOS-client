//
//  EMAPluginImagePreviewHandler.h
//  EEMicroAppSDK
//
//  Created by lilun.ios on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPPluginManagerAdapter/BDPJSBridgeBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAPluginImagePreviewHandler : NSObject

@property (nonatomic, strong, nonnull) BDPUniqueID *uniqueID;
@property (nonatomic, strong, nonnull) UIViewController *controller;

- (instancetype)initWithUniqueID:(nonnull BDPUniqueID *)uniqueID
                      controller:(nonnull UIViewController *)controller;

- (void)previewImageWithParam:(nonnull NSDictionary *)param
                     callback:(nonnull BDPJSBridgeCallback)callback;
+ (void)handelQRCode:(NSString *)qrCode fromController:(UIViewController *)controller uniqueID:(BDPUniqueID*)uniqueID;

@end

NS_ASSUME_NONNULL_END
