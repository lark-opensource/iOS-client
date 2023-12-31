# LibArchiveKit

## 组件作用

[LibArchiveKit](https://code.byted.org/ee/LibArchive) 基于开源库 **[libarchive](https://github.com/libarchive/libarchive)** 实现，支持解压 .zip、.rar4/5、.tar、.gz、.bz2 等多种压缩文件，提供获取压缩文件目录数据、按需解压、判断是否加密等能力。


## 使用方法

### LibArchiveFile

LibArchiveFile 是对于一个压缩文件的抽象，并且提供获取文件列表信息、是否加密等接口

```swift
public class LibArchiveFile {

    // 初始化方法
    // path: 压缩文件路径
    public init(path: String) throws {}
    
    /// 是否加密
    public private(set) var isEncrypted: Bool
	
    /// 压缩文件类型
	public private(set) var format: ArchiveFormat = .unknown

    /// 解析出压缩文件目录信息
    public func parseFileList() throws -> [LibArchiveEntry] {}

    /// 按需解压文件到指定目录
    /// - Parameters:
    ///  - entryName: 按需解压的文件（ArchiveEntry 的相对路径）
    ///  - toDir: 解压目录
    ///  - passcode: 密码
    ///  - completion: 解压结果
    public func extract(entryPath: String, toDir: URL, passcode: String? = nil) throws {}
    
    /// 全量解压文件到指定目录
    public func extract(toDir: URL, passcode: String? = nil) throws {}

}
```

### LibArchiveEntry

对压缩文件内的每一个节点的抽象，它可以是目录或者是文件

```swift
public struct LibArchiveEntry {

    enum EntryType {
        // 目录
        case directory
        // 文件
        case file
    }

    // 文件类型
    var type: EntryType

    // 文件相对于压缩文件内的路径
    var path: String

    // 文件大小
    var size: UInt64

}
```



### 使用例子

```Swift
// 全量解压
private func libArchiveSwift(url: URL) {
    let unZipPath = NSTemporaryDirectory() + url.lastPathComponent
    DispatchQueue.global().async {
        do {
            let archive = try LibArchiveFile(path: url.path)
            if archive.isEncrypted == true {
                try archive.extract(toDir: URL(fileURLWithPath: unZipPath), passcode: "123456")
            } else {
                try archive.extract(toDir: URL(fileURLWithPath: unZipPath))
            }
        } catch {
            let error = error as? LibArchiveError
            print("-----error: \(String(describing: error?.localizedDescription))")
        }
    }
}

// 按需解压
func libArchiveSingle(url: URL, entryPath: String) {
    let unZipPath = NSTemporaryDirectory() + url.lastPathComponent
    let archive = try? LibArchiveFile(path: url.path)
    try? archive?.extract(entryPath: entryPath, toDir: URL(fileURLWithPath: unZipPath))
}
```



更具体使用方式，可以查看项目 LibArchiveExample 的 ViewController 里。

