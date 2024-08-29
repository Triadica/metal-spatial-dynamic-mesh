
import SwiftUI
import RealityKit

struct FractalAnimationLowLevelTextureView: View {
    @State var texture: LowLevelTexture?
    let commandQueue: MTLCommandQueue
    let computePipeline: MTLComputePipelineState
    
    @State private var timer: Timer?
    @State var time: Float = 0
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        
        let library = device.makeDefaultLibrary()!
        
        let updateFunction = library.makeFunction(name: "fractalTextureShader")!
        self.computePipeline = try! device.makeComputePipelineState(function: updateFunction)
    }
    
    var body: some View {
        RealityView { content in
            let entity = try! getEntity()
            content.add(entity)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }
    
    func startTimer() {
       timer = Timer.scheduledTimer(withTimeInterval: 1/120, repeats: true) { _ in
           DispatchQueue.main.async {
               updateTexture()
           }
       }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func getEntity() throws -> Entity {
        let mesh = MeshResource.generatePlane(width: 1.0, height: 1.0)
        let texture = try LowLevelTexture(descriptor: textureDescriptor)
        let resource = try TextureResource(from: texture)
        var material = UnlitMaterial()
        material.color.texture = .init(resource)
        material.opacityThreshold = 0.5
        let modelComponent = ModelComponent(mesh: mesh, materials: [material])
        let entity = Entity()
        entity.components.set(modelComponent)
        entity.scale *= 0.4
        entity.transform.rotation = .init(angle: .pi * 0.5, axis: [0,0,-1])

        self.texture = texture
        return entity
    }
    
    func updateTexture() {
        guard let texture else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else { return }

        commandBuffer.enqueue()

        computeEncoder.setComputePipelineState(computePipeline)

        let outTexture: MTLTexture = texture.replace(using: commandBuffer)
        computeEncoder.setTexture(outTexture, index: 0)

        time += 0.1
        var timeBuffer = [time]
        computeEncoder.setBytes(&timeBuffer, length: MemoryLayout<Float>.size, index: 0)
        
        // Calculate the thread group sizes
        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        let threadGroupSize = MTLSizeMake(w, h, 1)
        let threadGroupCount = MTLSizeMake(
            (textureDescriptor.width + threadGroupSize.width - 1) / threadGroupSize.width,
            (textureDescriptor.height + threadGroupSize.height - 1) / threadGroupSize.height,
            1)

        computeEncoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)

        // End the encoding and commit the command buffer.
        // When the command buffer completes, RealityKit automatically applies the changes.
        computeEncoder.endEncoding()
        commandBuffer.commit()
    }
    
    var textureDescriptor: LowLevelTexture.Descriptor {
        var desc = LowLevelTexture.Descriptor()

        desc.textureType = .type2D
        desc.arrayLength = 1

        desc.width = 2048
        desc.height = 2048
        desc.depth = 1

        desc.mipmapLevelCount = 1
        desc.pixelFormat = .bgra8Unorm
        desc.textureUsage = [.shaderRead, .shaderWrite]
        desc.swizzle = .init(red: .red, green: .green, blue: .blue, alpha: .alpha)

        return desc
    }
}

#Preview {
    FractalAnimationLowLevelTextureView()
}
