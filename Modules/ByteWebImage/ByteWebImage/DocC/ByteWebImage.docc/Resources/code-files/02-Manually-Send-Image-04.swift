import ByteWebImage

// 创建压缩转码类
let sendImageProcessor = SendImageProcessorImpl()

// 方法1: 使用setting配置的默认参数，选择原图/非原图压缩
func process(source: ImageProcessSourceType, option: ImageProcessOptions, scene: Scene) -> ImageProcessResult?

// 方法2: 使用自定义参数，压缩转码图片
func process(source: ImageProcessSourceType, options: ImageProcessOptions,
             destPixel: Int, compressRate: Float, scene: Scene) -> ImageProcessResult?
