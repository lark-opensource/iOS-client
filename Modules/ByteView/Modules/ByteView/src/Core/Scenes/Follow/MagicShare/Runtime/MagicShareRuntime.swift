//
//  MagicShareRuntime.swift
//  ByteView
//
//  Created by chentao on 2020/4/12.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

protocol MagicShareRuntime: AnyObject {

    /// MSRuntime 持有者标识，避免 Runtime 被复用时，旧的持有者操作 runtime
    var ownerID: ObjectIdentifier? { get set }

    /// 是否是远端文档，未使用
    var isFromRemote: Bool { get }

    /// 文档的链接
    var documentUrl: String { get }

    /// 文档标题，未使用，外部使用MagicShareDocument的documentTitle
    var documentTitle: String { get }

    /// 文档容器
    var documentVC: UIViewController { get }

    /// 文档页面的ScrollView，未使用
    var contentScrollView: UIScrollView? { get }

    /// 是否可以调用“回到上次位置”方法
    var canBackToLastPosition: Bool { get }

    /// 文档数据实体
    var documentInfo: MagicShareDocument { get }

    /// 是否已经渲染完成
    var didRenderFinish: Bool { get }

    /// 当前用户是否处于编辑态
    var isEditing: Bool { get }

    /// 文档共享/跟随状态
    var currentDocumentStatus: MagicShareDocumentStatus { get }

    /// 是否准备好做初始化埋点
    var isReadyForInitTrack: Bool { get set }

    /// 设置“相对共享人的方向”
    func setLastDirection(_ direction: MagicShareDirectionViewModel.Direction?)

    /// 获取“相对共享人的方向”
    func getLastDirection() -> MagicShareDirectionViewModel.Direction?

    /// 更新API文档信息
    /// - Parameter documentInfo: 文档信息
    func updateDocument(_ documentInfo: MagicShareDocument)

    /// 开始记录State
    ///
    /// - Returns: 无
    func startRecord()

    /// 停止记录State
    ///
    /// - Returns: 无
    func stopRecord()

    /// 开启Follow状态
    /// 参会人端初始化时调用
    /// - Returns: 无
    func startFollow()

    /// 停止跟随
    /// 参会人端自由浏览时调用，结束Follow状态后，有FollowState来时，仍然需要调用 setState()，只是此时FollowState会存在起来不生效，等用户回到跟随浏览状态时，立即应用最新版FollowState。
    /// - Returns: 无
    func stopFollow()

    /// 开始投屏转妙享，*Any but sstomsFree* -> sstomsFollowing
    func startSSToMS()

    /// 结束投屏转妙享，sstomsFollowing -> sstomsFree
    func stopSSToMS()

    /// 刷新当前页面
    ///
    /// - Returns: 无
    func reload()

    /// 更新createSource时，重新计算加载时间
    /// - Parameter createSource: Runtime的创建方式
    func resetCreateSource(_ createSource: MagicShareRuntimeCreateSource)

    /// 设定MagicShareRuntimeDelegate，复用Runtime时调用
    func setDelegate(_ delegate: MagicShareRuntimeDelegate)

    /// 重新设置MagicShareDocumentChangeDelegate，复用Runtime时调用
    func setDocumentChangeDelegate(_ documentChangeDelegate: MagicShareDocumentChangeDelegate)

    /// 回到上次位置
    func setReturnToLastLocation()

    /// 存储当前位置
    func setStoreCurrentLocation()

    /// 清除文档位置
    func setClearStoredLocation()

    /// 容器即将消失，调用此方法通知CCM侧收起打开的页面
    func willSetFloatingWindow()

    /// 回到全屏行为结束
    func finishFullScreenWindow()

    /// 文档加载结束时埋点。如果skippedDocumentShareID非空，强制上报一次，且ShareID使用skippedDocumentShareID
    /// 参考：https://bytedance.feishu.cn/docs/doccna36Aup1dOWWWY3zMh9Ob1f
    /// - Parameters:
    ///   - finishReason: 加载结束的原因
    ///   - skippedDocumentShareID: 上报时使用的ShareID
    func trackOnMagicShareInitFinished(dueTo finishReason: MagicShareInitFinishedReason, forceUpdateWith skippedDocumentShareID: String?)

