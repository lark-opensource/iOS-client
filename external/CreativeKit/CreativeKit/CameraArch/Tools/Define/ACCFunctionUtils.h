//
//  ACCFunctionUtils.m
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/6.
//

CG_INLINE BOOL AWECGSizeIsNaN(CGSize size) {
    return isnan(size.width) || isnan(size.height);
}

CG_INLINE BOOL AWECGRectIsNaN(CGRect rect) {
    return isnan(rect.size.width) || isnan(rect.size.height) || isnan(rect.origin.x) || isnan(rect.origin.y);
}
