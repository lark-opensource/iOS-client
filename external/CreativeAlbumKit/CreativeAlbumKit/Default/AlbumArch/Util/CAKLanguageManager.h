//
//  CAKLanguageManager.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/10.
//

#import <Foundation/Foundation.h>

#define CAKLocalizedString(key, defaultTrans) [[CAKLanguageManager sharedInstance] translatedStringForKey:key defaultTranslation:defaultTrans]

@interface CAKLanguageManager : NSObject

@property (nonatomic, strong, readonly, nullable) NSString *currentLanguageCode;

+ (instancetype _Nonnull)sharedInstance;

- (void)setCurrentLanguageCode:(NSString * _Nullable)currentLanguageCode;

- (NSString * _Nullable)translatedStringForKey:(NSString * _Nullable)key defaultTranslation:(NSString * _Nullable)defaultTranslation;

@end

