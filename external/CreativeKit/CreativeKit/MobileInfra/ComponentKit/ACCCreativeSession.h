//
//  ACCCreativeSession.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/8/19.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESStaticContainer.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCreativeSession : NSObject

@property (nonatomic, copy, readonly) NSString *createId;
@property (nonatomic, copy, readonly) NSArray *holders;

- (instancetype)initWithCreateId:(NSString *)createId;

- (void)addHolder:(id)holder;

@end

NS_ASSUME_NONNULL_END
