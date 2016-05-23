#include "cinder/app/App.h"
#include "cinder/CameraUi.h"
#include "cinder/Rand.h"
#include "SharedTypes.h"
#include "Batch.h"
#include "Shader.h"
#include "metal.h"
#include "Draw.h"
#include "cinder/Utilities.h"

using namespace ci;
using namespace ci::app;
using namespace std;

#ifdef CINDER_COCOA_TOUCH
const static int kHalfDimension = 2;
#else
const static int kHalfDimension = 4;
#endif
const static int kDrawDimension = (kHalfDimension * 2 + 1);
const static int kDrawNum = kDrawDimension * kDrawDimension * kDrawDimension;

// Ported from Paul Houx's Depth of Field sample:
// https://github.com/paulhoux/Cinder-Samples/tree/master/DepthOfField

class DepthOfFieldApp : public App
{
    
public:
    
    DepthOfFieldApp()
    : mAperture( 1 )
    , mFocalStop( 14 )
    , mFocalPlane( 35 )
    , mFocalLength( 1.0f )
    , mFoV( 10 )
    , mMaxCoCRadiusPixels( 11 )
    , mFarRadiusRescale( 1.0f )
    , mDebugOption( 0 )
    , mTime( 0 )
    , mTimeDemo( 0 )
    , mPaused( false )
    , mResized( true )
    , mIsManualFocus( false )
    , mShowBounds( false )
    , mEnableDemo( false )
    , mFocus(mFocalPlane)
    {}
    
    static void prepare( Settings *settings );
    
    void setup() override;
    void setupRenderDescriptors();
    void setupInstances();
    void setupGeometry();
    void setupTextures();
    void setupCamera();
    
    void update() override;
    void update( double timestep ); // Will be called a fixed number of times per second.
    void draw() override;
    
#ifdef CINDER_COCOA_TOUCH
    void touchesBegan( TouchEvent event ) override;
    void touchesMoved( TouchEvent event ) override;
    void touchesEnded( TouchEvent event ) override;
#else
    void mouseMove( MouseEvent event ) override;
    void mouseDown( MouseEvent event ) override;
    void mouseDrag( MouseEvent event ) override;
    void keyDown( KeyEvent event ) override;
    void keyUp( KeyEvent event ) override { mIsManualFocus = event.isShiftDown(); }
#endif
    
    void resize() override;

private:

    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::RenderPassDescriptorRef mRenderDescriptorFboGeom;
    mtl::RenderPassDescriptorRef mRenderDescriptorFboBlurHoriz;
    mtl::RenderPassDescriptorRef mRenderDescriptorFboBlurVert;

    CameraPersp                  mCamera;                         // Our main camera.
    CameraPersp                  mCameraUser;                     // Our user camera. We'll smoothly interpolate the main camera using the user camera as reference.
    ci::CameraUi                 mCameraUi;                       // Allows us to control the main camera.
    Sphere                       mBounds;                         // Bounding sphere of a single teapot, allows us to easily find the object under the cursor.
    mtl::DataBufferRef           mInstances;

    // TODO:
    // Create an indexed uniform block with all of the params
    // mtl::UniformBlock<myUniforms_t> mUniforms;
    
    mtl::BatchRef               mTeapots, mBackground, mSpheres; // Batches to draw our objects.
    mtl::TextureBufferRef       mTexGold, mTexClay;              // Textures.
    mtl::TextureBufferRef       mFboSource;                      // We render the scene to this Fbo, which is then used as input to the composite pass.
    mtl::RenderPipelineStateRef mPipelineBlurHoriz;
    mtl::RenderPipelineStateRef mPipelineBlurVert;
    mtl::RenderPipelineStateRef mPipelineComposite;
    mtl::RenderPipelineStateRef mPipelineTexture;
    
    mtl::DepthStateRef          mDepthStateFbo;
    mtl::VertexBufferRef        mVertexBufferTexRect;
    
