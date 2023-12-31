//
//  HMDNetTrafficDefinedKey.h
//  Pods
//
//  Created by zhangxiao on 2021/10/18.
//

#ifndef HMDNetTrafficDefinedKey_h
#define HMDNetTrafficDefinedKey_h

static NSString *const kHMDTrafficAbnormalTypeTotalUsage = @"total_usage_abnormal";
static NSString *const kHMDTrafficAbnormalTypeBgUsage = @"bg_usage_abnormal";
static NSString *const kHMDTrafficAbnormalTypeNeverFrontUsage = @"never_front_usage_abnormal";
static NSString *const kHMDTrafficAbnormalTypeHighFreq = @"high_freq_request";
static NSString *const kHMDTrafficAbnormalTypeLargeRequest = @"large_request";

static NSString *const kHMDTrafficCustomInfoBeforeUsage = @"before_usage";
static NSString *const kHMDTrafficCustomInfoBeforeTimestamp = @"before_timestamp";
static NSString *const kHMDTrafficCustomInfoInitTimeKey = @"init_time";
static NSString *const kHMDTrafficCustomInfoEndTimeKey = @"end_time";

static NSString *const kHMDTrafficReportKeyUsageDetail = @"usage";
static NSString *const kHMDTrafficReportKeyBizName = @"biz";
static NSString *const kHMDTrafficReportKeyBizUsageDetail = @"usage_detail";
static NSString *const kHMDTrafficReportKeyBizSourceDetail = @"detail";
static NSString *const kHMDTrafficReportKeySourceName = @"source_id";
static NSString *const kHMDTrafficReportKeySourceUsageDetail = @"usage_detail";

static NSString *const kHMDTrafficReportKeyLargeUsageRequest = @"large_usage";
static NSString *const kHMDTrafficReportKeyHighFrequencyRequest = @"high_freq";
static NSString *const kHMDTrafficReportKeyLargePic = @"pic_large_usage";

static NSString *const kHMDTrafficReportUsageKeyInterval = @"usage_10_minutes";
static NSString *const kHMDTrafficReportUsageKeyMobileFront = @"mobile_front";
static NSString *const kHMDTrafficReportUsageKeyMobileBack = @"mobile_back";
static NSString *const kHMDTrafficReportUsageKeyWiFiFront = @"wifi_front";
static NSString *const kHMDTrafficReportUsageKeyWiFiBack = @"wifi_back";


#endif /* HMDNetTrafficDefinedKey_h */
