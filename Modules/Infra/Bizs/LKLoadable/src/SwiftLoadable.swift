//
//  SwiftLoadable.swift
//  Pods
//
//  Created by sniperj on 2022/1/9.
//

import Foundation
import MachO
import EEAtomic

#if arch(arm64) || arch(x86_64)
typealias LOADABLEUInt = UInt64
let loadableRecursiveThreshold = 63
typealias LoadableSegmentCommand = segment_command_64
typealias LoadableMachHeader = mach_header_64
let loadableLCSegment = LC_SEGMENT_64
#else
typealias LOADABLEUInt = UInt32
let loadableRecursiveThreshold = 31
typealias LoadableSegmentCommand = segment_command
typealias LoadableMachHeader = mach_header
let loadableLCSegment = LC_SEGMENT
#endif

public final class SwiftLoadable {
    private typealias ExcuteFunc = @convention(thin) () -> Void

    var exportedSymbols: [String: UnsafeMutableRawPointer?] = [:]

    var organizedSymbols: [String: [UnsafeMutableRawPointer?]] = [:]

    static private var excuteKey: [String] = []

    static private var unfairLock = os_unfair_lock_s()

    static let loadableQueue = DispatchQueue(label: "lark.loadable.queue")

    static let `default` = SwiftLoadable(namespace: "Lark")

    private static let dispatchOnceToken = AtomicOnce()

    private static let linkeditName = SEG_LINKEDIT.utf8CString

    var namespace: String
    lazy var fullNamespace = "_" + namespace + "."

    public convenience init(namespace: String) {
        self.init(name: namespace)
        setup()
    }

    @discardableResult
    /// start regist func
    /// - Parameter key: key
    /// - Returns: if return false means success excute
    private static func start(key: String) -> Bool {
        return SwiftLoadable.default.start(key: key)
    }

    @discardableResult
    /// start regist func only once
    /// - Parameter key: key
    /// - Returns: if return false means success excute
    public static func startOnlyOnce(key: String) -> Bool {
        os_unfair_lock_lock(&unfairLock)
        defer {
            os_unfair_lock_unlock(&unfairLock)
        }
        if excuteKey.contains(key) {
            return false
        }
        excuteKey.append(key)
        return Self.start(key: key)
    }

    @discardableResult
    func start(key: String) -> Bool {

        var symbols: [UnsafeMutableRawPointer?] = []
        Self.loadableQueue.sync {
            guard let organizedKeySymbols = organizedSymbols[key] else {
                exportedSymbols.forEach { (fullKey, symbol) in
                    if fullKey.hasPrefix(fullNamespace + key + ".") || fullKey == fullNamespace + key {
                        symbols.append(symbol)
                        exportedSymbols.removeValue(forKey: fullKey)
                    }
                }
                organizedSymbols[key] = symbols
                return
            }
            symbols = organizedKeySymbols
        }
        symbols.forEach { symbol in
            let f = unsafeBitCast(symbol, to: ExcuteFunc.self)
            f()
        }
        return symbols.isEmpty
    }

    private init(name: String) {
        self.namespace = name
    }

    private func setup() {
        for i in 0..<_dyld_image_count() {
            let image = String(cString: _dyld_get_image_name(i))
            if !image.hasPrefix(Bundle.main.bundlePath) {
                continue
            }
            let exportedSymbols = getExportedSymbols(image: _dyld_get_image_header(i), slide: _dyld_get_image_vmaddr_slide(i))
            exportedSymbols.forEach { (key, symbol) in
                Self.loadableQueue.sync {
                    addSymbol(key: key, symbol: symbol)
                }
            }
        }
    }

    private func getExportedSymbols(image: UnsafePointer<mach_header>!, slide: Int) -> [String: UnsafeMutableRawPointer?] {
        var linkeditCmd: UnsafeMutablePointer<LoadableSegmentCommand>!
        var dynamicLoadInfoCmd: UnsafeMutablePointer<dyld_info_command>!
        var linkeditDataCmd: UnsafeMutablePointer<linkedit_data_command>!
        var curCmd = UnsafeMutableRawPointer(mutating: image).advanced(by: MemoryLayout<LoadableMachHeader>.size).assumingMemoryBound(to: LoadableSegmentCommand.self)
        var symbols = [String : UnsafeMutableRawPointer?]()
        var exportedInfoOffset: Int = 0
        var exportedInfoSize: Int = 0
        for _ in 0..<image.pointee.ncmds {
            if curCmd.pointee.cmd == loadableLCSegment,
               curCmd.pointee.segname.0 == Self.linkeditName[0],
               curCmd.pointee.segname.1 == Self.linkeditName[1],
               curCmd.pointee.segname.2 == Self.linkeditName[2],
               curCmd.pointee.segname.3 == Self.linkeditName[3],
               curCmd.pointee.segname.4 == Self.linkeditName[4],
               curCmd.pointee.segname.5 == Self.linkeditName[5],
               curCmd.pointee.segname.6 == Self.linkeditName[6],
               curCmd.pointee.segname.7 == Self.linkeditName[7],
               curCmd.pointee.segname.8 == Self.linkeditName[8],
               curCmd.pointee.segname.9 == Self.linkeditName[9] {
                linkeditCmd = curCmd
            } else if curCmd.pointee.cmd == LC_DYLD_INFO_ONLY || curCmd.pointee.cmd == LC_DYLD_INFO {
                dynamicLoadInfoCmd = curCmd.withMemoryRebound(to: dyld_info_command.self, capacity: 1, { $0 })
            } else if curCmd.pointee.cmd == LC_DYLD_EXPORTS_TRIE {
                linkeditDataCmd = curCmd.withMemoryRebound(to: linkedit_data_command.self, capacity: 1, { $0 })
            }
            let curCmdSize = Int(curCmd.pointee.cmdsize)
            let temCurCmd = curCmd.withMemoryRebound(to: Int8.self, capacity: 1, { $0 }).advanced(by: curCmdSize)
            curCmd = temCurCmd.withMemoryRebound(to: LoadableSegmentCommand.self, capacity: 1, { $0 })
        }
        if linkeditCmd == nil {
            return symbols
        }
        let linkeditBase = slide + Int(linkeditCmd.pointee.vmaddr) - Int(linkeditCmd.pointee.fileoff)
        if dynamicLoadInfoCmd != nil {
            exportedInfoOffset = Int(dynamicLoadInfoCmd.pointee.export_off)
            exportedInfoSize = Int(dynamicLoadInfoCmd.pointee.export_size)
        } else if linkeditDataCmd != nil {
            exportedInfoOffset = Int(linkeditDataCmd.pointee.dataoff)
            exportedInfoSize = Int(linkeditDataCmd.pointee.datasize)
        }
        guard exportedInfoSize > 0 else {
            return symbols
        }
        guard let exportedInfo = UnsafeMutableRawPointer(bitPattern: linkeditBase + exportedInfoOffset)?.assumingMemoryBound(to: UInt8.self) else {
            return symbols
        }

        trieWalk(image: image, start: exportedInfo, loc: exportedInfo, end: exportedInfo + exportedInfoSize, currentSymbol: "", symbols: &symbols)
        return symbols
    }

