//
//  ACCTextExtraProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/7.
//

#ifndef ACCTextExtraProtocol_h
#define ACCTextExtraProtocol_h

#import "ACCPublishRepositoryElementProtocols.h"

typedef NS_ENUM(NSInteger, ACCTextExtraType);

typedef NS_ENUM(NSInteger, ACCTextExtraSubType);

@protocol ACCTextExtraProtocol <NSObject, NSCopying>

@property (nonatomic, assign) NSInteger start; // Left closed, right open, [), length = end - start
@property (nonatomic, assign) NSInteger end; // Left closed, right open, [), length = end - start
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *secUserID;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *awemeId;
@property (nonatomic, copy) NSString *hashtagName;
@property (nonatomic, assign, readonly) ACCTextExtraType accType;
@property (nonatomic, assign, readonly) ACCTextExtraSubType accSubtype;
@property (nonatomic, assign) NSInteger followStatus;

- (NSInteger)length;
- (void)setLength:(NSInteger)length;

@end

#endif /* ACCTextExtraProtocol_h */
