//
//  VFMetalContext.h

#import <Metal/Metal.h>

#define GROUP_OVERFLOW_TI  (1<<8)
#define GROUP_OVERFLOW (INT_MAX>>14)
#define GLCM_GROUP 20
#define SKIP_STEPX 4
#define SKIP_STEPY 4
#define SKIP_STEPX_SI 2
#define SKIP_STEPY_SI 2

@interface VFMetalContext : NSObject

//+ (instancetype)SharedContext;
- (instancetype)initWithDevice:(id<MTLDevice>)device;
- (void)Release;

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLLibrary> library;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

