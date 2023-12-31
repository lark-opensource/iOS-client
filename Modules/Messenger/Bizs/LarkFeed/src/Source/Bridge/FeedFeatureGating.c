//
//  FeedFeatureGating.h
//  LarkFeed
//
//  Created by 夏汝震 on 2021/9/15.
//

#include "FeedFeatureGating.h"
#include <stdlib.h>

int __lark_feature_gating_from__(const char *fg) {
    if (getFgValueOfSwiftImpl == NULL) {
        return 0;
    }
    return getFgValueOfSwiftImpl(fg);
}
