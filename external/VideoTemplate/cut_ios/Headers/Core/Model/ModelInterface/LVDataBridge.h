//
//  LVDataBridge.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/25.
//

#import <Foundation/Foundation.h>
#import "LVDataBridgeResult.h"
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSData* LVJsonData;

@interface LVDataBridge : NSObject

- (LVDataBridgeResult<LVMediaDraft *> *)forwardBridge:(LVJsonData)json atPath:(NSString *)path;

- (LVDataBridgeResult<LVJsonData> *)backwardBridge:(LVMediaDraft *)draft;

- (void)refineDraft:(LVMediaDraft *)draft rootPath:(NSString *)rootPath;
- (void)refineCoverDraft:(LVCoverDraft *)draft rootPath:(NSString *)rootPath;


@end

NS_ASSUME_NONNULL_END
