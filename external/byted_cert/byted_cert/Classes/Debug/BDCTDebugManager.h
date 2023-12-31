//
//  BDCTDebugManager.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/16.
//

#import <Foundation/Foundation.h>
#import "BytedCertManager.h"
#import "BytedCertError.h"

@class BDCTImageManager;

NS_ASSUME_NONNULL_BEGIN


@interface NSString (BDCTDebugAdditions)

- (void)bdctdebug_displayInSheetViewController;

@end


@interface BytedCertManager (OCRDebug)

@property (nonatomic, strong, readonly, nullable) BDCTImageManager *imageManager;

+ (NSData *_Nullable)imageWithType:(NSString *_Nullable)type;

@end


@interface BDCTDebugManager : NSObject

@property (nonatomic, strong) UIImagePickerController *picker;

+ (instancetype _Nullable)sharedInstance;

- (void)debugFaceLiveViewController:(NSString *_Nullable)livenessType;

- (void)debugFaceLiveViewController:(NSString *)livenessType motions:(NSString *_Nullable)motions beauty:(int)beauty completion:(void (^_Nullable)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion;

- (void)debugFaceLiveViewController:(NSString *)livenessType completion:(nullable void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion;

- (void)debugAliyunFaceLive;

- (void)debugVideoPlay;

- (void)debugVideoPlayWithURL:(NSURL *)URLString;

- (void)debugProtocolUrl;

- (void)debugNFC;
- (void)debugActionLivenessWithVideo;

@end

NS_ASSUME_NONNULL_END
