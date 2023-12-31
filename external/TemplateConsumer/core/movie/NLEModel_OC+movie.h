//
//  NLEModel+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NLEModel_OC_movie_h
#define NLEModel_OC_movie_h

#import <NLEPlatform/NLEModel+iOS.h>
#include <memory>

namespace cut {
    namespace model {
         class NLEModel;
    }
}

@interface NLEModel_OC (movie)

+ (NLEModel_OC *)convertWithConfig:(NSString *)config;

//- (NLEModel_OC *)originData;

@end

#endif /* NLEModel_OC_movie_h */
