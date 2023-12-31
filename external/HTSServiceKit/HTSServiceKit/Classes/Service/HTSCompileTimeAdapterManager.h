//
//  HTSCompileTimeAdapterManager.h
//  HTSServiceKit-Pods-Aweme
//
//  Created by chenxiancai on 2021/5/11.
//

#import "HTSCompileTimeMessageManager.h"
#import "HTSMessageCenter.h"

#define HTS_DECLARE_SUBSCRIBER(INDEX,CONTEXT,ARG)\
- (id <ARG>)a##ARG;

#define HTS_GET_SUBSCRIBER(INDEX,CONTEXT,ARG)\
- (id <ARG>)a##ARG {return (id<ARG>)safe_publish_message_in_pair(self, @protocol(ARG));}\
+ (Class <ARG>)a##ARG##Class {return (Class<ARG>)NSClassFromString([NSString stringWithUTF8String:#ARG]);}

/*
Example:
     @implementation AWEAwemePlayInteractionInteractorLiteAdapter
     HTSAssociateAdapters(AWEAwemePlayInteractionInteractorPrivateProtocol,
                         AWEAwemePlayInteractionInteractorCommonAdapter,
                         AWEAwemePlayInteractionInteractorLiteAdapter) {
         return [[AWEAwemePlayInteractionInteractorLiteAdapter alloc] init];
     }
 
Then: use [self weakTarget] to get weak target
*/
#define HTSAssociateAdapters(_target_protocol_, ...) \
- (id<_target_protocol_>)weakTarget { \
    return (id<_target_protocol_>)safe_get_publisher_in_pair(self);\
} \
+ (Class<_target_protocol_>)weakTargetClass { \
    return (Class<_target_protocol_>)NSClassFromString([NSString stringWithUTF8String:#_target_protocol_]);\
} \
static id<HTS_MUTIPLE_MESSAGES(__VA_ARGS__)> _HTS_MSG_ASSOCIATE_LOGIC_METHOD(void);\
HTS_MSG_MUTIPLE_PROTOCOL_METHODS(__VA_ARGS__)\
static id<HTS_MUTIPLE_MESSAGES(__VA_ARGS__)> _HTS_MSG_ASSOCIATE_LOGIC_METHOD(void)

/*
Example:
    @interface AWEPlayInteractionAnchorViewModel : NSObjec
    HTSDeclareAdapters(AWEAwemePlayInteractionInteractorCommonAdapter,
                AWEAwemePlayInteractionInteractorLiteAdapter)
   
 Then: use [self AWEAwemePlayInteractionInteractorCommonAdapter] or
           [self AWEAwemePlayInteractionInteractorLiteAdapter] to get adapter
*/

#define HTSDeclareAdapters(...) \
    metamacro_foreach_cxt(HTS_DECLARE_SUBSCRIBER,,,__VA_ARGS__)

/*
Example:
    @implementation AWEPlayInteractionAnchorViewModel
    HTSGetAdapters(AWEAwemePlayInteractionInteractorCommonAdapter,
                AWEAwemePlayInteractionInteractorLiteAdapter)
   
    
 Then: use [self AWEAwemePlayInteractionInteractorCommonAdapter] or
           [self AWEAwemePlayInteractionInteractorLiteAdapter] to get adapter
*/
#define HTSGetAdapters(...) \
    metamacro_foreach_cxt(HTS_GET_SUBSCRIBER,,,__VA_ARGS__)

