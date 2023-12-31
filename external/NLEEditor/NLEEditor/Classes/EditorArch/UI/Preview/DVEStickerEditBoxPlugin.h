//
//  DVEEditBoxPlugin.h
//  NLEEditor
//
//  Created by pengzhenhuan on 2022/1/5.
//

#import <Foundation/Foundation.h>
#import "DVEEditBoxPluginProtocol.h"
#import <DVETrackKit/DVETransformEditView.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEStickerEditBoxPlugin : NSObject<DVEEditBoxPluginProtocol, DVETransformEditViewDelegate>

- (instancetype)initWithVCContext:(DVEVCContext *)vcContext
                         editView:(DVETransformEditView *)editView;

@end

NS_ASSUME_NONNULL_END
