//
//  DebugPathViewModel.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/7/3.
//  

#if !LARK_NO_DEBUG

import Foundation
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkClean
import LarkContainer
import LarkStorage

final class DebugPathViewModel {
    let data = PublishRelay<[PathDebugSection]>()

    private var rawData = [PathDebugSection]()
    private let queue = DispatchQueue(label: "com.bytedance.lark.storage.LarkCleanDebugViewModel", attributes: .concurrent)

    @Provider var passport: PassportService

    var cleanContext: CleanContext

    init(cleanContext: CleanContext) {
        self.cleanContext = cleanContext
    }

    func fetchPaths() {
        let paths = allPaths(for: cleanContext)
        self.rawData = PathDebugSection.from(paths, queue: self.queue)
        self.publishData()

        self.rawData.flatMap { $0.items }
            .forEach { adapter in
                guard adapter.exists else {
                    adapter.state = .notExists
                    self.publishData()
                    return
                }

                self.queue.async { [weak self] in
                    guard let self else { return }
                    self.startScan(for: adapter)
                    self.publishData()
                }
            }
    }

    func clearPath(for adapter: PathDebugAdapter) {
        self.queue.async {
            adapter.clean { [weak self] success in
                if success {
                    //
                }
                self?.reloadPath(for: adapter)
            }
        }
    }

    func reloadPath(for adapter: PathDebugAdapter) {
        guard adapter.exists else {
            adapter.state = .notExists
            self.publishData()
            return
        }

        self.queue.async { [weak self] in
            guard let self else { return }
            adapter.state = .idle
            self.publishData()
            adapter.manager?.clear()
            self.startScan(for: adapter)
            self.publishData()
        }
    }

    @inline(__always)
    private func publishData() {
        self.data.accept(self.rawData)
    }

    private func startScan(for adapter: PathDebugAdapter) {
        do {
            try adapter.manager?.build()
            adapter.state = .ready
        } catch {
            adapter.state = .error(error.localizedDescription)
        }
    }
}

#endif

