//
//  FeatureGLCMGPU.h

#import <UIKit/UIKit.h>
#import "VFMetalContext.h"

@interface FeatureGLCMGPU : NSObject
-(instancetype)initWithContext: (VFMetalContext *) sharedcontext;
-(NSArray*)GetFeature:(void*)Buffer intype:(int) intype;
-(void)Release;
@end
