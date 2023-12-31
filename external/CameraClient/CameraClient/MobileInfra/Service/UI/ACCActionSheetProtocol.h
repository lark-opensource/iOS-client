//
//  ACCActionSheetProtocol.h
//  CameraClient
//
//  Created by Ciyou Lee on 2020/8/27.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCActionSheetProtocol;

@protocol ACCActionSheetDelegate <NSObject>

@optional
- (nullable NSString *)titleForActionSheet:(id<ACCActionSheetProtocol>)actionSheet;

- (nullable NSArray<NSString *> *)buttonTexts:(id<ACCActionSheetProtocol>)actionSheet;

- (void)actionSheet:(id<ACCActionSheetProtocol>)actionSheet didClickedButtonAtIndex:(NSInteger)index;

@end

@protocol ACCActionSheetProtocol <NSObject>

@property (nonatomic, weak) id<ACCActionSheetDelegate> delegate;

- (void)show;

@end

FOUNDATION_STATIC_INLINE id<ACCActionSheetProtocol> ACCActionSheet() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCActionSheetProtocol)];
}
