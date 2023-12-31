//
//  ACCCreativePathManagable.h
//  CreativeKit
//
//  Created by yangying on 2021/8/21.
//

#ifndef ACCCreativePathManagable_h
#define ACCCreativePathManagable_h
#import <IESInject/IESInject.h>
#import "ACCServiceLocator.h"
#import "ACCCreativeSession.h"
#import "ACCSessionServiceContainer.h"

@protocol ACCCreativePathManagable <NSObject>

- (ACCSessionServiceContainer *)sessionContainerWithCreateId:(NSString *)createId;

- (ACCSessionServiceContainer *)sessionContainerWithCreateId:(NSString *)createId saveHolder:(id)holder;

- (NSArray <ACCSessionServiceContainer *>*)allSessionContainers;

@end

FOUNDATION_STATIC_INLINE id<ACCCreativePathManagable> ACCCreativePath() {
    return IESRequiredInline(ACCBaseServiceProvider(), ACCCreativePathManagable);
}

#endif /* ACCCreativePathManagable_h */
