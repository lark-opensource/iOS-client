//
//  DVELinkageDescription.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVELinkageDescription : NSObject

@property (nonatomic, copy) NSString *linkIdentifier;
@property (nonatomic, assign) CMTime offset;

- (instancetype)initWithLinkIdentifier:(NSString *)linkIdentifier
                                offset:(CMTime)offset;

@end

NS_ASSUME_NONNULL_END
