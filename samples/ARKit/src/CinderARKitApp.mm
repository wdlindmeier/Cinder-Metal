#include "CinderARKitApp.h"
#import "NativeBridge.h"

using namespace ci;
using namespace ci::app;
using namespace std;

#pragma mark - Setup

void CinderARKitApp::setup()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create();
    
    mObjcDelegate = [[NativeBridge alloc] initWithApp:this];
    mARSession = [ARSession new];
    mARSession.delegate = mObjcDelegate;
    
    ARWorldTrackingSessionConfiguration *configuration = [ARWorldTrackingSessionConfiguration new];
    configuration.planeDetection = ARPlaneDetectionHorizontal;
    [mARSession runWithConfiguration:configuration];
    
    UITapGestureRecognizer *tapGesture2 = [[UITapGestureRecognizer alloc] initWithTarget:mObjcDelegate action:@selector(handleDoubleTap:)];
    tapGesture2.numberOfTapsRequired = 2;
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:mObjcDelegate action:@selector(handleSwipe:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture2];
    [gestureRecognizers addObject:swipeGesture];
    
    UIView *view = getWindow()->getNativeViewController().view;
    [gestureRecognizers addObjectsFromArray:view.gestureRecognizers];
    view.gestureRecognizers = gestureRecognizers;
    
    CVMetalTextureCacheCreate(NULL, NULL, [RendererMetalImpl sharedRenderer].device,
                              NULL, &mCapturedImageTextureCache);
    
    mPipelineVideo = mtl::RenderPipelineState::create("simple_vertex", "camera_fragment");
    
    mBatchCamera = mtl::Batch::create(geom::Rect(Rectf(-1,-1,1,1)).texCoords( vec2(0,1),
                                                                              vec2(1,1),
                                                                              vec2(1,0),
                                                                              vec2(0,0)),
                                      mPipelineVideo);
}

void CinderARKitApp::resize()
{
}

void CinderARKitApp::restart()
{
    console() << "restart\n";
    mPlaneIntersections.clear();
    mLastHorizontalPlane = mat4(1);
    mPlanePosition = vec3(-1);
    mHumanPosition = vec3(-1);
    for ( ARAnchor * a in mARSession.currentFrame.anchors )
    {
        [mARSession removeAnchor:a];
    }
}

#pragma mark - Helpers

mat4 modelMatFromTransform( matrix_float4x4 transform );
mat4 modelMatFromTransform( matrix_float4x4 transform )
{
    matrix_float4x4 coordinateSpaceTransform = matrix_identity_float4x4;
    // Flip Z axis to convert geometry from right handed to left handed
    coordinateSpaceTransform.columns[2].z = -1.0;
    matrix_float4x4 modelMat = matrix_multiply(transform, coordinateSpaceTransform);
    return fromMtl(modelMat);
}

#pragma mark - User Gestures

void CinderARKitApp::touchesBegan( TouchEvent event )
{
    mNumTouches += event.getTouches().size();
    if ( mNumTouches == 2 )
    {
        // Add an anchor
        addAnchor();
    }
}

void CinderARKitApp::touchesEnded( TouchEvent event )
{
    mNumTouches -= event.getTouches().size();
}

void CinderARKitApp::tapped(int numTaps)
{
    if ( numTaps == 2 )
    {
        mHumanPosition = mPlanePosition;
    }
}

void CinderARKitApp::swipe(int direction)
{
    if ( direction == (int)UISwipeGestureRecognizerDirectionUp )
    {
        restart();
    }
}

#pragma mark - Anchor

void CinderARKitApp::addAnchor()
{
    ARFrame *currentFrame = [mARSession currentFrame];
    
    // Create anchor using the camera's current position
    if (currentFrame)
    {
        // Create a transform with a translation of 0.5 meters in front of the camera
        matrix_float4x4 translation = matrix_identity_float4x4;
        translation.columns[3].z = -0.5;
        matrix_float4x4 transform = matrix_multiply(currentFrame.camera.transform, translation);
        ARAnchor *anchor = [[ARAnchor alloc] initWithTransform:transform];
        [mARSession addAnchor:anchor];
    }
}

#pragma mark - Texture Conversions

id <MTLTexture> CinderARKitApp::createTextureFromPixelBuffer( CVPixelBufferRef pixelBuffer,
                                                              MTLPixelFormat pixelFormat,
                                                              NSInteger planeIndex )
{
    id<MTLTexture> mtlTexture = nil;
    const size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    const size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    CVMetalTextureRef texture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, mCapturedImageTextureCache,
                                                                pixelBuffer, NULL, pixelFormat, width, height,
                                                                planeIndex, &texture);
    if( status == kCVReturnSuccess )
    {
        mtlTexture = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    }
    return mtlTexture;
}

void CinderARKitApp::createOrUpdateTextureFromPixelBuffer( mtl::TextureBufferRef & texture,
                                                           CVPixelBufferRef pixelBuffer,
                                                           mtl::PixelFormat pxFormat,
                                                           NSInteger planeIndex )
{
    id <MTLTexture> nativeTex = createTextureFromPixelBuffer(pixelBuffer, (MTLPixelFormat)pxFormat, planeIndex);
    if ( texture )
    {
        texture->update((__bridge void *)nativeTex);
    }
    else
    {
        texture = mtl::TextureBuffer::create((__bridge void *)nativeTex);
    }
}

#pragma mark - Update

