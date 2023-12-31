//
//  CardContainer.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/5/13.
//

import Foundation
import LarkOPInterface

/// 卡片容器，封装整个卡片渲染流程的逻辑实体
public final class CardContainer {

    /// 卡片 schema
    private let schema: URL

    /// 卡片 schema model
    private let cardSchemaModel: CardSchema

    /// 当前的meta请求上下文对象
    private var cardMetaLoadContext: MetaContext {
        MetaContext(
            uniqueID: uniqueID,
            token: cardSchemaModel.token
        )
    }

    /// 应用uniqueID
    private var uniqueID: BDPUniqueID

    /// 正在使用的meta
    private var usingMeta: CardMeta?

    /// 卡片配置信息回调
    weak private var cardInfoListener: CardInfoListenerProtocol?

    /// 卡片view实体
    private lazy var internalCardView: CardView = CardView(cardframe: cardFrame, uniqueID: uniqueID)
    /// 卡片view的尺寸信息
    private var cardFrame: CGRect

    /// 暴露给外界使用的卡片的渲染引擎
    public var cardRenderEngine: CardViewProtocol {
        internalCardView
    }

    /// 暴露给外界使用的抽象View，可以被addSubview
    public var view: UIView {
        internalCardView
    }

    /// 容器初始化
    /// - Parameters:
    ///   - schema: 卡片Schema
    ///   - cardInfoListener: 容器给业务方的回调，可以让业务方监听到卡片的的meta 信息请求结果还有卡片渲染时的外观配置
    ///   - cardLifeCyclelistener: Card LifeCycle Protocol
    ///   - cardFrame: 尺寸
    public init(
        schema: URL,
        cardInfoListener: CardInfoListenerProtocol? = nil,
        cardLifeCyclelistener: CardLifeCycleProtocol? = nil,
        cardFrame: CGRect
    ) {
        BDPLogInfo(tag: .cardContainer, "card container init, schema: \(schema.absoluteString)")
        self.schema = schema
        let csModel = CardSchema(with: schema)
        cardSchemaModel = csModel
        uniqueID = cardSchemaModel.uniqueID()
        self.cardFrame = cardFrame
        self.cardInfoListener = cardInfoListener
        if let cardLifeCyclelistener = cardLifeCyclelistener {
            internalCardView.setLifeCycleListener(cardLifeCyclelistener)
        }
    }

    deinit {
        BDPLogInfo(tag: .cardContainer, "card conntainer deinit with uniqueID: \(uniqueID)")
    }

    /// 添加卡片生命周期监听（请业务方自己处理对象生命周期，并且不保证设置的时候一定没有走卡片的流程）
    /// - Parameter listener: 监听对象
    public func setLifeCycleListener(_ listener: CardLifeCycleProtocol) {
        internalCardView.setLifeCycleListener(listener)
    }

    /// 添加卡片配置信息监听（请业务方自己处理对象生命周期，并且不保证设置的时候一定没有走卡片的流程）
    /// - Parameter listener: 监听对象
    public func setCardInfoListener(_ listener: CardInfoListenerProtocol) {
        cardInfoListener = listener
    }


    /// 进行meta和包流程，加载卡片
    public func loadWithSchema() {
        guard let appLoader = BDPModuleManager(of: .widget)
            .resolveModule(with: CommonAppLoadProtocol.self) as? CommonAppLoadProtocol else {
                let msg = "has no app load module manager"
                assertionFailure(msg)
                BDPLogError(tag: .cardContainer, msg)
                return
        }

        /// 卡片使用方的错误
        var bizMetaError: Error?
        appLoader.launchLoadMetaAndPackage(
            with: cardMetaLoadContext,
            packageType: .zip,
            getMetaSuccess: { [weak self] (meta, type) in
                guard let `self` = self, type != .asyncUpdate else { return }
                let cardMeta = meta as! CardMeta
                self.usingMeta = cardMeta
                //  回调
                self.cardInfoListener?.cardMetaCallback(with: cardMeta)
                bizMetaError = self.cardInfoListener?.isMetaVaild(with: cardMeta)
            },
            getMetaFailure: { [weak self] (error, type) in
                guard let `self` = self, type != .asyncUpdate else { return }
                self.cardInfoListener?.cardInfoError(with: error)
            },
            downloadPackageBegun: nil,
            downloadPackageProgress: nil
        ) { [weak self] (packageReader, error, type) in
            guard let `self` = self, type != .asyncUpdate else { return }
            if let error = error {
                self.cardInfoListener?.cardInfoError(with: error)
                return
            }
            if let bizError = bizMetaError {
                self.cardInfoListener?.cardInfoError(with: bizError)
                return
            }
            guard let packageReader = packageReader else {
                let msg = "has no packageReader"
                let err = cardContainerError(with: msg)
                BDPLogError(tag: .cardContainer, msg)
                self.cardInfoListener?.cardInfoError(with: err)
                return
            }
            self.loadPackage(with: packageReader)
        }
    }

