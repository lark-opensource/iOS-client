//
//  TTBridgeAuthInfoViewController.h
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/13.
//

#import <TTDebugCore/SSDebugViewControllerBase.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (BDPiperAuthDebug)

- (NSString *)readableString;

@end

@interface NSDictionary (BDPiperAuthDebug)

- (NSString *)readableString;

@end

@interface TTBridgeAuthCellItem : STTableViewCellItem

@property (nonatomic, copy, readonly) NSString *channelName;
@property (nonatomic, copy, readonly) NSString *domainName;

- (instancetype)initWithChannelName:(NSString *)channelName domainName:(NSString *)domainName target:(id)target action:(__nullable SEL)action;

@end

@interface TTBridgeAuthInfoViewController : SSDebugViewControllerBase

@property (nonatomic, copy) NSDictionary *json;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *channels;

- (instancetype)initWithTitle:(NSString *)title JSON:(NSDictionary *)json accessKey:(NSString *)accessKey;

- (void)loadDataSource;

@end

NS_ASSUME_NONNULL_END
