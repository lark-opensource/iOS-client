//
//  BenchmarkController.swift
//  LarkCleanDev
//
//  Created by 李昊哲 on 2023/7/17.
//  

import UIKit
import Foundation
import LarkStorage
import SnapKit
import RxSwift
import RxCocoa

final class BenchmarkController: UIViewController {
    private lazy var resultView = UITextView()
    private lazy var statusLabel = UILabel()

    private let disposeBag = DisposeBag()
    private let resultRelay = PublishRelay<String>()
    private let statusRelay = PublishRelay<String>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupView()
        setupRx()
    }

    private func setupView() {
        let scrollView = UIScrollView()
        let contentView = UIView()

        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false

        contentView.addSubview(resultView)
        contentView.addSubview(statusLabel)
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)

        statusLabel.text = "正在执行 Benchmark...请耐心等待\n"
        statusLabel.numberOfLines = 0

        resultView.font = .systemFont(ofSize: 15)
        resultView.isScrollEnabled = false
        resultView.isEditable = false

        resultView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview().inset(20)
        }
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(resultView.snp.bottom)
            make.left.right.equalTo(resultView)
            make.bottom.equalToSuperview().inset(80)
        }
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(view.snp.width)
            make.height.greaterThanOrEqualToSuperview()
        }
    }

    private func setupRx() {
        guard let attrs = try? AbsPath.home.attributesOfFileSystem(),
           let freeSize = attrs[.systemFreeSize] as? Int,
           freeSize > 10 * 1024 * 1024 * 1024
        else {
            resultView.text = "iPhone 可用存储空间小于 10G，无法执行 Benchmark"
            return
        }

        resultRelay
            .scan("", accumulator: { $0 + "\n" + $1 })
            .bind(to: resultView.rx.text)
            .disposed(by: disposeBag)

        statusRelay
            .bind(to: statusLabel.rx.text)
            .disposed(by: disposeBag)

        self.doBenchmark()
    }

    private func doBenchmark() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            self.resultRelay.accept("------ 按照文件大小和数量 ------")

            // 文件大小、大小单位、文件数量
            let cases: [(FileSize, Int)] = [
                (FileSize(1, .KB), 1000), (FileSize(1, .KB), 10000),
                (FileSize(1, .MB), 100), (FileSize(1, .MB), 500), (FileSize(1, .MB), 1000), (FileSize(1, .MB), 10000),
                (FileSize(10, .MB), 100), (FileSize(10, .MB), 500), (FileSize(10, .MB), 1000),
                (FileSize(100, .MB), 5), (FileSize(100, .MB), 10), (FileSize(100, .MB), 100),
                (FileSize(500, .MB), 1), (FileSize(500, .MB), 10),
                (FileSize(1, .GB), 1), (FileSize(1, .GB), 10),
                (FileSize(10, .GB), 1),
            ]
            for (size, count) in cases {
                let status = "正在填充文件\t大小: \(size)\t数量: \(count)"
                self.statusRelay.accept(status)
                let result: String
                do {
                    let rootPath = IsoPath.in(space: .global, domain: Domain.biz.infra.child("LarkCleanDev"))
                        .build(forType: .temporary, relativePart: "Benchmark")
                    try Self.createFlattenFiles(rootPath: rootPath, size: size, number: count)

                    let time = try Self.deletePath(rootPath)
                    result = String(format: "耗时: %.3lfs\t大小: %@\t数量: %d", time, size.description, count)
                } catch {
                    result = "大小: \(size)\t数量: \(count)\t错误: \(error)"
                }
                self.resultRelay.accept(result)
            }

            self.resultRelay.accept("\n------ 按照层级深度 ------")

            // 完全N叉树, 深度 depth, 深度为 0 表示此 path 下不包含文件
            let cases2: [(Int, Int, FileSize)] = [
                (4, 3, FileSize(1, .MB)), (4, 4, FileSize(1, .MB)), (4, 5, FileSize(1, .MB)),
                (4, 3, FileSize(10, .MB)), (4, 4, FileSize(10, .MB)), (4, 5, FileSize(10, .MB)),
                (4, 3, FileSize(100, .MB)), (4, 4, FileSize(100, .MB)),
            ]
            for (degree, depth, size) in cases2 {
                let leafCount = Int(pow(Double(degree), Double(depth)))
                let internalCount = (leafCount - degree) / (degree - 1)
                let totalCount = (leafCount * degree - 1) / (degree - 1)

                let status = "正在填充文件\t大小: \(size)结点度: \(degree)\t深度: \(depth)\t总个数: \(totalCount)"
                self.statusRelay.accept(status)
                let result: String
                do {
                    let rootPath = IsoPath.in(space: .global, domain: Domain.biz.infra.child("LarkCleanDev"))
                        .build(forType: .temporary, relativePart: "Benchmark")
                    try Self.createTreeDirectories(rootPath: rootPath, size: size, degree: degree, depth: depth)

                    let time1 = try Self.deletePath(rootPath)

                    // 创建仅一层的文件夹，填充对应数量的文件和文件夹
                    try Self.createFlattenFilesAndDirectories(
                        rootPath: rootPath,
                        size: size,
                        numberOfFiles: leafCount,
                        numberOfDirectories: internalCount
                    )

                    let time2 = try Self.deletePath(rootPath)

                    result = String(format: "耗时: %.3lfs\t节点度: %d\t深度: %d\n", time1, degree, depth)
                             + String(format: "对应仅一层 %d 个目录, %d 个文件耗时: %.3lfs", internalCount, leafCount, time2)
                } catch {
                    result = "节点度: \(degree)\t深度: \(depth)\t错误: \(error)"
                }
                self.resultRelay.accept(result)
            }

            self.statusRelay.accept("执行完成")
        }
    }

    private static func createFile(path: IsoPath, size: FileSize) throws {
        let times, bufferCount: Int

        switch size.unit {
        case .B, .KB, .MB:
            times = size.count
            bufferCount = size.unit.count
        case .GB:
            times = size.count * 1024
            bufferCount = FileSizeUnit.MB.count
        }

        try path.createFileIfNeeded()
        let handle = try path.fileUpdatingHandle()
        let buffer = Data(repeating: 0, count: bufferCount)
        for _ in 0..<times {
            handle.seekToEndOfFile()
            handle.write(buffer)
        }
        handle.closeFile()
    }

    // 创建仅一层的文件夹，文件夹内根据给定文件大小和数量填充文件
    private static func createFlattenFiles(rootPath: IsoPath, size: FileSize, number: Int) throws {
        if rootPath.exists {
            try rootPath.removeItem()
        }
        try rootPath.createDirectory()

        let group = DispatchGroup()
        fillWithFiles(group: group, path: rootPath, size: size, number: number)
        group.wait()
    }

    // 创建仅一层的文件夹，文件夹内根据给定文件大小和数量填充文件，并填充指定数量的文件夹
    private static func createFlattenFilesAndDirectories(rootPath: IsoPath, size: FileSize, numberOfFiles: Int, numberOfDirectories: Int) throws {
        if rootPath.exists {
            try rootPath.removeItem()
        }
        try rootPath.createDirectory()

        let group = DispatchGroup()
        fillWithFiles(group: group, path: rootPath, size: size, number: numberOfFiles)
        fillWithDirectories(group: group, path: rootPath, number: numberOfDirectories)
        group.wait()
    }

    // 创建完全N叉树结构的文件夹，叶子结点填充为指定大小的文件
    private static func createTreeDirectories(rootPath: IsoPath, size: FileSize, degree: Int, depth: Int) throws {
        if rootPath.exists {
            try rootPath.removeItem()
        }
        try rootPath.createDirectory()

        let group = DispatchGroup()

        func inner(path: IsoPath, depth: Int) {
            if depth > 1 {
                // 递归创建目录
                fillWithDirectories(group: group, path: path, number: degree) { subPath in
                    inner(path: subPath, depth: depth - 1)
                }
            } else if depth == 1 {
                // 叶子结点填充为文件
                fillWithFiles(group: group, path: path, size: size, number: degree)
            }
        }
        inner(path: rootPath, depth: depth)

        group.wait()
    }

    private static func fillWithFiles(group: DispatchGroup, path: IsoPath, size: FileSize, number: Int) {
        for i in 0..<number {
            let name = String(i)
            let subPath = path + name

            DispatchQueue.global().async(group: group) {
                do {
                    try createFile(path: subPath, size: size)
                } catch {
                    print("create file \(subPath) error:", error)
                }
            }
        }
    }

    private static func fillWithDirectories(group: DispatchGroup, path: IsoPath, number: Int, complete: ((IsoPath) throws -> Void)? = nil) {
        for i in 0..<number {
            let name = String(i)
            let subPath = path + name

            DispatchQueue.global().async(group: group) {
                do {
                    try subPath.createDirectory()
                    try complete?(subPath)
                } catch {
                    print("create directory \(subPath) error:", error)
                }
            }
        }
    }

    private static func deletePath(_ path: IsoPath) throws -> Double {
        let startTime = CFAbsoluteTimeGetCurrent()
        try path.removeItem()
        let endTime = CFAbsoluteTimeGetCurrent()
        return endTime - startTime
    }

}

private enum FileSizeUnit: String {
    case B, KB, MB, GB

    var count: Int {
        switch self {
        case .B: return 0x1
        case .KB: return 0x400
        case .MB: return 0x100000
        case .GB: return 0x40000000
        }
    }
}

private struct FileSize: CustomStringConvertible {
    let count: Int
    let unit: FileSizeUnit

    init(_ count: Int, _ unit: FileSizeUnit) {
        self.count = count
        self.unit = unit
    }

    var description: String {
        return "\(count)\(unit)"
    }
}