    /// 更新卡片
    public func updateCard() {
        //  如果当前没有正在加载的Meta，走常规加载流程即可
        guard let currentMeta = usingMeta else {
            loadWithSchema()
            return
        }
        let metaAndPkgManager: (MetaInfoModuleProtocol, BDPPackageModuleProtocol)
        do {
            metaAndPkgManager = try tryGetMetaAndPkgManager()
        } catch {
            //  必定不会走到这里，只是不希望在tryGetMetaAndPkgManager写强制解包，这里catch一下
            BDPLogError(tag: .cardContainer, "first load card error, \(error)")
            return
        }
        //  直接下载最新meta
        metaAndPkgManager.0.requestRemoteMeta(
            with: cardMetaLoadContext,
            shouldSaveMeta: true,
            success: { [weak self] (meta, _) in
                guard let `self` = self else { return }
                let metaModel = meta as! CardMeta
                if let bizMetaError = self.cardInfoListener?.isMetaVaild(with: metaModel) {
                    //  卡片更新的时候也需要调用一下业务方的合法性判断
                    self.cardInfoListener?.cardInfoError(with: bizMetaError)
                    return
                }
                self.usingMeta = metaModel
                //  判断md5是否一样
                guard metaModel.packageData.md5 != currentMeta.packageData.md5 else {
                    //  md5一样，无需下包刷新
                    return
                }
                //  使用了新的meta 按照新需求也需要走cardInfoListener回调 和@李论确认过，如果md5不变化，不需要调用cardMetaCallback
                self.cardInfoListener?.cardMetaCallback(with: metaModel)
                //  下包刷新
                var cardPkgMonitor = OPMonitor(kEventName_op_app_card_package_install)
                    .setUniqueID(metaModel.uniqueID)
                    .addCategoryValue(kEventKey_load_type, "normal")
                    .addTag(.cardContainer)
                    .timing()
                self.loadPkg(
                    with: metaAndPkgManager.1,
                    cardID: metaModel.uniqueID.identifier,
                    context: self.buildPackageContext(with: metaModel, trace: self.cardMetaLoadContext.trace),
                    cardPkgMonitor: cardPkgMonitor
                )
            }
        ) { [weak self] (error) in
            //  更新卡片 按照新需求也需要走cardInfoListener回调
            self?.cardInfoListener?.cardInfoError(with: error)
            BDPLogError(tag: .cardContainer, "try update card error, request meta failed, \(error)")
        }
    }

    /// 组装包相关请求上下文
    /// - Parameter cardMeta: 卡片meta
    /// - Returns: 包上下文
    private func buildPackageContext(with cardMeta: CardMeta, trace: BDPTracing) -> BDPPackageContext {
        //  组装包相关请求上下文
        BDPPackageContext(
            appMeta: cardMeta,
            packageType: .zip,
            packageName: nil,
            trace: trace
        )
    }

    /// 加载卡片，回调config
    /// - Parameter packageReader: 读包对象
    private func loadPackage(with packageReader: BDPPkgFileManagerHandleProtocol) {
        //  用filemanager，拼接card.config.json到后面，读出来是个data，回调出去
        do {
            //  后端返回出来的结构要求如此拼接
            let cardConfigData = try packageReader.readData(withFilePath: "/card.config.json")
            cardInfoListener?.cardConfigCallback(with: cardConfigData)
        } catch {
            let msg = "no card.config.json"
            BDPLogError(tag: .cardContainer, error.localizedDescription + ": \(msg)")
        }

        //  用filemanager，拼接template.js到后面，读出来
        do {
            let data = try packageReader.readData(withFilePath: "/template.js")
            DispatchQueue.main.async {
                self.cardRenderEngine.loadTemplate(
                    with: data,
                    url: "local",
                    initData: nil
                )
                self.cardRenderEngine.triggerLayout()
            }
        } catch {
            let msg = "no template.js"
            BDPLogError(tag: .cardContainer, error.localizedDescription + ": \(msg)")
        }
    }
}

