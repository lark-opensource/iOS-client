//
//  ACCSubtitleActionSheetProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by admin on 2020/12/14.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

typedef NS_ENUM(NSInteger, ACCSubtitleActionSheetButtonType) {
    ACCSubtitleActionSheetButtonNormal,
    ACCSubtitleActionSheetButtonHighlight,
    ACCSubtitleActionSheetButtonSubtitle
};

@protocol ACCSubtitleActionSheetProtocol;

@protocol ACCSubtitleActionSheetDelegate <NSObject>

@optional

- (nullable NSString *)titleForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet;

- (nullable NSArray<NSString *> *)buttonTextsForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet;

- (nullable NSArray<NSNumber *> *)buttonTypesForSubtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet;

- (void)subtitleActionSheet:(id<ACCSubtitleActionSheetProtocol>)actionSheet didClickedButtonAtIndex:(NSInteger)index;

@end

@protocol ACCSubtitleActionSheetProtocol <NSObject>

@property (nonatomic, assign) BOOL hasTitle;
@property (nonatomic, weak) id<ACCSubtitleActionSheetDelegate> delegate;

- (void)show;

@end

FOUNDATION_STATIC_INLINE id<ACCSubtitleActionSheetProtocol> ACCSubtitleActionSheet() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCSubtitleActionSheetProtocol)];
}
