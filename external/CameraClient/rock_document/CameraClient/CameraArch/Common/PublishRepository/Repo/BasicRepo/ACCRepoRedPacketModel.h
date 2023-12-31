//
//  ACCRepoRedPacketModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Howie He on 2020/11/3.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <Mantle/Mantle.h>

// 红包资产类型
typedef NS_ENUM(NSUInteger, ACCFlowerRedPacketAssetType) {
    ACCFlowerRedPacketAssetTypeNone     = 0, /// 未绑定
    ACCFlowerRedPacketAssetTypeCoupon   = 1, /// 卡券
    ACCFlowerRedPacketAssetTypeCashPay  = 2, /// C2C现金支付的红包
};

/// 卡券红包和现金红包，不和业务属性(例如道具，任务等)绑定
/// 所以感觉比较通用，故未下沉到flower，后续可以再使用

@interface ACCFlowerRedPacketInfo : MTLModel

#pragma mark - common

/// 客户端生成的外部订单号，透传FE使用和service
@property (nonatomic, copy, nullable, readonly) NSString *uniqueCreationID;

/// creationID 标注唯一
- (instancetype)initWithCreationID:(NSString *_Nonnull)creationID;

/// 当前绑定的红包资产类型 现金红包 | 卡券红包
- (ACCFlowerRedPacketAssetType)currentAssetType;

/// 通用的外部订单号，B2C直接使用uniqueCreationID，C2C由前端生成，使用cashOutOrderId
- (NSString *_Nullable)outOrderId;


#pragma mark - coupon

/// B2C补贴的卡券，可能是FE选择后的回传或者从router带入
@property (nonatomic, copy, nullable) NSString *couponId;

/// 卡券红包领取个数配置，由FE透传或者从settings下发
@property (nonatomic, assign) NSInteger couponCount;

/// 卡券核销后的id，一般在发布的时候核销卡券，服务端回传核销后的id
@property (nonatomic, copy, nullable) NSString *couponOrderId;

#pragma mark - cash pay
/// 现金红包红包id，现金红包一定是支付的，由FE回传
@property (nonatomic, copy, nullable) NSString *cashRedPacketId;

/// FE透传的一些现金红包额外信息，客服端只负责透传到投稿
@property (nonatomic, copy, nullable) NSString *cashPacketExtra;

/// FE根据客户端的uniqueCreationID+时间戳生成的现红包专用的外部订单号
/// @see self.outOrderId
@property (nonatomic, copy, nullable) NSString *cashOutOrderId;

@end

@interface ACCRepoRedPacketModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol,ACCRepositoryTrackContextProtocol>

@property(nonatomic, strong, nullable) ACCFlowerRedPacketInfo *redPacketInfo;

/// 外部传入的关联卡券，用于激活首次进入时的红包
@property (nonatomic, copy, nullable) NSString *routerCouponId;

/// 是否清过红包，用于一些路径忽略发布页，不存草稿
@property (nonatomic, assign) BOOL didClearedRedpacketInfoOnce;

/// 是否已经绑定红包（卡券/现金）并不一定已核销，核销是在发布流程中
- (BOOL)didBindRedpacketInfo;

/// 绑定的是现金红包
- (BOOL)isBindCashRedpacketInfo;

/// 清理绑定的卡券、订单
- (void)clearRedPacketInfo;

/// 回滚B2C红包后需要重新生成
- (void)rebuildCreationID;
@property (nonatomic, assign) BOOL needHandleRebuildCreationIDFlag;

/// B2C已核销，C2C已付款
- (BOOL)didSendAnyRedpacket;

- (NSDictionary *_Nullable)trackInfo;

/// 从冷启恢复自动发布的路径下 恢复资源的时候 跳过check，字段不存草稿
@property (nonatomic, assign) BOOL skipRedpacketCheckWhenBackupPublishFlag;

@end

@interface AWEVideoPublishViewModel (RepoRedPacket)<ACCRepositoryElementRegisterCategoryProtocol>

@property (nonatomic, strong, readonly, nonnull) ACCRepoRedPacketModel *repoRedPacket;

@end
