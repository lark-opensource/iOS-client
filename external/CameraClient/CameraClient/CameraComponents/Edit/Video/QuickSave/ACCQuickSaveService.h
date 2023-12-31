//
//  ACCQuickSaveService.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liyingpeng on 2021/9/24.
//

#ifndef ACCQuickSaveService_h
#define ACCQuickSaveService_h

typedef NS_ENUM(NSInteger, ACCEditQuickSaveStyle) {
    ACCEditQuickSaveStyleNone = 0,
    ACCEditQuickSaveStyleDraft = 1,
    ACCEditQuickSaveStylePrivate = 2,
    ACCEditQuickSaveStyleAlbum = 3
};

@protocol ACCQuickSaveSubscriber <NSObject>

- (void)willTriggerQuickSaveAction;

@end

@protocol ACCQuickSaveService <NSObject>

- (void)addSubscriber:(nonnull id<ACCQuickSaveSubscriber>)subscriber;
- (void)notifywillTriggerQuickSaveAction;

- (BOOL)shouldDisableQuickSave;

@end

#endif /* ACCQuickSaveService_h */
