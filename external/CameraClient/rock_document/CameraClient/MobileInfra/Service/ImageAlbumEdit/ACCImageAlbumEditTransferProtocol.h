//
//  ACCImageAlbumEditTransferProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/20.
//

#import <Foundation/Foundation.h>
#import "AWEEditPageProtocol.h"
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@protocol ACCImageAlbumEditTransferProtocol <NSObject>

- (UIViewController<AWEEditPageProtocol> *)videoEditorWithModel:(AWEVideoPublishViewModel *)model;

@end

FOUNDATION_STATIC_INLINE id<ACCImageAlbumEditTransferProtocol> ACCImageAlbumEditTransfer() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCImageAlbumEditTransferProtocol)];
}



NS_ASSUME_NONNULL_END
