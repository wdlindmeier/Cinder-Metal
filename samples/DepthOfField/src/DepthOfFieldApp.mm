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
    , mShiftDown( false )
    , mShowBounds( false )
    , mEnableDemo( false )
    {}
    
    static void prepare( Settings *settings );
    
    void setup() override;
    void update() override;
    void update( double timestep ); // Will be called a fixed number of times per second.
    void draw() override;
    
    void mouseMove( MouseEvent event ) override;
    void mouseDown( MouseEvent event ) override;
    void mouseDrag( MouseEvent event ) override;
    
    void keyDown( KeyEvent event ) override;
    void keyUp( KeyEvent event ) override { mShiftDown = event.isShiftDown(); }
    
    void resize() override;

private:

    mtl::RenderPassDescriptorRef mRenderDescriptor;
    mtl::RenderPassDescriptorRef mRenderDescriptorFboGeom;
    mtl::RenderPassDescriptorRef mRenderDescriptorFboBlur;

    CameraPersp                  mCamera;                         // Our main camera.
    CameraPersp                  mCameraUser;                     // Our user camera. We'll smoothly interpolate the main camera using the user camera as reference.
    ci::CameraUi                 mCameraUi;                       // Allows us to control the main camera.
    Sphere                       mBounds;                         // Bounding sphere of a single teapot, allows us to easily find the object under the cursor.
    //gl::VboRef             mInstances;                      // Buffer containing the model matrix for each teapot.
    mtl::DataBufferRef           mInstances;

    // TODO:
    // Create an indexed uniform block with all of the params
    mtl::UniformBlock<myUniforms_t> mUniforms;
    
    mtl::BatchRef               mTeapots, mBackground, mSpheres; // Batches to draw our objects.
    mtl::TextureBufferRef       mTexGold, mTexClay;              // Textures.
    mtl::TextureBufferRef       mFboSource;                      // We render the scene to this Fbo, which is then used as input to the
    mtl::TextureBufferRef       mFboBlurHoriz[2];                        // We render the scene to this Fbo, which is then used as input to the
    mtl::TextureBufferRef       mFboBlurVert[2];
    mtl::RenderPipelineStateRef mPipelineBlurHoriz;
    mtl::RenderPipelineStateRef mPipelineBlurVert;
    mtl::RenderPipelineStateRef mPipelineComposite;
    mtl::DepthStateRef          mDepthStateFbo;
    
    mtl::VertexBufferRef        mVertexBufferTexture;
    // TMP
    mtl::RenderPipelineStateRef mPipelineTexture;
    
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
    bool mShiftDown;
    bool mShowBounds;
    bool mEnableDemo;
    
    vec2 mMousePos;
};

void DepthOfFieldApp::prepare( Settings *settings )
{
    settings->setWindowSize( 960, 540 );
    settings->disableFrameRate();
}

