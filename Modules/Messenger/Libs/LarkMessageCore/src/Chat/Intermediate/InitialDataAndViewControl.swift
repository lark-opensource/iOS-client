//
//  InitialDataAndViewControl.swift
//  LarkChat
//
//  Created by zc09v on 2020/3/15.
//
import Foundation
import RxSwift
import LarkTracing

//https://bytedance.feishu.cn/docs/doccn6A5zLnXQvygKRn2IhLHIxd#
public enum ProcessStatus<BlockPreLoadData>: CustomStringConvertible {
    //阻塞数据获取，构造必备依赖组件，如ViewModel等
    case blockDataFetched(data: BlockPreLoadData)
    //构造正式视图,或去掉loading,展示初始数据
    case inNormalStatus
    //构造中间态视图,或展示loading
    case inInstantStatus

    public var description: String {
        switch self {
        case .blockDataFetched:
            return "blockDataFetched"
        case .inNormalStatus:
            return "inNormalStatus"
        case .inInstantStatus:
            return "inInstantStatus"
        }
    }
}

// BlockPreLoadData: 页面构造、关键组件必备的依赖数据类型
// OtherPreLoadData: 其他需要预先加载的数据类型
open class InitialDataAndViewControl<BlockPreLoadData, OtherPreLoadData> {
    //其他需要预先加载的数据，如果构造时有传入,后面在页面中监听这个信号就可以拿到数据。不用考虑订阅时机,有buffer,总会获取到
    public var otherPreLoadDataObservable: Observable<OtherPreLoadData> {
        return otherPreLoadDataSignal.asObservable()
    }
    //必备视图及组件是否构造完成
    public private(set) var setupFinish = false {
        didSet {
            if setupFinish {
                for perform in performCacheWhenSetup {
                    perform()
                }
            }
        }
    }

    //非阻塞数据信号,非阻塞数据拉取后发射(防止阻塞数据拉取较慢，必要数据处理对象尚未构造，结果需要缓存bufferSize: 1)
    private let otherPreLoadDataSignal: ReplaySubject<OtherPreLoadData> = ReplaySubject<OtherPreLoadData>.create(bufferSize: 1)
    private let blockPreLoadData: Observable<BlockPreLoadData>
    private let otherPreLoadData: Observable<OtherPreLoadData>?
    private let viewDidLoadSignal = PublishSubject<Bool>()
    private let disposeBag: DisposeBag = DisposeBag()
    //当viewDidLoad执行时，界面不应展示空白，如果此时block数据未返回，应通知vc展示中间态视图
    private var needShowInstantView: Bool = true
    //加载阶段操作缓存(如viewapear等中的相关调用)
    private var performCacheWhenSetup: [() -> Void] = []
    //此处采用闭包回调，闭包可保持调用的上下文环境。通过信号转发无法保证环境及逻辑时序
    private var statusChanged: ((Result<ProcessStatus<BlockPreLoadData>, Error>) -> Void)?

    /// - Parameter blockPreLoadData: 页面构造、逻辑必备的依赖数据信号
    /// - Parameter otherPreLoadData: 其他需要预先加载的数据信号，可选
    public init(blockPreLoadData: Observable<BlockPreLoadData>,
         otherPreLoadData: Observable<OtherPreLoadData>? = nil) {
        self.blockPreLoadData = blockPreLoadData
        self.otherPreLoadData = otherPreLoadData
    }

    //开始流程 获取数据->创建依赖组件->创建正式（或中间态）视图
    public func start(statusChanged: @escaping ((Result<ProcessStatus<BlockPreLoadData>, Error>) -> Void)) {
        self.statusChanged = statusChanged
        let blockDataOb = blockPreLoadData.do(onNext: { [weak self] (data) in
            self?.statusChanged?(.success(.blockDataFetched(data: data)))
            self?.needShowInstantView = false
        }, onError: { [weak self] (error) in
            self?.statusChanged?(.failure(error))
        })
        Observable.zip(viewDidLoadSignal, blockDataOb)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_, _) in
                self?.statusChanged?(.success(.inNormalStatus))
                self?.setupFinish = true
            }).disposed(by: self.disposeBag)

        otherPreLoadData?
            .subscribe(onNext: { [weak self] (data) in
                LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.getChatMessages)
                self?.otherPreLoadDataSignal.onNext(data)
            }, onError: { [weak self] (error) in
                self?.otherPreLoadDataSignal.onError(error)
            }).disposed(by: self.disposeBag)
    }

    //ViewController viewDidLoad函数中调用
    public func viewDidLoad() {
        viewDidLoadSignal.onNext(true)
        if needShowInstantView {
            self.statusChanged?(.success(.inInstantStatus))
        }
    }

    //必备视图及组件是否构造期间，需要执行的方案通过该函数包装，保证不会因提前访问导致崩溃
    public func performSafeWhenSetup(_ perform: @escaping () -> Void) {
        if setupFinish {
            perform()
        } else {
            self.performCacheWhenSetup.append(perform)
        }
    }
}
