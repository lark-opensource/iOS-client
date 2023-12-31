//
//  WavFile.swift
//  LarkChat
//
//  Created by 李晨 on 2019/2/27.
//

import Foundation

// disable-lint: magic number

// Endian 参见 https://zh.wikipedia.org/wiki/%E5%AD%97%E8%8A%82%E5%BA%8F#%E5%B0%8F%E7%AB%AF%E5%BA%8F

// Add WAV headers to the decoded PCM data.
// Refer to the documentation here for details: http://soundfile.sapp.org/doc/WaveFormat/

//swiftlint:disable missing_docs line_length

/// WavHeader struct, **请勿轻易改动属性**，尤其是属性的增删改；
/// 由于在 `toData()` 方法中，直接Copy了该结构的内存到 Data 中，
/// 所以任何对属性的修改都可能导致最后导出的数据无法解析；
///
/// 慎重！慎重！慎重！
///
/// WavHeader 布局如下:
///
/// =======================================================================================
/// | Endian | Offset | Field Name    | Field Size    |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - |
/// | Big    | 0      | ChunkID       | 4             |  **The "RIFF" chunk descriptor**  |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 4      | ChunkSize     | 4             |  The Format of concern here i     |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |  "WAVE", which requires two       |
/// | Big    | 8      | Format        | 4             |  sub-chunks: "ft " and "data"     |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |- - - - - - - - - - - - - - - - - -|
/// | Big    | 12     | SubChunk1ID   | 4             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 16     | SubChunk1Size | 4             |  **The "fit " sub-chunk**         |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 20     | AudioFormat   | 2             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |  describes the format of          |
/// | Little | 22     | NumChannels   | 2             |  the sound information in         |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |  the data sub-chunk               |
/// | Little | 24     | SampleRate    | 4             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 28     | ByteRate      | 4             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 32     | BlockAlign    | 2             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 34     | BitsPerSample | 2             |                                   |
/// | - - - - - - - - - - - - - - - - - - - - - - - - | - - - - - - - - - - - - - - - - - |
/// | Big    | 36     | SubChunk2ID   | 4             |  **The "data" sub-chunk**         |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |                                   |
/// | Little | 40     | SubChunk2Size | 4             |  Indicates the size of the        |
/// | - - - - - - - - - - - - - - - - - - - - - - - - |  sound information and            |
/// | Little | 44     | data          | SubChunk2Size |  contains the raw sound data      |
/// =======================================================================================

public struct WavHeader {
    public typealias FourByte = (UInt8, UInt8, UInt8, UInt8)
    public static let headerSize: Int32 = 44

    public let chunkID: FourByte = (82, 73, 70, 70)            //4byte,big-endian 资源交换文件标志: "RIFF"
    public let chunkSize: Int32                                //4byte,litte-endian 从下个地址到文件结尾的总字节数
    public let format: FourByte = (87, 65, 86, 69)             //4byte,big-endian wave文件标志: "WAVE"
    public let subchunk1ID: FourByte = (102, 109, 116, 32)     //4byte,big-endian 波形文件标志: "fmt "
    public let subchunk1Size: Int32 = Int32(16)                //4byte,litte-endian 音频属性(audioFormat,numChannels,sampleRate,byteRate,blockAlign,bitsPerSample)所占字节数
    public let audioFormat = Int16(1)                          //2byte,litte-endian 编码格式(1-线性pcm-WAVE_FORMAT_PCM,WAVEFORMAT_ADPCM)
    public let numChannels: Int16                              //2byte,litte-endian 通道数
    public let sampleRate: Int32                               //4byte,litte-endian 采样率
    public let byteRate: Int32                                 //4byte,litte-endian 传输速率
    public let blockAlign: Int16                               //2byte,litte-endian 数据块的对齐
    public let bitsPerSample: Int16                            //2byte,big-endian 采样精度 采样深度
    public let subchunk2ID: FourByte = (100, 97, 116, 97)      //4byte,litte-endian 数据标志: "data"
    public let subchunk2Size: Int32                            //4byte,litte-endian pcm data length

