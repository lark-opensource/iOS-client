//
//  DVELiteVideoClipPlayPlugin.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/24.
//

#import <Foundation/Foundation.h>
#import "DVEPreviewPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DVELiteVideoClipPlayPluginDelegate <NSObject>

- (void)didVideoClipPlayTap:(BOOL)isPlay;

@end

@interface DVELiteVideoClipPlayPlugin : UIView<DVEPreviewPluginProtocol>

@property (nonatomic, weak) id<DVELiteVideoClipPlayPluginDelegate> delegate;

- (void)updatePlayIconHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
