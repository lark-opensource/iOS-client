//
//  GroupFeature.h

#import <UIKit/UIKit.h>
#import "VFMetalContext.h"

@interface GroupFeature : NSObject
-(instancetype)initWithContext: (VFMetalContext *) sharedcontext;
-(NSArray*)GetFeature:(void*)img1  img_ref:(void*)img2 intype:(int) intype;
-(void)Release;
@end


