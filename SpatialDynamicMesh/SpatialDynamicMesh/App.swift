import SwiftUI

@main
struct SpatialDynamicMeshApp: App {
    
    var body: some Scene {
        WindowGroup() {
            // ContentView()
            // FibonacciLatticeView()
            // MorphingSphereMetalView()
            FractalAnimationLowLevelTextureView()
        }
        #if os(visionOS)
        .windowStyle(.volumetric)
        .defaultSize(width: 1.0, height: 1.0, depth: 0.3, in: .meters)
        #endif
    }
}