    /// 更新当前会议中的参会人数量
    func updateParticipantCount(_ count: Int)

    /// 取消“跟随者未收到有效FollowStates”回调报警监控
    func cancelFollowerNoValidFollowStatesTimeout()

    /// 取消全部已发起的妙享相关的报警监控
    func cancelAllMagicShareTimeouts()

    /// 将followAPI替换为空实现，以释放WebView供复用
    func replaceWithEmptyFollowAPI()
}

extension MagicShareRuntime {

    /// 文档加载结束时埋点
    /// - Parameter finishReason: 加载结束的原因
    func trackOnMagicShareInitFinished(dueTo finishReason: MagicShareInitFinishedReason) {
        trackOnMagicShareInitFinished(dueTo: finishReason, forceUpdateWith: nil)
    }

}

extension MagicShareRuntime {

    func stop() {
        switch currentDocumentStatus {
        case .sharing:
            stopRecord()
        case .following:
            stopFollow()
        case .sstomsFollowing:
            stopSSToMS()
        case .free, .sstomsFree:
            break
        }
    }

}

protocol MagicShareRuntimeDelegate: AnyObject {

    /// 文档加载完全结束
    func magicShareRuntimeDidReady(_ magicShareRuntime: MagicShareRuntime)

    /// 用户在文档页面点击链接等操作
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onOperation operation: MagicShareOperation)

    /// 【已废弃】自由浏览时，主/被共享人位置变化
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onPresenterFollowerLocationChange location: MagicSharePresenterFollowerLocation)

    /// 自由浏览时，主/被共享人位置变化
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onRelativePositionChange position: MagicShareRelativePosition)

    /// 有FollowState被调用Apply
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onApplyStates states: [FollowState], uuid: String, timestamp: CGFloat)

    /// CCM首次Apply成功
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, onFirstPositionChangeAfterFollow receiveFollowInfoTime: TimeInterval)

}

protocol MagicShareDocumentChangeDelegate: AnyObject {

    /// MS文档内容改变
    func magicShareRuntime(_ magicShareRuntime: MagicShareRuntime, didDocumentChange userOperation: MagicShareOperation)

}

extension CCMDependency {

    /// 下载加密的图片并解密返回
    /// - Parameters:
    ///   - url: 加密图片url
    ///   - imageView: imageView
    ///   - thumbnailInfo: ["nonce":"随机数", "secret":"秘钥","type" :"解密方式"]
    ///   - completion: 回调
    func downloadEncryptedImage(use url: String, to imageView: UIImageView,
                                imageSize: CGSize? = nil,
                                thumbnailInfo: [String: Any],
                                requireFullImage: Bool = false, // PPT类型需要在小窗上展示完整缩略图
                                completion: ((UIImage?, Error?) -> Void)?) {
        var size: CGSize?
        if !requireFullImage {
            if let imageSize = imageSize {
                size = imageSize
            } else {
                size = getEncryptedImageSize()
            }
        }
        downloadThumbnail(url: url, thumbnailInfo: thumbnailInfo, imageSize: size) { [weak imageView] r in
            Util.runInMainThread { [weak imageView] in
                switch r {
                case let .success(image):
                    imageView?.image = image
                    completion?(image, nil)
                case let .failure(error):
                    Logger.vcFollow.error("downloadEncryptedImage failed", error: error)
                    completion?(nil, error)
                }
            }
        }
    }

    private func getEncryptedImageSize() -> CGSize {
        let isLandscape = VCScene.isLandscape
        let windowWidth = VCScene.bounds.size.width
        var count: CGFloat = 2
        if Display.pad {
            count = 3.0 // 每排3个
        } else {
            count = isLandscape ? 5.0 : 2.0 // 竖屏每排2个，横屏5个
        }
        // 这样算出来的宽度会比实际的imageView大，就是scaleFit模式进行缩小
        let width: CGFloat = windowWidth / count
        return CGSize(width: width, height: width * 0.825)
    }

}
