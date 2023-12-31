//
//  ACCMusicFontProtocol.h
//  CameraClient
//
//  Created by 夏德群 on 2021/6/16.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicFontProtocol <NSObject>

- (UIFont *)systemFontOfSize:(CGFloat)fontSize;
- (UIFont *)systemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight;
- (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize;

- (CGFloat)currentScale;
- (BOOL)musicBigFontModeOn;

@end

FOUNDATION_STATIC_INLINE id<ACCMusicFontProtocol> MusicFont() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCMusicFontProtocol)];
}

FOUNDATION_STATIC_INLINE CGFloat MusicFontScale() {
    return [MusicFont() currentScale];
}

FOUNDATION_STATIC_INLINE BOOL MusicBigFontModeOn() {
    return [MusicFont() musicBigFontModeOn];
}

NS_ASSUME_NONNULL_END
