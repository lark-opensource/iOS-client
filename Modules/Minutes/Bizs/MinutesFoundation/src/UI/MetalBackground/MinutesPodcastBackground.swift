//
//  MinutesPodcastBackground.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/4/6.
//

import Foundation
import Metal
import MetalKit
import SnapKit

struct LYVertex {
    var position: vector_float4
    var textureCoordinate: vector_float2
}

enum VertexInputIndex: Int {
    case vertices = 0
}

enum FragmentInputIndex: Int {
    case texture = 0
    case uniforms = 1
}

struct UniformParameters {
    internal init(resolution: vector_float2, time: Float, slot1: Float, slot2: Float, params: Params) {
        self.resolution = resolution
        self.time = time
        self.slot1 = slot1
        self.slot2 = slot2
        self.noiseFactor = params.noiseFactor
        self.noiseDisplacement = params.noiseDisplacement
        self.offset = vector_float2(params.offsetX, params.offsetY)
        self.sampleScale = params.sampleScale
        self.flowSpeed = params.flowSpeed
        self.saturation = params.saturation
    }

    var resolution: vector_float2
    var time: Float
    var slot1: Float
    var slot2: Float
    var noiseFactor: Float
    var noiseDisplacement: Float
    var offset: vector_float2
    var sampleScale: Float
    var flowSpeed: Float
    var saturation: Float

}

public struct Params {
    public init(noiseFactor: Float, noiseDisplacement: Float, offsetX: Float, offsetY: Float, sampleScale: Float, flowSpeed: Float, saturation: Float) {
        self.noiseFactor = noiseFactor
        self.noiseDisplacement = noiseDisplacement
        self.offsetX = offsetX
        self.offsetY = offsetY
        self.sampleScale = sampleScale
        self.flowSpeed = flowSpeed
        self.saturation = saturation
    }

    let noiseFactor: Float
    let noiseDisplacement: Float
    let offsetX: Float
    let offsetY: Float
    let sampleScale: Float
    let flowSpeed: Float
    let saturation: Float

    // disable-lint: magic number
    public static let `default` = Params(noiseFactor: 130, noiseDisplacement: 0.3, offsetX: 0, offsetY: 0, sampleScale: 1.3, flowSpeed: 0.15, saturation: 0.8)
    // enable-lint: magic number
}

public final class MinutesPodcastBackgroundView: UIView {

    var params: Params = .default

    lazy var flowBGView: MTKView = {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = self
        return view
    }()

    var viewportSize: vector_uint2 {
        return vector_uint2(UInt32(flowBGView.drawableSize.width), UInt32(flowBGView.drawableSize.height))
    }

    lazy var pipelineState: MTLRenderPipelineState? = {
        let defaultLibrary = try? flowBGView.device?.makeDefaultLibrary(bundle: BundleConfig.MinutesFoundationBundle) // .metal
        let vertexFunction = defaultLibrary?.makeFunction(name: "vertexShader") // 顶点shader，vertexShader是函数名
        let fragmentFunction = defaultLibrary?.makeFunction(name: "samplingShader") // 片元shader，samplingShader是函数名

        guard vertexFunction != nil, fragmentFunction != nil else { return nil }

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.flowBGView.colorPixelFormat
        return try? flowBGView.device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor) // 创建图形渲染管道，耗性能操作不宜频繁调用
    }()

    lazy var commandQueue: MTLCommandQueue? = {
        _ = self.pipelineState
        return flowBGView.device?.makeCommandQueue()
    }()

    lazy var vertices: MTLBuffer? = {
        let bytes = [
            LYVertex(position: vector_float4(1, -1, 0, 1), textureCoordinate: vector_float2(0, 0)),
            LYVertex(position: vector_float4(-1, -1, 0, 1), textureCoordinate: vector_float2(0, 1)),
            LYVertex(position: vector_float4(-1, 1, 0, 1), textureCoordinate: vector_float2(0, 0)),
            LYVertex(position: vector_float4(1, -1, 0, 1), textureCoordinate: vector_float2(1, 1)),
            LYVertex(position: vector_float4(-1, 1, 0, 1), textureCoordinate: vector_float2(0, 0)),
            LYVertex(position: vector_float4(1, 1, 0, 1), textureCoordinate: vector_float2(1, 0))
                ]
        let vertices = flowBGView.device?.makeBuffer(bytes: bytes, length: MemoryLayout<LYVertex>.stride * bytes.count, options: .storageModeShared)
        return vertices
    }()

    var numVertices = 6

    let startTime: Date = Date()

    var texture: MTLTexture?

    var parameters: UniformParameters {
        let time = Date().timeIntervalSince(startTime)
        let resolution = vector_float2(Float(bounds.size.width), Float(bounds.size.height))
        return UniformParameters(resolution: resolution, time: Float(time), slot1: 1, slot2: 0, params: params)
    }

    public var image: UIImage {
        didSet {
            loadTexture()
        }
    }

    public required init(background image: UIImage) {
        self.image = image
        super.init(frame: .zero)
        addSubview(flowBGView)
        flowBGView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        loadTexture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadTexture() {
        let imageWidth = Int(self.image.size.width)
        let imageHeight = Int(self.image.size.height)
        guard imageWidth > 0, imageHeight > 0 else { return }
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = imageWidth
        textureDescriptor.height = imageHeight
        let texture = flowBGView.device?.makeTexture(descriptor: textureDescriptor)
        let region = MTLRegionMake3D(0, 0, 0, Int(image.size.width), Int(image.size.height), 1)
        if let spriteImage = image.cgImage {
            let width = spriteImage.width
            let height = spriteImage.height
            var spriteData: [UInt8] = [UInt8](repeating: 0, count: width * height * 4)

            var space = spriteImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            if !space.supportsOutput {
                space = CGColorSpaceCreateDeviceRGB()
            }

            let spriteContext = CGContext(data: &spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

            spriteContext?.draw(spriteImage, in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))

            texture?.replace(region: region, mipmapLevel: 0, withBytes: spriteData, bytesPerRow: 4 * width)
        }
        self.texture = texture
    }
}

extension MinutesPodcastBackgroundView: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    // disable-lint: magic number
    public func draw(in view: MTKView) {
        guard view.bounds != .zero else {
            return
        }

        guard let state = pipelineState else { return }

        if let texture = self.texture, let commandBuffer = self.commandQueue?.makeCommandBuffer() {
            if let renderPassDescriptor = view.currentRenderPassDescriptor {
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 0.5, 1.0)
                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

                renderEncoder?.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: -1, zfar: 1))

                renderEncoder?.setRenderPipelineState(state)

                renderEncoder?.setVertexBuffer(vertices, offset: 0, index: VertexInputIndex.vertices.rawValue)

                renderEncoder?.setFragmentTexture(texture, index: FragmentInputIndex.texture.rawValue)
                var parameters = self.parameters
                renderEncoder?.setFragmentBytes(&parameters, length: MemoryLayout<UniformParameters>.stride, index: FragmentInputIndex.uniforms.rawValue)

                renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: numVertices)

                renderEncoder?.endEncoding()

                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }

            commandBuffer.commit()
        }
    }
    // enable-lint: magic number

}
