//
//  ACCEditWrapper.h
//  CameraClient
//
//  Created by haoyipeng on 2020/8/13.
//

#import <Foundation/Foundation.h>
#import "ACCEditSessionBuilderProtocol.h"
#import <TTVideoEditor/VEEditorSession.h>

NS_ASSUME_NONNULL_BEGIN

@class VEEditorSession;

@protocol ACCEditWrapper <NSObject>

- (void)setEditSessionProvider:(id<ACCEditSessionProvider>)editSessionProvider;

@end

NS_ASSUME_NONNULL_END