    float mAperture;           // Calculated from F-Stop and Focal Length.
    int   mFocalStop;          // For more information on these values, see: http://improvephotography.com/photography-basics/aperture-shutter-speed-and-iso/
    float mFocalPlane;         // Distance to object in perfect focus.
    float mFocalLength;        // Calculated from Field of View.
    float mFoV;                // In degrees.
    int   mMaxCoCRadiusPixels; // Maximum blur in pixels.
    float mFarRadiusRescale;   // Should usually be set to 1.
    int   mDebugOption;        // Debug render modes.
    
    double mTime;
    double mTimeDemo;
    float  mFPS;
    float  mFocus;
    
    bool mPaused;
    bool mResized;
    bool mIsManualFocus;
    bool mShowBounds;
    bool mEnableDemo;
    
    vec2 mMousePos;
};

#pragma mark - Setup

void DepthOfFieldApp::prepare( Settings *settings )
{
    settings->setWindowSize( 960, 540 );
    settings->disableFrameRate();
    settings->setFullScreen();
}

void DepthOfFieldApp::setup()
{
    setupRenderDescriptors();
    setupInstances();
    setupGeometry();
    setupTextures();
    setupCamera();
}

void DepthOfFieldApp::setupRenderDescriptors()
{
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor( ColorAf(1.f, 0.f, 0.f, 1.f) ) );
    
    mRenderDescriptorFboGeom = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                                 .clearColor( ColorAf(0.f, 0.f, 0.f, 0.f) ) );

    // NOTE: We want a render decriptor for BOTH horizontal and vertical because they're different sizes.
    // Otherwise it has to re-create the depth texture each render pass, which is expensive.
    mRenderDescriptorFboBlurHoriz = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                                      .clearColor( ColorAf(0.f, 0.f, 0.f, 0.f) ) );

    mRenderDescriptorFboBlurVert = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                                     .clearColor( ColorAf(0.f, 0.f, 0.f, 0.f) ) );
}

void DepthOfFieldApp::setupInstances()
{
    // Initialize model matrices (one for each instance).
    Rand::randSeed( 12345 );
    std::vector<TeapotInstance> instances;
    
    for( int z = -kHalfDimension; z <= kHalfDimension; z++ )
    {
        for( int y = -kHalfDimension; y <= kHalfDimension; y++ )
        {
            for( int x = -kHalfDimension; x <= kHalfDimension; x++ )
            {
                vec3  position = vec3( x, y, z ) * 5.f + Rand::randVec3();
                vec3  axis = Rand::randVec3();
                float angle = Rand::randFloat( -180.0f, 180.0f );
                
                mat4 transform = glm::translate( position );
                transform *= glm::rotate( glm::radians( angle ), axis );
                
                TeapotInstance instance;
                instance.position = toMtl(position);
                instance.axis = toMtl(axis);
                instance.modelMatrix = toMtl(transform);

                instances.emplace_back(instance);
            }
        }
    }
    
    assert(instances.size() == kDrawNum);
    
    mInstances = mtl::DataBuffer::create(instances,
                                         mtl::DataBuffer::Format().label("Node Instances").isConstant());
}
    