    public init(
        dataSize: Int32,
        numChannels: Int16,
        sampleRate: Int32,
        bitsPerSample: Int16 = Int16(16)
    ) {
        self.chunkSize = Int32(dataSize + WavHeader.headerSize - 4)
        self.numChannels = numChannels
        self.sampleRate = sampleRate
        self.byteRate = Int32(sampleRate * Int32(numChannels) * Int32(bitsPerSample) / Int32(Data.Element.bitWidth))
        self.blockAlign = Int16(numChannels * bitsPerSample / Int16(Data.Element.bitWidth))
        self.bitsPerSample = bitsPerSample
        self.subchunk2Size = dataSize
    }

    public init?(data: Data) {
        if !WavFile.isWavFormat(data) { return nil }
        if data.count < WavHeader.headerSize { return nil }

        let dataSizeRange = Range(uncheckedBounds: (lower: 40, upper: 44))
        let dataSizeData = data.subdata(in: dataSizeRange)
        let dataSize: Int32 = Int32(
            littleEndian: dataSizeData.withUnsafeBytes {
                $0.baseAddress!.bindMemory(to: Int32.self, capacity: MemoryLayout<Int32>.stride).pointee
            }
        )

        let numChannelsRange = Range(uncheckedBounds: (lower: 22, upper: 24))
        let numChannelsData = data.subdata(in: numChannelsRange)
        let numChannels: Int16 = Int16(
            littleEndian: numChannelsData.withUnsafeBytes {
                $0.baseAddress!.bindMemory(to: Int16.self, capacity: MemoryLayout<Int32>.stride).pointee
            }
        )

        let sampleRateRange = Range(uncheckedBounds: (lower: 24, upper: 28))
        let sampleRateData = data.subdata(in: sampleRateRange)
        let sampleRate: Int32 = Int32(
            littleEndian: sampleRateData.withUnsafeBytes {
                $0.baseAddress!.bindMemory(to: Int32.self, capacity: MemoryLayout<Int32>.stride).pointee
            }
        )

        let bitsPerSampleRange = Range(uncheckedBounds: (lower: 34, upper: 36))
        let bitsPerSampleData = data.subdata(in: bitsPerSampleRange)
        let bitsPerSample: Int16 = Int16(littleEndian: bitsPerSampleData.withUnsafeBytes {
                $0.baseAddress!.bindMemory(to: Int16.self, capacity: MemoryLayout<Int16>.stride).pointee
            }
        )

        self.init(dataSize: dataSize, numChannels: numChannels, sampleRate: sampleRate, bitsPerSample: bitsPerSample)
    }

    public func toData() -> Data {
        var tmp = self
        return Data(bytes: &tmp, count: MemoryLayout<WavHeader>.stride)
    }
}

public final class WavFile {
    public let header: WavHeader
    public let pcmData: PCMData

    public init?(data: Data) {
        guard let header = WavHeader(data: data) else { return nil }
        self.header = header
        self.pcmData = PCMData(
            data: Data(data[WavHeader.headerSize...]),
            numChannels: header.numChannels,
            sampleRate: header.sampleRate,
            bitsPerSample: header.bitsPerSample
        )
    }

    public static func isWavFormat(_ data: Data) -> Bool {
        // resources for WAV header format:
        // [1] http://unusedino.de/ec64/technical/formats/wav.html
        // [2] http://soundfile.sapp.org/doc/WaveFormat/

        let riffHeaderChunkIDOffset = 0
        let riffHeaderChunkIDSize = 4
        let riffHeaderChunkSizeOffset = 8
        let riffHeaderChunkSizeSize = 4
        let riffHeaderSize = 12

        guard data.count >= riffHeaderSize else {
            return false
        }

        let riffChunkID = dataToUTF8String(data: data, offset: riffHeaderChunkIDOffset, length: riffHeaderChunkIDSize)
        guard riffChunkID == "RIFF" else {
            return false
        }

        let riffFormat = dataToUTF8String(
            data: data,
            offset: riffHeaderChunkSizeOffset,
            length: riffHeaderChunkSizeSize
        )
        guard riffFormat == "WAVE" else {
            return false
        }

        return true
    }

    private static func dataToUTF8String(data: Data, offset: Int, length: Int) -> String? {
        let range = Range(uncheckedBounds: (lower: offset, upper: offset + length))
        let subdata = data.subdata(in: range)
        return String(data: subdata, encoding: String.Encoding.utf8)
    }
}
