//
//  BDUGSharePanelContent.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/10/21.
//

#import "BDUGSharePanelContent.h"

@implementation BDUGSharePanelContent

- (instancetype)init
{
    self = [super init];
    if (self) {
        //默认使用服务端数据。
        _disableRequestShareInfo = NO;
        //默认使用请求缓存。
        _useRequestCache = YES;
        
        _supportAutorotate = YES;
        _supportOrientation = UIInterfaceOrientationMaskAll;
    }
    return self;
}

- (void)setShareContentItem:(BDUGShareBaseContentItem *)shareContentItem {
    _shareContentItem = shareContentItem;
    if (shareContentItem.clientExtraData == nil) {
        shareContentItem.clientExtraData = self.clientExtraData;
    }
}

- (void)setClientExtraData:(NSDictionary *)clientExtraData {
    _clientExtraData = clientExtraData;
    if (self.shareContentItem.clientExtraData == nil) {
        self.shareContentItem.clientExtraData = clientExtraData;
    }
}

@end