void DepthOfFieldApp::setupGeometry()
{

    // Pipelines
    auto blendingFormat = mtl::RenderPipelineState::Format().colorPixelFormat(mtl::PixelFormatRGBA16Float)
                                                            .blendingEnabled();
    auto opaqueFormat = mtl::RenderPipelineState::Format().colorPixelFormat(mtl::PixelFormatRGBA16Float);
    auto opaqueBlurFormat = mtl::RenderPipelineState::Format().colorPixelFormat(mtl::PixelFormatRGBA16Float)
                                                              .numColorAttachments(2);
    
    mPipelineBlurHoriz = mtl::RenderPipelineState::create("texture_vertex", "blur_horiz_fragment", opaqueBlurFormat);
    
    mPipelineBlurVert = mtl::RenderPipelineState::create("texture_vertex", "blur_vert_fragment", opaqueBlurFormat);
    
    mPipelineComposite = mtl::RenderPipelineState::create("texture_vertex", "composite_fragment", opaqueFormat);

    mPipelineTexture = mtl::RenderPipelineState::create("texture_vertex", "texture_fragment", opaqueFormat);
    
    // Geometry
    AxisAlignedBox bounds;
    
    mTeapots = mtl::Batch::create( geom::Teapot().subdivisions( 8 ) >> geom::Translate( 0, -0.5f, 0 ) >> geom::Bounds( &bounds ),
                                    mtl::RenderPipelineState::create("instanced_vertex", "scene_fragment",  opaqueFormat));
    
    mBounds.setCenter( bounds.getCenter() );
    mBounds.setRadius( 0.5f * glm::length( bounds.getExtents() ) ); // Scale down for a better fit.
    
    mSpheres = mtl::Batch::create( geom::WireSphere().center( mBounds.getCenter() ).radius( mBounds.getRadius() ),
                                    mtl::RenderPipelineState::create("instanced_vertex", "debug_fragment", blendingFormat) );

    mBackground = mtl::Batch::create( geom::Sphere().subdivisions( 60 ).radius( 150.0f ) >> geom::Invert( geom::NORMAL ),
                                     mtl::RenderPipelineState::create("background_vertex", "scene_fragment", opaqueFormat));
    
    mVertexBufferTexRect = mtl::VertexBuffer::create(geom::Rect(Rectf(0,0,1,1)),
                                                     {ci::geom::POSITION, ci::geom::TEX_COORD_0});
}

void DepthOfFieldApp::setupTextures()
{
    // Load the textures.
    mTexGold = mtl::TextureBuffer::create( loadImage( loadAsset( "gold.png" ) ),
                                           mtl::TextureBuffer::Format().flipVertically() );
    
    mTexClay = mtl::TextureBuffer::create( loadImage( loadAsset( "clay.png" ) ),
                                           mtl::TextureBuffer::Format().flipVertically() );
}

void DepthOfFieldApp::setupCamera()
{
    // Setup the camera.
    mCamera.setPerspective( mFoV, 1.0f, 0.05f, 100.0f );
    mCamera.lookAt( vec3( 8.4f, 14.1f, 29.7f ), vec3( 0 ) );
    mCameraUser.setPerspective( mFoV, 1.0f, 0.05f, 100.0f );
    mCameraUser.lookAt( vec3( 8.4f, 14.1f, 29.7f ), vec3( 0 ) );
#ifdef CINDER_COCOA_TOUCH
    mCameraUi = CameraUi(&mCameraUser, getWindow());
#else
    mCameraUi.setCamera( &mCameraUser );
#endif
}

#pragma mark - Update

void DepthOfFieldApp::update()
{
    mFPS = getAverageFps();
    
    if ( getElapsedFrames() % 60 == 0 && isFullScreen() )
    {
        console() << "mFPS: " << mFPS << "\n";
    }

    // Create or resize Fbo's.
    if( mResized )
    {
        mResized = false;
        
        int width = getWindowWidth();
        int height = getWindowHeight();

        auto fmt = mtl::TextureBuffer::Format()
        .pixelFormat(mtl::PixelFormatRGBA16Float)
        .usage((mtl::TextureUsage)(mtl::TextureUsageRenderTarget |
                                   mtl::TextureUsageShaderRead));
        mFboSource = mtl::TextureBuffer::create( width, height, fmt);

        // The horizontal blur Fbo will contain a downsampled and blurred version of the scene.
        // The first attachment contains the foreground. RGB = premultiplied color, A = coverage.
        // The second attachments contains the blurred scene. RGB = color, A = Signed CoC.
        width >>= 2;

        auto fboHoriz0 = mtl::TextureBuffer::create( width, height, fmt );
        auto fboHoriz1 = mtl::TextureBuffer::create( width, height, fmt );
        mRenderDescriptorFboBlurHoriz->setColorAttachment(fboHoriz0, 0);
        mRenderDescriptorFboBlurHoriz->setColorAttachment(fboHoriz1, 1);
        
        // The vertical blur Fbo will contain a downsampled and blurred version of the scene.
        // The first attachment contains the foreground. RGB = premultiplied color, A = coverage.
        // The second attachments contains the blurred scene. RGB = color, A = discarded.
        height >>= 2;

        auto fboVert0 = mtl::TextureBuffer::create( width, height, fmt );
        auto fboVert1 = mtl::TextureBuffer::create( width, height, fmt );
        mRenderDescriptorFboBlurVert->setColorAttachment(fboVert0, 0);
        mRenderDescriptorFboBlurVert->setColorAttachment(fboVert1, 1);        
    }

    // Use a fixed time step for a steady 60 updates per second.
    static const double timestep = 1.0 / 60.0;
    
    // Keep track of time.
    static double time = getElapsedSeconds();
    static double accumulator = 0.0;
    
    // Calculate elapsed time since last frame.
    double elapsed = getElapsedSeconds() - time;
    time += elapsed;
    
    // Update all nodes in the scene graph.
    accumulator += math<double>::min( elapsed, 0.1 ); // prevents 'spiral of death'
    
    while( accumulator >= timestep )
    {
        update( mPaused ? 0.0 : timestep );
        accumulator -= timestep;
    }
}