void DepthOfFieldApp::setup()
{
    mFocus = mFocalPlane;
    
    mRenderDescriptor = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                          .clearColor( ColorAf(1.f, 0.f, 0.f, 1.f) ) );
    
    // TODO: Play around with these formats
    mRenderDescriptorFboGeom = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                             .clearColor( ColorAf(0.f, 0.f, 0.f, 0.f) )
                                                             .stencilStoreAction( mtl::StoreActionStore )
                                                             .stencilUsage( ( mtl::TextureUsage )
                                                                            ( mtl::TextureUsageRenderTarget |
                                                                              mtl::TextureUsageShaderRead ) )
                                                             .depthStoreAction( mtl::StoreActionStore )
                                                             .depthUsage( ( mtl::TextureUsage )
                                                                          ( mtl::TextureUsageRenderTarget |
                                                                            mtl::TextureUsageShaderRead ) )
                                                             );
    mRenderDescriptorFboBlur = mtl::RenderPassDescriptor::create(mtl::RenderPassDescriptor::Format()
                                                                 .clearColor( ColorAf(0.f, 0.f, 0.f, 0.f) )
                                                                 .depthStoreAction( mtl::StoreActionStore )
                                                                 .depthUsage( ( mtl::TextureUsage )
                                                                             ( mtl::TextureUsageRenderTarget |
                                                                               mtl::TextureUsageShaderRead ) )
                                                                 );

    // Load the textures.
    mTexGold = mtl::TextureBuffer::create( loadImage( loadAsset( "gold.png" ) ),
                                           mtl::TextureBuffer::Format().flipVertically() );
    mTexClay = mtl::TextureBuffer::create( loadImage( loadAsset( "clay.png" ) ),
                                           mtl::TextureBuffer::Format().flipVertically() );
    
    // Initialize model matrices (one for each instance).
    std::vector<mtl::Instance> instances;
    for( int z = -4; z <= 4; z++ )
    {
        for( int y = -4; y <= 4; y++ )
        {
            for( int x = -4; x <= 4; x++ )
            {
                vec3  axis = Rand::randVec3();
                float angle = Rand::randFloat( -180.0f, 180.0f );
                
                mat4 transform = glm::translate( vec3( x, y, z ) * 5.0f );
                transform *= glm::rotate( glm::radians( angle ), axis );
                
                mtl::Instance instance;
                instance.modelMatrix = toMtl(transform);

                instances.emplace_back(instance);
            }
        }
    }
    
    // TODO: Make this indexed
    mInstances = mtl::DataBuffer::create(instances, mtl::DataBuffer::Format().label("Node Instances").isConstant());
    
    // Create mesh and append per-instance data.
    AxisAlignedBox bounds;

    mTeapots = mtl::Batch::create( geom::Teapot().subdivisions( 8 ) >> geom::Translate( 0, -0.5f, 0 ) >> geom::Bounds( &bounds ),
                                  mtl::RenderPipelineState::create("instanced_vertex", "scene_fragment",
                                                                   mtl::RenderPipelineState::Format()
                                                                   .pixelFormat(mtl::PixelFormatRGBA16Float)) );
    
    mBounds.setCenter( bounds.getCenter() );
    mBounds.setRadius( 0.5f * glm::length( bounds.getExtents() ) ); // Scale down for a better fit.
    
    // Create batches.
    auto blendingFormat = mtl::RenderPipelineState::Format().blendingEnabled().pixelFormat(mtl::PixelFormatRGBA16Float);
    auto opaqueFormat = mtl::RenderPipelineState::Format().pixelFormat(mtl::PixelFormatRGBA16Float);
    
    mSpheres = mtl::Batch::create( geom::WireSphere().center( mBounds.getCenter() ).radius( mBounds.getRadius() ),
                                    mtl::RenderPipelineState::create("instanced_vertex", "debug_fragment",
                                                                      blendingFormat) );

    // Create background.
    mBackground = mtl::Batch::create( geom::Sphere().subdivisions( 60 ).radius( 150.0f ) >> geom::Invert( geom::NORMAL ),
                                      mtl::RenderPipelineState::create("background_vertex", "scene_fragment",
                                                                        opaqueFormat) );

    mPipelineBlurHoriz = mtl::RenderPipelineState::create("texture_vertex", "blur_horiz_fragment", opaqueFormat);
    
    mPipelineBlurVert = mtl::RenderPipelineState::create("texture_vertex", "blur_vert_fragment", opaqueFormat);
    
    mPipelineComposite = mtl::RenderPipelineState::create("texture_vertex", "composite_fragment", opaqueFormat);

    // Setup the camera.
    mCamera.setPerspective( mFoV, 1.0f, 0.05f, 100.0f );
    mCamera.lookAt( vec3( 8.4f, 14.1f, 29.7f ), vec3( 0 ) );
    mCameraUser.setPerspective( mFoV, 1.0f, 0.05f, 100.0f );
    mCameraUser.lookAt( vec3( 8.4f, 14.1f, 29.7f ), vec3( 0 ) );
    mCameraUi.setCamera( &mCameraUser );
}

