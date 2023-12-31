//
//  TTBridgeAuthInfoDiffViewController.h
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/21.
//

#import "TTBridgeAuthInfoViewController.h"

NS_ASSUME_NONNULL_BEGIN

// AuthInfo's diff status in Gecko compared with the builtin authInfo.
typedef NS_ENUM(NSInteger, TTBridgeAuthInfoDiffStatus) {
    TTBridgeAuthInfoNewAdded,
    TTBridgeAuthInfoDeleted,
    TTBridgeAuthInfoUpdated,
};

@interface TTBridgeAuthInfoDiffCellItem : TTBridgeAuthCellItem

- (instancetype)initWithChannelName:(NSString *)channelName domainName:(NSString *)domainName status:(NSNumber *)status target:(id)target action:(__nullable SEL)action;

@end


@interface TTBridgeAuthInfoDiffViewController : TTBridgeAuthInfoViewController

- (instancetype)initWithTitle:(NSString *)title JSON:(NSDictionary *)json ComparedJSON:(NSDictionary *)comparedJson accessKey:(NSString *)accessKey;

- (void)loadDataSource;

@end

NS_ASSUME_NONNULL_END
