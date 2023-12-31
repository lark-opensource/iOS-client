//
//  AWEVideoPublishViewModel+FilterEdit.h
//  Aweme
//
//  Created by Liu Bing on 5/11/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface AWEVideoPublishViewModel (FilterEdit)

- (NSDictionary *)videoFragmentInfoDictionary;
- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod;
- (void)trackPostEvent:(NSString *)event enterMethod:(NSString *)enterMethod extraInfo:(NSDictionary *)extraInfo;

- (void)trackPostEvent:(NSString *)event
           enterMethod:(NSString *)enterMethod
             extraInfo:(NSDictionary *)extraInfo
           isForceSend:(BOOL)isForceSend;

- (BOOL)isStory;

@end
