# Cinder-Metal

### Overview
A [Cinder](http://libcinder.org) block for [Apple's Metal](https://developer.apple.com/metal/) graphics API.

For a brief summary of the Metal architecture, refer to the [architecture description](https://github.com/wdlindmeier/Cinder-Metal/blob/master/Metal%20Architecture.txt) and the [architecture diagram](https://github.com/wdlindmeier/Cinder-Metal/blob/master/Metal%20Diagram.png). The block API is designed to have a 1:1 class mapping with the Objective-C API, with a few exceptions. With this in mind, users should refer to the [Apple documentation](https://developer.apple.com/library/ios/documentation/MetalKit/Reference/MTKFrameworkReference/index.html#//apple_ref/doc/uid/TP40015356) for usage instructions. Also, see "Gotchas" below.

### Up and Running
Once you've created an app using the Metal Basic template in TinderBox, follow these steps to get it building:  

* Change the Deployment Target to iOS >= 9.0 or Mac OS >= 10.11 in the Project "Info" tab.  
* Enable "Automatic Reference Counting" in the Target Build Settings.  
* Add the Metal Framework to your target in Build Phases > Link Binaries with Libraries.  
* If you're building for OS X, also add the QuartzCore Framework.  
* If you want to include block headers in your Metal shaders, add this path to  
	Build Settings > Metal > Header Search Paths:
	`$(CINDER_PATH)/blocks/Cinder-Metal/include`

### Samples
The easiest way to get started is to edit a sample project found in samples/.

### Usage Notes

**Metal Renderer**  
Metal and OpenGL are mutually exclusive. To use Metal with your Cinder app,  replace the OpenGL renderer (RendererGl) with the Metal Renderer (RendererMetal) in the CINDER_APP macro. In addition, all calls to the gl:: namespace should be replaced with calls to the mtl:: namespace. 

**Buffers**  
Most data is passed between the CPU and GPU as buffers. The Metal block uses the DataBuffer class for arbitrary data (e.g. uniforms and vertices) and the TextureBuffer class for image data.

**Scopes**  
Command Buffers and Encoders are generally created, modified and committed once per draw loop. For convenience, the block has Scoped versions of these classes which will automatically be committed when they fall out of scope. 

**Render Pipelines**  
Render pipelines are similar to gl::GlslProgs; they specify the vertex and frag shaders, but also specify some additional state such as the blend mode and sample count.

**Render Command Buffer**  
This class doesn't have an equvalent Objective-C implementation, it's just useful for Cinder apps. It's a subclass of CommandBuffer that contains a reference to the next "drawable", and also presents that drawable when it's committed. You'll generally use one of these per `draw()` call.

**Number of Inflight Buffers**  
Metal generally has multiple Command Buffers at various points of execution, referred to as "inflight buffers." This improves concurrency across the CPU and GPU. One important consideration is that the CPU and GPU have access to the same memory at different points in the pipeline, and you don't want your CPU to overwrite data that the GPU hasn't rendered yet. To account for this, you should make your mutating buffers large enough for multiple copies of the data (each mapping to a frame), and offset the "current" data using the current inflight buffer index. The default number of inflight buffers is 3, but this can be changed in the RendererMetal::Options.

### Using the Metal API directly 
This block is still a work in progress, and you may find a reason to call the Objective-C Metal API directly. All of the C++ classes found in this block have accessors to their native Objective-C implementations using the `getNative()` accessor, as well as constructors that take a native instance (generally as a `void *`). To make Objective-C calls in your Cinder app, change the .cpp suffix of your App file to .mm.

### Gotchas

**BufferedLayout and MTLVertexDescriptor**  
For indexed draw calls, Metal has a class called [MTLVertexDescriptor](https://developer.apple.com/library/ios/documentation/Metal/Reference/MTLVertexDescriptor_Ref/), which maps buffered attributes to the shader. This class duplicates much of the behavior found in Cinder's BufferLayout, so we've opted to use BufferLayout instead. The benefit of this decision is that the data layout is defined per-buffer, rather than per-pipeline, and it's also a familiar API. However, this means that the indexed data is accessed in a slightly different way than the idiomatic Metal approach. See the vertex shader in the "Cube" sample for an example of how the attributes are accessed using BufferLayout. If you prefer to use MTLVertexDescriptor, you can still use the Objective-C API.

**GPU Support**  
While Metal on iOS devices is pretty solid, driver support for laptop GPUs is still catching up. On MacBooks, the discreet and integrated GPUs have been known to render things slightly differently. You can download [gfxCardStatus](https://gfx.io/) to show which GPU you're using, and manually switch between them for debugging.
