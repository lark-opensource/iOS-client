//
//  FBSwiftGraphElement.h
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/5/7.
//

#import "FBObjectiveCGraphElement.h"
#import "FBObjectGraphConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSiwftGetStrongReferenceProtocol <NSObject>
+ (BOOL)isSwiftInstanceWith:(id)object;
+ (NSArray *)getAllStrongRetainedReferencesOf:(id)object;
+ (NSArray *)getAllStrongRetainedReferencesOf:(id)object withConfiguration:(FBObjectGraphConfiguration *)Configuration;
@end


@protocol PropertyAndNameProtocol <NSObject>
- (NSString *)propertyName;
- (id)propertyValue;
@end

@interface FBSwiftGraphElement : FBObjectiveCGraphElement
+ (BOOL)judegeIfSwiftInstanceWith:(id)object;
@end


NS_ASSUME_NONNULL_END