void DepthOfFieldApp::update( double timestep )
{
    mTime += timestep;
    
    // Adjust cameras.
    {
        // User camera.
        auto target = mCameraUser.getPivotPoint();
        auto distance = glm::clamp( mCameraUser.getPivotDistance(), 5.0f, 45.0f );
        
        vec3 eye;
        if( mEnableDemo )
        {
            // In demo mode, we slowly move the camera, change the focus distance and field of view.
            mTimeDemo += timestep;
            
            eye.x = float( 25.0 * sin( 0.05 * mTimeDemo ) );
            eye.y = float( 15.0 * cos( 0.01 * mTimeDemo ) );
            eye.z = float( 10.0 * cos( 0.05 * mTimeDemo ) );
            
            mFocus = mIsManualFocus ? mFocus : glm::mix( distance, 45.0f, float( 0.5 - 0.5 * cos( 0.05 * mTimeDemo ) ) );
            mFoV = glm::mix( 10.0f, 20.0f, float( 0.5 - 0.5 * cos( 0.02 * mTimeDemo ) ) );
        }
        else
        {
            // Otherwise, just constrain the camera to a distance range.
            eye = target - distance * mCameraUser.getViewDirection();
        }
        
        mCameraUser.lookAt( eye, target );
        mCameraUser.setFov( mFoV );
    }
    
    {
        // Main camera.
        const float kSmoothing = 0.1f;
        
        auto  eye = glm::mix( mCamera.getEyePoint(), mCameraUser.getEyePoint(), kSmoothing );
        auto  target = glm::mix( mCamera.getPivotPoint(), mCameraUser.getPivotPoint(), kSmoothing );
        float fov = glm::mix( mCamera.getFov(), mCameraUser.getFov(), kSmoothing );
        
        mCamera.setFov( fov );
        mCamera.lookAt( eye, target );
    }
    
    // Update values.
    mFocalPlane = exp( glm::mix( log( mFocalPlane ), log( mFocus ), 0.2f ) );
    mFocalLength = mCamera.getFocalLength();
    
    static const float fstops[] = { 0.7f, 0.8f, 1.0f, 1.2f, 1.4f, 1.7f, 2.0f, 2.4f, 2.8f, 3.3f,
                                    4.0f, 4.8f, 5.6f, 6.7f, 8.0f, 9.5f, 11.0f, 16.0f, 22.0f };
    mAperture = mFocalLength / fstops[mFocalStop];
    
    // Initialize ray-casting.
    auto  ray = mCamera.generateRay( mMousePos, getWindowSize() );
    float min, max, dist = FLT_MAX;
    
    // Reset random number generator.
    Rand::randSeed( 12345 );
    
//    // Animate teapots and perform ray casting at the same time.
    auto ptr = (TeapotInstance *)mInstances->contents();
    for( int z = -kHalfDimension; z <= kHalfDimension; z++ )
    {
        for( int y = -kHalfDimension; y <= kHalfDimension; y++ )
        {
            for( int x = -kHalfDimension; x <= kHalfDimension; x++ )
            {
                float angle = Rand::randFloat( -180.0f, 180.0f ) + Rand::randFloat( 1.0f, 90.0f ) * float( mTime );
                
                TeapotInstance & i = *ptr++;
                mat4 transform = glm::translate( fromMtl(i.position) );
                transform *= glm::rotate( glm::radians( angle ), fromMtl(i.axis) );
                
                i.modelMatrix = toMtl(transform);
                
                // Ray-casting.
                if( mIsManualFocus )
                {
                    auto bounds = mBounds.transformed( transform );
                    if( bounds.intersect( ray, &min, &max ) > 0 )
                    {
                        if( min < dist )
                        {
                            dist = min;
                        }
                    }
                }
            }
        }
    }
    
    // Auto-focus.
    if( mIsManualFocus && dist < FLT_MAX )
    {
        mFocalPlane = dist;
    }
}

