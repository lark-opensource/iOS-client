//
//  ACCEditSessionWrapper.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/24.
//

#import <Foundation/Foundation.h>

@class ACCImageAlbumEditorSession;
@class VEEditorSession;

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditSessionWrapper : NSObject

@property (nonatomic, strong, readonly) VEEditorSession *videoEditSession;

@property (nonatomic, strong, readonly) ACCImageAlbumEditorSession *imageEditSession;

- (instancetype)initWithEditorSession:(id)editorSession;

@end

NS_ASSUME_NONNULL_END
