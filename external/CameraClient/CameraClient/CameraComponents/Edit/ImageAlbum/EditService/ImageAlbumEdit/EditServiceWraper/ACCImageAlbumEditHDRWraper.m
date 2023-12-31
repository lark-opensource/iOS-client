//
//  ACCImageAlbumEditHDRWraper.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageAlbumEditHDRWraper.h"
#import "ACCImageAlbumEditorSession.h"

@interface ACCImageAlbumEditHDRWraper () <ACCEditBuildListener>

@property (nonatomic, weak) id<ACCImageAlbumEditorSessionProtocol> player;

@end

@implementation ACCImageAlbumEditHDRWraper
- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider
{
    [editSessionProvider addEditSessionListener:self];
}

- (void)onEditSessionInit:(ACCEditSessionWrapper *)editSession
{
    self.player = editSession.imageEditSession;
}

- (void)setupLensHDRModelWithFilePath:(NSString *)filePath
{
    [self.player setupLensHDRModelWithFilePath:filePath];
}

- (void)setHDREnable:(BOOL)enable
{
    [self.player setHDREnable:enable];
}

@end