    private func trieWalk(image: UnsafePointer<mach_header>!,
                          start: UnsafeMutablePointer<UInt8>,
                          loc: UnsafeMutablePointer<UInt8>,
                          end: UnsafeMutablePointer<UInt8>,
                          currentSymbol: String,
                          symbols: inout [String: UnsafeMutableRawPointer?]) {
        var p = loc
        if p <= end {
            var terminalSize = LOADABLEUInt(p.pointee)

            if terminalSize > 127 {
                p -= 1
                terminalSize = Self.readUleb128(p: &p, end: end)
            }
            if terminalSize != 0 {
                guard currentSymbol.hasPrefix(fullNamespace) else {
                    return
                }

                let returnSwiftSymbolAddress = { () -> UnsafeMutableRawPointer in
                    let machO = image.withMemoryRebound(to: Int8.self, capacity: 1, { $0 })
                    let swiftSymbolAddress = machO.advanced(by: Int(Self.readUleb128(p: &p, end: end)))
                    return UnsafeMutableRawPointer(mutating: swiftSymbolAddress)
                }

                p += 1
                let flags = Self.readUleb128(p: &p, end: end)

                switch flags & LOADABLEUInt(EXPORT_SYMBOL_FLAGS_KIND_MASK) {
                case LOADABLEUInt(EXPORT_SYMBOL_FLAGS_KIND_REGULAR):
                    symbols[currentSymbol] = returnSwiftSymbolAddress()
                case LOADABLEUInt(EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL):
                    if flags & LOADABLEUInt(EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER) != 0 {
                    }
                case LOADABLEUInt(EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE):
                    if flags & LOADABLEUInt(EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER) != 0 {
                    }
                    symbols[currentSymbol] = UnsafeMutableRawPointer(bitPattern: UInt(Self.readUleb128(p: &p, end: end)))
                default:
                    break
                }
            }

            let child = loc.advanced(by: Int(terminalSize + 1))
            let childCount = child.pointee
            p = child + 1
            for _ in 0 ..< childCount {
                let nodeLabel = String(cString: p.withMemoryRebound(to: CChar.self, capacity: 1, { $0 }), encoding: .utf8)
                // advance to the end of node's label
                while p.pointee != 0 {
                    p += 1
                }

                // so advance to the child's node
                p += 1
                let nodeOffset = Int(Self.readUleb128(p: &p, end: end))
                if nodeOffset != 0, let nodeLabel = nodeLabel {
                    let symbol = currentSymbol + nodeLabel
                    if symbol.lengthOfBytes(using: .utf8) > 0 && (symbol.hasPrefix(fullNamespace) || fullNamespace.hasPrefix(symbol)) {
                        trieWalk(image: image, start: start, loc: start.advanced(by: nodeOffset), end: end, currentSymbol: symbol, symbols: &symbols)
                    }
                }
            }
        }
    }

    /// http://www.itkeyword.com/doc/143214251714949x965/uleb128p1-sleb128-uleb128
    private static func readUleb128(p: inout UnsafeMutablePointer<UInt8>, end: UnsafeMutablePointer<UInt8>) -> LOADABLEUInt {
        var result: LOADABLEUInt = 0
        var bit = 0
        var readNext = true

        repeat {
            if p == end {
                assert(false, "malformed uleb128")
            }
            let slice = LOADABLEUInt(p.pointee & 0x7f)
            if bit > loadableRecursiveThreshold {
                assert(false, "uleb128 too big for loadableUIntType")
            } else {
                result |= (slice << bit)
                bit += 7
            }
            readNext = (p.pointee & 0x80) != 0
            p += 1
        } while (readNext)

        return result
    }

    private func addSymbol(key: String, symbol: UnsafeMutableRawPointer?) {
        self.exportedSymbols[key] = symbol
    }

}
