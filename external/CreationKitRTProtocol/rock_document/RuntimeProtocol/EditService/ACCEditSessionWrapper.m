//
//  ACCEditSessionWrapper.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/24.
//

#import "ACCEditSessionWrapper.h"

@interface ACCEditSessionWrapper ()

@property (nonatomic, strong, readwrite) VEEditorSession *videoEditSession;

@property (nonatomic, strong, readwrite) ACCImageAlbumEditorSession *imageEditSession;

@end

@implementation ACCEditSessionWrapper

- (instancetype)initWithEditorSession:(id)editorSession
{
    self = [super init];
    
    if (self) {
        Class veClass = NSClassFromString(@"VEEditorSession");
        if (veClass && [editorSession isKindOfClass:veClass]) {
            _videoEditSession = editorSession;
        } else {
            _imageEditSession = editorSession;
        }
    }
    
    return self;
}

@end
