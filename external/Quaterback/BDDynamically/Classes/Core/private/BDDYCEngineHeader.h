#import <Foundation/Foundation.h>

enum {
    BDDYCEngineUsingUndefined = 0,
    BDDYCEngineUsingJSContext = 1 << 0,
    BDDYCEngineUsingBrady = 1 << 1,
};

#define BDDYC_FORMAT_LL @"ll"
#define BDDYC_FORMAT_BC @"bc"
#define BDDYC_FORMAT_BD @"bd"

__unused
static NSArray * BDDYCGetBitcodeEngineFormats(void)
{
    return @[BDDYC_FORMAT_LL, BDDYC_FORMAT_BC,BDDYC_FORMAT_BD];
}