#pragma mark - Draw

void DepthOfFieldApp::draw()
{
    // Render RGB and normalized CoC (in alpha channel) to Fbo.
    if( true )
    {
        mtl::ScopedCommandBuffer fboBuffer;
        mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFboGeom, mFboSource, "FBO Geom");
        // FLIP the main contents so it looks just like the Cinder demo
        fboEncoder.setViewport(vec2(0, mFboSource->getHeight()),
                               vec2(mFboSource->getWidth(), -mFboSource->getHeight()));

        mtl::ScopedMatrices scpMatrices;
        mtl::setMatrices( mCamera );
        fboEncoder.enableDepth();

        fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom0);
        fboEncoder.setFragmentValueAtIndex(&mAperture, mtl::ciBufferIndexCustom1);
        fboEncoder.setFragmentValueAtIndex(&mFocalPlane, mtl::ciBufferIndexCustom2);
        fboEncoder.setFragmentValueAtIndex(&mFocalLength, mtl::ciBufferIndexCustom3);

        if( true )
        {
            mtl::ScopedColor       scpColor( 1, 1, 1 );
            fboEncoder.setTexture(mTexGold);
            fboEncoder.draw(mTeapots, mInstances, kDrawNum );
        }
        
        if( true )
        {
            // Render background.
            fboEncoder.setCullMode(mtl::CullModeFront);
            mtl::ScopedColor       scpColor( 1, 1, 1 );
            fboEncoder.setTexture(mTexClay);
            mBackground->draw(fboEncoder);
        }

        if( mShowBounds )
        {
            // Render bounding spheres.
            mtl::ScopedColor       scpColor( 1, 1, 1 );
            fboEncoder.draw( mSpheres, mInstances, kDrawNum );
        }
    }

    // Perform horizontal blur and downsampling. Output 2 targets.
    if( true )
    {
        mtl::ScopedCommandBuffer fboBuffer;
        mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFboBlurHoriz, "FBO Horiz Blur");
        ivec2 renderSize = mRenderDescriptorFboBlurHoriz->getColorAttachment()->getSize();
        fboEncoder.setViewport(vec2(0), vec2(renderSize));

        mtl::ScopedMatrices matBlur;
        mtl::setMatricesWindow(renderSize);

        mtl::ScopedColor scpColor(1,1,1);
        fboEncoder.setTexture( mFboSource );
        fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom0);
        fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom1);
        float invNearBlurRadiusPixels = 1.0f / mMaxCoCRadiusPixels;
        fboEncoder.setFragmentValueAtIndex(&invNearBlurRadiusPixels, mtl::ciBufferIndexCustom2);
        fboEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

        mtl::scale(vec2(renderSize));
        fboEncoder.draw(mVertexBufferTexRect, mPipelineBlurHoriz);
    }

    // Perform vertical blur.
    if( true )
    {
        mtl::ScopedCommandBuffer fboBuffer;
        mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFboBlurVert, "FBO Vert Blur");
        ivec2 renderSize = mRenderDescriptorFboBlurVert->getColorAttachment()->getSize();
        fboEncoder.setViewport(vec2(0), vec2(renderSize));

        mtl::ScopedMatrices matBlur;
        mtl::setMatricesWindow(renderSize);
        mtl::ScopedColor scpColor(1,1,1);

        fboEncoder.setTexture(mRenderDescriptorFboBlurHoriz->getColorAttachment(0), 0);
        fboEncoder.setTexture(mRenderDescriptorFboBlurHoriz->getColorAttachment(1), 1);
        fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom0);
        fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom1);
        fboEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

        mtl::scale(vec2(renderSize));
        fboEncoder.draw(mVertexBufferTexRect, mPipelineBlurVert);
    }
    
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    mtl::ScopedMatrices matWindow;
    mtl::setMatricesWindow(getWindowSize());

    // Perform compositing.
    if( true )
    {
        mtl::ScopedColor scpColor(1,1,1);

        renderEncoder.setTexture(mFboSource, 0);
        renderEncoder.setTexture(mRenderDescriptorFboBlurVert->getColorAttachment(0), 1);
        renderEncoder.setTexture(mRenderDescriptorFboBlurVert->getColorAttachment(1), 2);
        vec2 inputSourceInvSize = 1.0f / vec2( mFboSource->getSize() );
        renderEncoder.setFragmentValueAtIndex(&inputSourceInvSize, mtl::ciBufferIndexCustom0);
        vec2 offset(0.f);
        renderEncoder.setFragmentValueAtIndex(&offset, mtl::ciBufferIndexCustom1);
        renderEncoder.setFragmentValueAtIndex(&mFarRadiusRescale, mtl::ciBufferIndexCustom2);
        ivec2 renderSize = getWindowSize();
        renderEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

        mtl::scale(getWindowSize());
        renderEncoder.draw(mVertexBufferTexRect, mPipelineComposite);
    }
}