void CinderARKitApp::update()
{
    // Create the camera textures
    ARFrame *currentFrame = mARSession.currentFrame;
    CVPixelBufferRef pixelBuffer = currentFrame.capturedImage;
    if ( CVPixelBufferGetPlaneCount(pixelBuffer) < 2 )
    {
        return;
    }
    createOrUpdateTextureFromPixelBuffer(mTextureLuma, pixelBuffer, mtl::PixelFormatR8Unorm, 0);
    createOrUpdateTextureFromPixelBuffer(mTextureChroma, pixelBuffer, mtl::PixelFormatRG8Unorm, 1);
    
    // Update the floor position
    NSArray<ARHitTestResult *> *results;
    mPlanePosition = vec3(-1);
    if ( currentFrame.anchors.count > 0 )
    {
        results = [currentFrame hitTest:CGPointMake(0.5, 0.5)
                                  types:ARHitTestResultTypeExistingPlaneUsingExtent | ARHitTestResultTypeExistingPlane];
        mPlaneIntersections.clear();
        for ( ARHitTestResult *result in results )
        {
            mat4 planeMat = modelMatFromTransform(result.worldTransform);
            vec3 planePosition = vec3(planeMat[3]);
            mPlaneIntersections.push_back(planeMat);
            // Prefer PlaneUsingExtent, but if we cant find one, use ExistinPlane.
            if ( result.type == ARHitTestResultTypeExistingPlaneUsingExtent ||
                 mPlanePosition == vec3(-1) )
            {
                mPlanePosition = planePosition;
            }
        }
    }
    
    // If we didn't find one with an existing plane, try estimating the horizontal plane.
    if ( mPlanePosition == vec3(-1) )
    {
        results = [currentFrame hitTest:CGPointMake(0.5, 0.5)
                                  types:ARHitTestResultTypeEstimatedHorizontalPlane];
        
        for ( ARHitTestResult *result in results )
        {
            mLastHorizontalPlane = modelMatFromTransform(result.worldTransform);
            mPlanePosition = vec3(mLastHorizontalPlane[3]); // Might have to divide by w if you can't assume w == 1
        }
    }
}

#pragma mark - Drawing

void CinderARKitApp::draw()
{
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    
    renderEncoder.disableDepth();
    // Put your drawing here
    if ( mTextureLuma )
    {
        renderEncoder.setTexture(mTextureLuma, mtl::ciTextureIndex0);
    }
    if ( mTextureChroma )
    {
        renderEncoder.setTexture(mTextureChroma, mtl::ciTextureIndex1);
    }
    renderEncoder.draw(mBatchCamera);
    
    renderEncoder.enableDepth();
    {
        mtl::ScopedMatrices matScene;
        ARFrame *frame = mARSession.currentFrame;
        
        UIView *view = getWindow()->getNativeViewController().view;
        CGSize viewportSize = view.bounds.size;
        mat4 projectionMatrix = fromMtl([frame.camera projectionMatrixWithViewportSize:viewportSize
                                                                           orientation:UIInterfaceOrientationLandscapeRight
                                                                                 zNear:0.001
                                                                                  zFar:1000]);
        mtl::setProjectionMatrix(projectionMatrix);
        
        mat4 viewMatrix = fromMtl(matrix_invert(frame.camera.transform));
        mtl::setViewMatrix(viewMatrix);
        
        // Now draw any anchors
        for ( ARAnchor *anchor in frame.anchors )
        {
            mtl::ScopedModelMatrix matAnchor;
            mtl::multModelMatrix(modelMatFromTransform(anchor.transform));
            
            if ( [anchor isKindOfClass:[ARPlaneAnchor class]] )
            {
                // Draw a plane
                mtl::rotate(M_PI*0.5f, vec3(1,0,0)); // Make it parallel with the ground
                mtl::color(1,1,0,0.5);
                renderEncoder.drawSolidRect(Rectf(-0.1,-0.1,0.1,0.1));
            }
            else
            {
                // Flip Z axis to convert geometry from right handed to left handed
                mtl::color(1,0,0);
                renderEncoder.drawCube(vec3(0), vec3(0.1)); // What size?
            }
        }
        
        // Last horizontal plane
        {
            mtl::ScopedModelMatrix matPlane;
            mtl::multModelMatrix(mLastHorizontalPlane);
            // Draw a plane
            mtl::rotate(M_PI*0.5f, vec3(1,0,0)); // Make it parallel with the ground
            mtl::color(0,0,1);
            renderEncoder.drawSolidRect(Rectf(-0.1,-0.1,0.1,0.1));
        }
        
        // Plane position in the center of the screen
        if ( mPlanePosition != vec3(-1) )
        {
            mtl::ScopedModelMatrix matPlane;
            mtl::translate(mPlanePosition);
            mtl::color(1,1,1);
            renderEncoder.drawCube(vec3(0), vec3(0.1)); // What size?
        }
        
        // The "Human" position
        if ( mHumanPosition != vec3(-1) )
        {
            vec3 humanScale(0.2,1.85,0.4);
            mtl::ScopedModelMatrix matPlane;
            mtl::translate(mHumanPosition + (humanScale * vec3(0,0.5,0)));
            mtl::color(0.92,0.72,0.62); // fleshy
            renderEncoder.drawCube(vec3(0), humanScale);
        }
    }
}

CINDER_APP( CinderARKitApp, RendererMetal )
