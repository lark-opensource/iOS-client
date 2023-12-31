//
//  AWELyricPattern.h
//  Aweme
//
//  Created by Nero on 2019/1/9.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWELyricPattern : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *timeId;
@property (nonatomic, copy) NSString *lyricText;

@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

@end

NS_ASSUME_NONNULL_END
