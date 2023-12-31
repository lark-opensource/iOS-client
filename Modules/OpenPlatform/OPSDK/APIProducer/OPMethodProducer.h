//
//  OPMethodProducter.h
//  OPSDK
//
//  Created by Nicholas Tau on 2020/12/10.
//

#import <Foundation/Foundation.h>
@class OPArguement;
NS_ASSUME_NONNULL_BEGIN

@interface OPMethodProducer : NSObject
- (instancetype)initWithJsapi:(NSString *)jsName
                    className:(NSString *)className
                   methodName:(NSString *)methodName;
@property(nonatomic, copy, readonly)  NSString  *jsName;
@property(nonatomic, copy, readonly)  NSString  *objectClsName;
@property(nonatomic, copy, readonly)  NSString  *objectMethodName;
@property(nonatomic, assign, readonly)  SEL     targetSel;
//arguments which mapping from paramters map, but with a specific type already
@property(nonatomic, copy, readonly) NSArray<OPArguement *>  *argumentList;

-(void)invokeWithTarget:(id)target andParams:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END
