//
//  ACCRecordMode+LiteTheme.h
//  CameraClient-Pods-AwemeLiteCore
//
//  Created by Fengfanhua.byte on 2021/10/14.
//

#import <CreationKitArch/ACCRecordMode.h>

@interface ACCRecordMode (LiteTheme)

@property (nonatomic, assign, readonly) BOOL isStoryStyleMode;

@property (nonatomic, assign, readonly) BOOL isAdditionVideo;
@property (nonatomic, copy, nullable) BOOL(^additionIsVideoBlock)(void);

@end