void DepthOfFieldApp::update()
{
    mFPS = getAverageFps();

    // Create or resize Fbo's.
    if( mResized )
    {
        mResized = false;
        
        mVertexBufferTexture = mtl::VertexBuffer::create(geom::Rect(getWindowBounds()), {ci::geom::POSITION, ci::geom::TEX_COORD_0});
        
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

        mFboBlurHoriz[0] = mtl::TextureBuffer::create( width, height, fmt );
        mFboBlurHoriz[1] = mtl::TextureBuffer::create( width, height, fmt );
        
        // The vertical blur Fbo will contain a downsampled and blurred version of the scene.
        // The first attachment contains the foreground. RGB = premultiplied color, A = coverage.
        // The second attachments contains the blurred scene. RGB = color, A = discarded.
        height >>= 2;

        mFboBlurVert[0] = mtl::TextureBuffer::create( width, height, fmt );
        mFboBlurVert[1] = mtl::TextureBuffer::create( width, height, fmt );
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
            
            mFocus = mShiftDown ? mFocus : glm::mix( distance, 45.0f, float( 0.5 - 0.5 * cos( 0.05 * mTimeDemo ) ) );
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
    
    // Animate teapots and perform ray casting at the same time.
    auto ptr = (mtl::Instance *)mInstances->contents();
    for( int z = -4; z <= 4; z++ )
    {
        for( int y = -4; y <= 4; y++ )
        {
            for( int x = -4; x <= 4; x++ )
            {
                vec3  position = vec3( x, y, z ) * 5.0f + Rand::randVec3();
                vec3  axis = Rand::randVec3();
                float angle = Rand::randFloat( -180.0f, 180.0f ) + Rand::randFloat( 1.0f, 90.0f ) * float( mTime );
                
                mat4 transform = glm::translate( position );
                transform *= glm::rotate( glm::radians( angle ), axis );
                
                //( *ptr++ ) = transform;
                ( *ptr++ ).modelMatrix = toMtl(transform);
                
                // Ray-casting.
                if( mShiftDown )
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
    if( mShiftDown && dist < FLT_MAX )
    {
        mFocalPlane = dist;
    }
}

void DepthOfFieldApp::draw()
{
    // Render RGB and normalized CoC (in alpha channel) to Fbo.
    if( true )
    {
        mtl::ScopedCommandBuffer fboBuffer(true);
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
            // TODO: Use param names
            fboEncoder.draw(mTeapots, mInstances, 9 * 9 * 9 );
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
            fboEncoder.draw( mSpheres, mInstances, 9 * 9 * 9 );
        }
    }

    // Perform horizontal blur and downsampling. Output 2 targets.
    if( true )
    {
        // TODO: Pass both textures to the Render Encoder
        // HOWTO: assign both textures to mRenderDescriptorFboBlur
        // SEE NOTES in Cinder-Metal todo
        
        for ( int i = 0; i < 2; ++i )
        {

            auto fbo = mFboBlurHoriz[i];
            mtl::ScopedCommandBuffer fboBuffer(true);
            mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFboBlur, fbo, "FBO Horiz Blur " + to_string(i));
            fboEncoder.setViewport(vec2(0), vec2(fbo->getSize()));

            mtl::ScopedMatrices matBlur;
            mtl::setMatricesWindow(fbo->getSize());

            mtl::ScopedColor scpColor(1,1,1);
            fboEncoder.setTexture( mFboSource );
            fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom0);
            fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom1);
            float invNearBlurRadiusPixels = 1.0f / mMaxCoCRadiusPixels;
            fboEncoder.setFragmentValueAtIndex(&invNearBlurRadiusPixels, mtl::ciBufferIndexCustom2);
            ivec2 renderSize = fbo->getSize();
            fboEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

            bool returnNear = true;
            if ( i == 0 )
            {
                returnNear = false;
            }
            fboEncoder.setFragmentValueAtIndex( &returnNear, mtl::ciBufferIndexCustom5 );

            // TODO: Cache this
            auto fboRect = mtl::VertexBuffer::create(geom::Rect(Rectf(0, 0, fbo->getWidth(), fbo->getHeight())),
                                                     {ci::geom::POSITION, ci::geom::TEX_COORD_0});
            fboEncoder.draw(fboRect, mPipelineBlurHoriz);
        }
    }

    // Perform vertical blur.
    if( true )
    {
        for ( int i = 0; i < 2; ++i )
        {
            auto fbo = mFboBlurVert[i];
            // TODO: Try removing "true"
            mtl::ScopedCommandBuffer fboBuffer(true);
            mtl::ScopedRenderEncoder fboEncoder = fboBuffer.scopedRenderEncoder(mRenderDescriptorFboBlur, fbo, "FBO Vert Blur " + to_string(i));
            fboEncoder.setViewport(vec2(0), vec2(fbo->getSize()));

            mtl::ScopedMatrices matBlur;
            mtl::setMatricesWindow(fbo->getSize());
            mtl::ScopedColor scpColor(1,1,1);

            fboEncoder.setTexture(mFboBlurHoriz[0], 0);
            fboEncoder.setTexture(mFboBlurHoriz[1], 1);
            fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom0);
            fboEncoder.setFragmentValueAtIndex(&mMaxCoCRadiusPixels, mtl::ciBufferIndexCustom1);
            ivec2 renderSize = fbo->getSize();
            fboEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

            bool returnNear = true;
            if ( i == 0 )
            {
                returnNear = false;
            }
            fboEncoder.setFragmentValueAtIndex( &returnNear, mtl::ciBufferIndexCustom5 );

            // TODO: Cache this
            auto fboRect = mtl::VertexBuffer::create(geom::Rect(Rectf(0, 0, fbo->getWidth(), fbo->getHeight())),
                                                     {ci::geom::POSITION, ci::geom::TEX_COORD_0});
            fboEncoder.draw(fboRect, mPipelineBlurVert);

        }
    }
    
    mtl::ScopedRenderCommandBuffer renderBuffer;
    mtl::ScopedRenderEncoder renderEncoder = renderBuffer.scopedRenderEncoder(mRenderDescriptor);
    mtl::setMatricesWindow(getWindowSize());

    // Perform compositing.
    if( true )
    {
        mtl::ScopedColor scpColor(1,1,1);

        renderEncoder.setTexture(mFboSource, 0);
        renderEncoder.setTexture(mFboBlurVert[0], 1);
        renderEncoder.setTexture(mFboBlurVert[1], 2);
        vec2 inputSourceInvSize = 1.0f / vec2( mFboSource->getSize() );
        renderEncoder.setFragmentValueAtIndex(&inputSourceInvSize, mtl::ciBufferIndexCustom0);
        vec2 offset(0.f);
        renderEncoder.setFragmentValueAtIndex(&offset, mtl::ciBufferIndexCustom1);
        renderEncoder.setFragmentValueAtIndex(&mFarRadiusRescale, mtl::ciBufferIndexCustom2);
        ivec2 renderSize = getWindowSize();
        renderEncoder.setFragmentValueAtIndex(&renderSize, mtl::ciBufferIndexCustom3);

        // TODO: Cache this
        auto compositeRect = mtl::VertexBuffer::create(geom::Rect(getWindowBounds()),
                                                 {ci::geom::POSITION, ci::geom::TEX_COORD_0});
        renderEncoder.draw(compositeRect, mPipelineComposite);
    }
}

void DepthOfFieldApp::mouseMove( MouseEvent event )
{
    mShiftDown = event.isShiftDown();
    mMousePos = event.getPos();
}

void DepthOfFieldApp::mouseDown( MouseEvent event )
{
    mCameraUi.mouseDown( event );
}

void DepthOfFieldApp::mouseDrag( MouseEvent event )
{
    mCameraUi.mouseDrag( event );
    
    mShiftDown = event.isShiftDown();
    mMousePos = event.getPos();
}

void DepthOfFieldApp::keyDown( KeyEvent event )
{
    mShiftDown = event.isShiftDown();
    
    switch( event.getCode() )
    {
        case KeyEvent::KEY_ESCAPE:
            quit();
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

void DepthOfFieldApp::resize()
{
    mCamera.setAspectRatio( getWindowAspectRatio() );
    mResized = true;
}

CINDER_APP( DepthOfFieldApp,
            RendererMetal(RendererMetal::Options().pixelFormat(mtl::PixelFormatRGBA16Float)),
            DepthOfFieldApp::prepare )
