//
//  BDDYCPatchConfigProtocol.h
//  BDDynamically
//
//  Created by hopo on 2019/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDQuaterbackConfigProtocol <NSObject>
@required
@property (nonatomic, copy) NSArray *channelList;
@property (nonatomic, copy) NSArray *appVersionList;
@property (nonatomic, copy) NSDictionary *osVersionRange;
@property (nonatomic, copy) NSString *loadEnable;
@property (nonatomic, assign) int hookType;
@end

NS_ASSUME_NONNULL_END
