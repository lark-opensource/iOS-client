//
//  ACCRecordModeBackgroundModelProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/22.
//

#ifndef ACCRecordModeBackgroundModelProtocol_h
#define ACCRecordModeBackgroundModelProtocol_h

#import <CreationKitArch/ACCURLModelProtocol.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>

@protocol ACCRecordModeBackgroundModelProtocol <NSObject>

@property (nonatomic, assign) BOOL isColorBackground;
@property (nonatomic, copy, readonly, nullable) NSArray<AWEStoryColor *> *colors;
@property (nonatomic, copy, nullable) id<ACCURLModelProtocol> backgroundImage;
@property (nonatomic, strong, readonly, nullable) AWEStoryColor *fontColor;
@property (nonatomic, strong, readonly, nullable) AWEStoryFontModel *font;
@property (nonatomic, strong, readonly, nullable) AWEStoryColor *hintColor;

- (NSArray *)CGColors;
- (NSString *)colorString;

@end

#endif /* ACCRecordModeBackgroundModelProtocol_h */
