//
//  NSMutableDictionary+RepositoryContainer.h
//  CameraClient-Pods-Aweme
//
//  Created by Charles on 2020/8/19.
//

#import <Foundation/Foundation.h>

@class AWEVideoPublishViewModel;


@interface NSMutableDictionary (RepositoryContainer)

/// set a model to dic model by it's class,
/// fail if extesionModel is nil.
- (BOOL)acc_setExtensionModelByClass:(id)extensionModel;

- (void)acc_removeExtensionModel:(Class)modelClass;

- (id)acc_extensionModelOfClass:(Class)modelClass;

/// return the first element model that conform to protocol
- (id)acc_extensionModelOfProtocol:(Protocol *)protocol;

- (NSMutableDictionary *)acc_deepCopyExtensionModels;

- (void)acc_enumerateExtensionModels:(BOOL)needCopy requireProtocol:(Protocol *)protocol requireSelector:(SEL)sel block:(void (^)(NSString *clzStr, id model, BOOL *stop))block;

@end