#pragma mark - Input

#ifdef CINDER_COCOA_TOUCH

void DepthOfFieldApp::touchesBegan( TouchEvent event )
{
    mMousePos = event.getTouches()[0].getPos();
    mCameraUi.mouseDown(mMousePos);
}

void DepthOfFieldApp::touchesMoved( TouchEvent event )
{
    mIsManualFocus = false;
    mMousePos = event.getTouches()[0].getPos();
    mCameraUi.mouseDrag( mMousePos, true, false, false );
}

void DepthOfFieldApp::touchesEnded( TouchEvent event )
{
    mIsManualFocus = true;
    mMousePos = event.getTouches()[0].getPos();
    mCameraUi.mouseUp(mMousePos);
}

#else

void DepthOfFieldApp::mouseMove( MouseEvent event )
{
    mIsManualFocus = event.isShiftDown();
    mMousePos = event.getPos();
}

void DepthOfFieldApp::mouseDown( MouseEvent event )
{
    mCameraUi.mouseDown( event );
}

void DepthOfFieldApp::mouseDrag( MouseEvent event )
{
    mCameraUi.mouseDrag( event );
    
    mIsManualFocus = event.isShiftDown();
    mMousePos = event.getPos();
}

void DepthOfFieldApp::keyDown( KeyEvent event )
{
    mIsManualFocus = event.isShiftDown();
    
    switch( event.getCode() )
    {
        case KeyEvent::KEY_ESCAPE:
            quit();
            break;
        case KeyEvent::KEY_f:
            setFullScreen(!isFullScreen());
            break;
        case KeyEvent::KEY_SPACE:
            mPaused = !mPaused;
            break;
        case KeyEvent::KEY_b:
            mShowBounds = !mShowBounds;
            break;
        case KeyEvent::KEY_d:
            mEnableDemo = !mEnableDemo;
            break;
        default:
            break;
    }
}

#endif

#pragma mark - Resize

void DepthOfFieldApp::resize()
{
    mCamera.setAspectRatio( getWindowAspectRatio() );
    mResized = true;
}

CINDER_APP( DepthOfFieldApp,
            RendererMetal(RendererMetal::Options().pixelFormat(mtl::PixelFormatRGBA16Float)),
            DepthOfFieldApp::prepare )