extension CardContainer {

    /// 尝试获取Meta和包管理器
    /// - Returns: 管理器元组
    private func tryGetMetaAndPkgManager() throws -> (MetaInfoModuleProtocol, BDPPackageModuleProtocol) {
        guard let metaManager = BDPModuleManager(of: .widget)
            .resolveModule(with: MetaInfoModuleProtocol.self) as? MetaInfoModuleProtocol else {
                let err = cardContainerError(with: "has no meta module manager")
                cardInfoListener?.cardInfoError(with: err)
                assertionFailure(err.localizedDescription)
                BDPLogError(tag: .cardContainer, "\(err)")
                throw err
        }
        guard let packageManager = BDPModuleManager(of: .widget)
            .resolveModule(with: BDPPackageModuleProtocol.self) as? BDPPackageModuleProtocol else {
                let err = cardContainerError(with: "has no pkg module manager")
                cardInfoListener?.cardInfoError(with: err)
                assertionFailure(err.localizedDescription)
                BDPLogError(tag: .cardContainer, "\(err)")
                throw err
        }
        return (metaManager, packageManager)
    }

    /// 使用meta加载包
    /// - Parameters:
    ///   - pkgManager: 包管理器
    ///   - cardID: 卡片ID
    ///   - context: 包管理加载上下文
    ///   - cardPkgMonitor: 卡片包管理monitor
    private func loadPkg(
        with pkgManager: BDPPackageModuleProtocol,
        cardID: String,
        context: BDPPackageContext,
        cardPkgMonitor: OPMonitor
    ) {
        pkgManager
            .checkLocalOrDownloadPackage(
                with: context,
                localCompleted: { [weak self] (packageReader) in
                    guard let `self` = self else { return } //  self释放，关闭了卡片，流程结束
                    //  埋点Log
                    cardPkgMonitor
                        .setResultTypeSuccess()
                        .setMonitorCode(AppCardMonitorCodeInstall.install_success)
                        .timing()
                        .flush()
                    BDPLogInfo(tag: .cardContainer, "card container get local pkg path, cardid: \(cardID)")
                    //  加载包
                    self.loadPackage(with: packageReader)
                },
                downloadPriority: URLSessionTask.highPriority,
                downloadBegun:nil,
                downloadProgress: nil
            ) { [weak self] (error, _, packageReader) in
                guard let `self` = self else { return } //  self释放，关闭了卡片，流程结束
                //  埋点
                if let error = error {
                    self.cardInfoListener?.cardInfoError(with: error)
                    BDPLogError(tag: .cardContainer, error.localizedDescription)
                    cardPkgMonitor
                        .setResultTypeFail()
                        .setMonitorCode(AppCardMonitorCodeInstall.install_failed)
                        .setError(error)
                        .flush()
                    return
                }
                guard let packageReader = packageReader else {
                    let msg = "has no package reader form pkg manager"
                    self.cardInfoListener?.cardInfoError(with: cardContainerError(with: msg))
                    BDPLogError(tag: .cardContainer, msg)
                    cardPkgMonitor
                        .setResultTypeFail()
                        .setMonitorCode(AppCardMonitorCodeInstall.install_failed)
                        .setErrorMessage(msg)
                        .flush()
                    return
                }
                BDPLogInfo(tag: .cardContainer, "card container get remote pkg path, cardid: \(cardID)")
                cardPkgMonitor
                    .setResultTypeSuccess()
                    .setMonitorCode(AppCardMonitorCodeInstall.install_success)
                    .timing()
                    .flush()
                self.loadPackage(with: packageReader)
        }
    }
}

/// 组装远程URL下载卡片的错误对象
/// - Parameter msg: 错误信息
private func cardContainerError(with msg: String) -> Error {
    NSError(
        domain: "CardContainer",
        code: -1,
        userInfo: [
            NSLocalizedDescriptionKey: msg
        ]
    )
}
