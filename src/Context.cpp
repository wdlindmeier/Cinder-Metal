//
//  Context.cpp
//
//  Created by William Lindmeier on 1/20/16.
//
//

#include "Context.h"

#include "cinder/Log.h"
#include "MetalConstants.h"
#include "ShaderTypes.h"
#include "RendererMetal.h"
#include "Shader.h"

using namespace std;

namespace cinder { namespace mtl {
    
    static pthread_key_t sThreadSpecificCurrentContextKey;
    static bool sThreadSpecificCurrentContextInitialized = false;

    Context::Context( const std::shared_ptr<PlatformData> &platformData )
    :
    mPlatformData( platformData )
    {
        // set thread's active Context to 'this' in case anything calls mtl::context() (like the GlslProg constructor)
        auto prevCtx = Context::getCurrent();
        Context::reflectCurrent( this );

        mColor = ColorAf(1,1,1,1);
        
        mModelMatrixStack.push_back( mat4() );
        mViewMatrixStack.push_back( mat4() );
        mProjectionMatrixStack.push_back( mat4() );
        
        // restore current context thread-local to what it was previously
        Context::reflectCurrent( prevCtx );
    }
    
    Context::~Context()
    {
        if( getCurrent() == this )
        {
//            env()->makeContextCurrent( nullptr );
            pthread_setspecific( sThreadSpecificCurrentContextKey, NULL );
        }
    }
    
    ContextRef Context::create( const Context *sharedContext )
    {
        shared_ptr<Context::PlatformData> platformData = shared_ptr<Context::PlatformData>( new PlatformData() );
        ContextRef result( new Context( platformData ) );
        return result;
    }
    
    ContextRef Context::createFromExisting( const std::shared_ptr<PlatformData> &platformData )
    {
//        env()->initializeFunctionPointers();
        ContextRef result( std::shared_ptr<Context>( new Context( platformData ) ) );
        return result;
    }
    
    void Context::makeCurrent( bool force ) const
    {
        if( ! sThreadSpecificCurrentContextInitialized ) {
            pthread_key_create( &sThreadSpecificCurrentContextKey, NULL );
            sThreadSpecificCurrentContextInitialized = true;
        }
        if( force || ( pthread_getspecific( sThreadSpecificCurrentContextKey ) != this ) ) {
            pthread_setspecific( sThreadSpecificCurrentContextKey, this );
//            env()->makeContextCurrent( this );
        }
    }
    
    Context* Context::getCurrent()
    {
        if( ! sThreadSpecificCurrentContextInitialized ) {
            return nullptr;
        }
        return reinterpret_cast<Context*>( pthread_getspecific( sThreadSpecificCurrentContextKey ) );
    }
    
    void Context::reflectCurrent( Context *context )
    {
        if( ! sThreadSpecificCurrentContextInitialized ) {
            pthread_key_create( &sThreadSpecificCurrentContextKey, NULL );
            sThreadSpecificCurrentContextInitialized = true;
        }
        pthread_setspecific( sThreadSpecificCurrentContextKey, context );
    }
    
    Context* context()
    {
        auto ctx = Context::getCurrent();
        assert( ctx != nullptr );
        return ctx;
    }
    
    void setDefaultShaderVars( RenderEncoder & renderEncoder,
                               RenderPipelineStateRef pipeline )
    {
        unsigned long vertBufferIndex = -1;
        unsigned long fragBufferIndex = -1;
        
        // Check the vertex shader for a param named "ciUniforms"
        for( ci::mtl::Argument argument : pipeline->getVertexArguments() )
        {
            std::string argName = argument.getName();
            if ( argName == "ciUniforms" )
            {
                assert(argument.getType() == mtl::ArgumentTypeBuffer);
                vertBufferIndex = argument.getIndex();
            }
        }
        
        // Check the frag shader for a param named "ciUniforms"
        for( ci::mtl::Argument argument : pipeline->getFragmentArguments() )
        {
            std::string argName = argument.getName();
            if ( argName == "ciUniforms" )
            {
                assert(argument.getType() == mtl::ArgumentTypeBuffer);
                fragBufferIndex = argument.getIndex();
            }
        }
        
        if ( vertBufferIndex != -1 || fragBufferIndex != -1 )
        {
            // NOTE: Creating a new buffer on-the-fly.
            // This probably isn't the most efficient way to do this, but
            // it is the most straight forward.
            // NOTE: We're sending all of the data over, assuming the buffer is a ciUniform_t.
            mtl::ciUniforms_t uniforms;
            uniforms.ciModelMatrix = toMtl(mtl::getModelMatrix());
            uniforms.ciModelMatrixInverse = toMtl(glm::inverse( mtl::getModelMatrix() ));
            uniforms.ciModelMatrixInverseTranspose = toMtl(mtl::calcModelMatrixInverseTranspose());
            uniforms.ciViewMatrix = toMtl(mtl::getViewMatrix());
            uniforms.ciViewMatrixInverse = toMtl(mtl::calcViewMatrixInverse());
            uniforms.ciModelView = toMtl(mtl::getModelView());
            uniforms.ciModelViewInverse = toMtl(glm::inverse( mtl::getModelView() ));
            uniforms.ciModelViewInverseTranspose = toMtl( mtl::calcNormalMatrix() );
            uniforms.ciModelViewProjection = toMtl(mtl::getModelViewProjection());
            uniforms.ciModelViewProjectionInverse = toMtl(glm::inverse( mtl::getModelViewProjection()));
            uniforms.ciProjectionMatrix = toMtl(mtl::getProjectionMatrix());
            uniforms.ciProjectionMatrixInverse = toMtl(glm::inverse( mtl::getProjectionMatrix()));
            uniforms.ciViewProjection = toMtl(mtl::getProjectionMatrix() * mtl::getViewMatrix());            
            // TMP: rm `mat4(`
            uniforms.ciNormalMatrix = toMtl(mtl::calcNormalMatrix());
            uniforms.ciNormalMatrix4x4 = toMtl(mat4(mtl::calcNormalMatrix()));
//            uniforms.ciViewportMatrix = toMtl(mtl::calcViewportMatrix());
            uniforms.ciWindowSize = toMtl( app::getWindowSize() );
            uniforms.ciElapsedSeconds = float( app::getElapsedSeconds() );
            uniforms.ciColor = toMtl(context()->getCurrentColor());

            if ( vertBufferIndex != -1 )
            {
                renderEncoder.setVertexBytesAtIndex(&uniforms, mtlConstantSizeOf(ciUniforms_t), vertBufferIndex);
            }
            
            if ( fragBufferIndex != -1 )
            {
                renderEncoder.setFragmentBytesAtIndex(&uniforms, mtlConstantSizeOf(ciUniforms_t), fragBufferIndex);
            }
        }
    }

    void setMatrices( const ci::Camera& cam )
    {
        auto ctx = mtl::context();
        ctx->getViewMatrixStack().back() = cam.getViewMatrix();
        ctx->getProjectionMatrixStack().back() = cam.getProjectionMatrix();
        ctx->getModelMatrixStack().back() = mat4();
    }
    
    void setModelMatrix( const ci::mat4 &m )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() = m;
    }
    
    void setViewMatrix( const ci::mat4 &m )
    {
        auto ctx = mtl::context();
        ctx->getViewMatrixStack().back() = m;
    }
    
    void setProjectionMatrix( const ci::mat4 &m )
    {
        auto ctx = mtl::context();
        ctx->getProjectionMatrixStack().back() = m;
    }
    
    void pushModelMatrix()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().push_back( ctx->getModelMatrixStack().back() );
    }
    
    void popModelMatrix()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().pop_back();
    }
    
    void pushViewMatrix()
    {
        auto ctx = mtl::context();
        ctx->getViewMatrixStack().push_back( ctx->getViewMatrixStack().back() );
    }
    
    void popViewMatrix()
    {
        auto ctx = mtl::context();
        ctx->getViewMatrixStack().pop_back();
    }
    
    void pushProjectionMatrix()
    {
        auto ctx = mtl::context();
        ctx->getProjectionMatrixStack().push_back( ctx->getProjectionMatrixStack().back() );
    }
    
    void popProjectionMatrix()
    {
        auto ctx = mtl::context();
        ctx->getProjectionMatrixStack().pop_back();
    }
    
    void pushModelView()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().push_back( ctx->getModelMatrixStack().back() );
        ctx->getViewMatrixStack().push_back( ctx->getViewMatrixStack().back() );
    }
    
    void popModelView()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().pop_back();
        ctx->getViewMatrixStack().pop_back();
    }
    
    void pushMatrices()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().push_back( ctx->getModelMatrixStack().back() );
        ctx->getViewMatrixStack().push_back( ctx->getViewMatrixStack().back() );
        ctx->getProjectionMatrixStack().push_back( ctx->getProjectionMatrixStack().back() );
    }
    
    void popMatrices()
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().pop_back();
        ctx->getViewMatrixStack().pop_back();
        ctx->getProjectionMatrixStack().pop_back();
    }
    
    void multModelMatrix( const ci::mat4& mtx )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() *= mtx;
    }
    
    void multViewMatrix( const ci::mat4& mtx )
    {
        auto ctx = mtl::context();
        ctx->getViewMatrixStack().back() *= mtx;
    }
    
    void multProjectionMatrix( const ci::mat4& mtx )
    {
        auto ctx = mtl::context();
        ctx->getProjectionMatrixStack().back() *= mtx;
    }
    
    mat4 getModelMatrix()
    {
        auto ctx = mtl::context();
        return ctx->getModelMatrixStack().back();
    }
    
    mat4 getViewMatrix()
    {
        auto ctx = mtl::context();
        return ctx->getViewMatrixStack().back();
    }
    
    mat4 getProjectionMatrix()
    {
        auto ctx = mtl::context();
        return ctx->getProjectionMatrixStack().back();
    }
    
    mat4 getModelView()
    {
        auto ctx = mtl::context();
        return ctx->getViewMatrixStack().back() * ctx->getModelMatrixStack().back();
    }
    
    mat4 getModelViewProjection()
    {
        auto ctx = mtl::context();
        return ctx->getProjectionMatrixStack().back() * ctx->getViewMatrixStack().back() * ctx->getModelMatrixStack().back();
    }
    
    mat4 calcViewMatrixInverse()
    {
        return glm::inverse( getViewMatrix() );
    }
    
    mat3 calcNormalMatrix()
    {
        return glm::inverseTranspose( glm::mat3( getModelView() ) );
    }
    
    mat3 calcModelMatrixInverseTranspose()
    {
        auto m = glm::inverseTranspose( getModelMatrix() );
        return mat3( m );
    }
    
    mtl::RenderPipelineStateRef & getStockPipeline( const mtl::ShaderDef &shaderDef )
    {
        static std::map<mtl::ShaderDef, mtl::RenderPipelineStateRef> sStockShaders;
        if ( sStockShaders.count(shaderDef) == 0 )
        {
            mtl::RenderPipelineState::Format format;
            if ( shaderDef.getAlphaBlending() )
            {
                format.blendingEnabled();
                if ( shaderDef.getBlendMode() == mtl::BlendModeAdditive )
                {
                    // format.srcColorBlendFactor(mtl::BlendFactorOne);
					format.dstAlphaBlendFactor(mtl::BlendFactorOne);
                    format.dstColorBlendFactor(mtl::BlendFactorOne);
                }
                // TODO: Add mode
            }
            sStockShaders[shaderDef] = PipelineBuilder::buildPipeline(shaderDef, format);
        }
        return sStockShaders.at(shaderDef);
    }
    
    void setMatricesWindowPersp( int screenWidth, int screenHeight, float fovDegrees, float nearPlane, float farPlane, bool originUpperLeft )
    {
        auto ctx = mtl::context();
        
        CameraPersp cam( screenWidth, screenHeight, fovDegrees, nearPlane, farPlane );
        ctx->getModelMatrixStack().back() = mat4();
        ctx->getProjectionMatrixStack().back() = cam.getProjectionMatrix();
        ctx->getViewMatrixStack().back() = cam.getViewMatrix();
        if( originUpperLeft ) {
            ctx->getViewMatrixStack().back() *= glm::scale( vec3( 1, -1, 1 ) );								// invert Y axis so increasing Y goes down.
            ctx->getViewMatrixStack().back() *= glm::translate( vec3( 0, (float) - screenHeight, 0 ) );		// shift origin up to upper-left corner.
        }
    }
    
    void setMatricesWindowPersp( const ci::ivec2& screenSize, float fovDegrees, float nearPlane, float farPlane, bool originUpperLeft )
    {
        setMatricesWindowPersp( screenSize.x, screenSize.y, fovDegrees, nearPlane, farPlane, originUpperLeft );
    }
    
    void setMatricesWindow( int screenWidth, int screenHeight, bool originUpperLeft )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() = mat4();
        ctx->getViewMatrixStack().back() = mat4();
        
        float sx = 2.0f / (float)screenWidth;
        float sy = 2.0f / (float)screenHeight;
        float ty = -1;
        
        if( originUpperLeft ) {
            sy *= -1;
            ty *= -1;
        }
        
        mat4 &m = ctx->getProjectionMatrixStack().back();
        m = mat4( sx, 0,  0, 0,
                  0, sy,  0, 0,
                  0,  0, -1, 0,
                 -1, ty,  0, 1 );
    }
    
    void setMatricesWindow( const ci::ivec2& screenSize, bool originUpperLeft )
    {
        setMatricesWindow( screenSize.x, screenSize.y, originUpperLeft );
    }
    
    void rotate( const quat &quat )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() *= toMat4( quat );
    }
    
    void rotate( float angleRadians, const vec3 &axis )
    {
        if( math<float>::abs( angleRadians ) > EPSILON_VALUE ) {
            auto ctx = mtl::context();
            ctx->getModelMatrixStack().back() *= glm::rotate( angleRadians, axis );
        }
    }
    
    void scale( const ci::vec3& v )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() *= glm::scale( v );
    }
    
    void translate( const ci::vec3& v )
    {
        auto ctx = mtl::context();
        ctx->getModelMatrixStack().back() *= glm::translate( v );
    }
    
    vec3 windowToObjectCoord( const mat4 &modelMatrix, const ci::vec2 &coordinate, const std::pair<vec2,vec2> &viewport, float z)
    {
        // Build the viewport (x, y, width, height).
        vec2 size = viewport.second;
        vec4 vp = vec4( viewport.first.x, viewport.first.y, viewport.second.x, viewport.second.y );
        
        // Calculate the view-projection matrix.
        mat4 viewProjectionMatrix = mtl::getProjectionMatrix() * mtl::getViewMatrix();
        
        // Calculate the intersection of the mouse ray with the near (z=0) and far (z=1) planes.
        vec3 nearPlane = glm::unProject( vec3( coordinate.x, size.y - coordinate.y, 0 ), modelMatrix, viewProjectionMatrix, vp );
        vec3 farPlane = glm::unProject( vec3( coordinate.x, size.y - coordinate.y, 1 ), modelMatrix, viewProjectionMatrix, vp );
        
        // Calculate world position.
        return ci::lerp( nearPlane, farPlane, ( z - nearPlane.z ) / ( farPlane.z - nearPlane.z ) );
    }

    vec3 objectToWindowCoord( const mat4 &modelMatrix, const ci::vec3 &coordinate, const std::pair<vec2,vec2> &viewport )
    {
        // Build the viewport (x, y, width, height).
        vec4 vp = vec4( viewport.first.x, viewport.first.y, viewport.second.x, viewport.second.y );
        
        // Calculate the view-projection matrix.
        mat4 viewProjectionMatrix = mtl::getProjectionMatrix() * mtl::getViewMatrix();
        
        return glm::project( coordinate, modelMatrix, viewProjectionMatrix, vp );
    }

//    vec2 objectToWindowCoord( const mat4 &modelMatrix, const ci::vec3 &coordinate, const std::pair<vec2,vec2> &viewport )
//    {
//        return vec2( objectToWindowCoord(modelMatrix, coordinate, viewport) );
//    }
    
    void color( float r, float g, float b )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( ColorAf( r, g, b, 1.0f ) );
    }
    
    void color( float r, float g, float b, float a )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( ColorAf( r, g, b, a ) );
    }
    
    void color( const ci::Color &c )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( c );
    }
    
    void color( const ci::ColorA &c )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( c );
    }
    
    void color( const ci::Color8u &c )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( c );
    }
    
    void color( const ci::ColorA8u &c )
    {
        auto ctx = mtl::context();
        ctx->setCurrentColor( c );
    }

    std::string uniformSemanticToString( UniformSemantic uniformSemantic )
    {
        switch( uniformSemantic ) {
            case UNIFORM_MODEL_MATRIX: return "UNIFORM_MODEL_MATRIX";
            case UNIFORM_MODEL_MATRIX_INVERSE: return "UNIFORM_MODEL_MATRIX_INVERSE";
            case UNIFORM_MODEL_MATRIX_INVERSE_TRANSPOSE: return "UNIFORM_MODEL_MATRIX_INVERSE_TRANSPOSE";
            case UNIFORM_VIEW_MATRIX: return "UNIFORM_VIEW_MATRIX";
            case UNIFORM_VIEW_MATRIX_INVERSE: return "UNIFORM_VIEW_MATRIX_INVERSE";
            case UNIFORM_MODEL_VIEW: return "UNIFORM_MODEL_VIEW";
            case UNIFORM_MODEL_VIEW_INVERSE: return "UNIFORM_MODEL_VIEW_INVERSE";
            case UNIFORM_MODEL_VIEW_INVERSE_TRANSPOSE: return "UNIFORM_MODEL_VIEW_INVERSE_TRANSPOSE";
            case UNIFORM_MODEL_VIEW_PROJECTION: return "UNIFORM_MODEL_VIEW_PROJECTION";
            case UNIFORM_MODEL_VIEW_PROJECTION_INVERSE: return "UNIFORM_MODEL_VIEW_PROJECTION_INVERSE";
            case UNIFORM_PROJECTION_MATRIX: return "UNIFORM_PROJECTION_MATRIX";
            case UNIFORM_PROJECTION_MATRIX_INVERSE: return "UNIFORM_PROJECTION_MATRIX_INVERSE";
            case UNIFORM_VIEW_PROJECTION: return "UNIFORM_VIEW_PROJECTION";
            case UNIFORM_NORMAL_MATRIX: return "UNIFORM_NORMAL_MATRIX";
//            case UNIFORM_VIEWPORT_MATRIX: return "UNIFORM_VIEWPORT_MATRIX";
            case UNIFORM_WINDOW_SIZE: return "UNIFORM_WINDOW_SIZE";
            case UNIFORM_ELAPSED_SECONDS: return "UNIFORM_ELAPSED_SECONDS";
            case UNIFORM_USER_DEFINED: return "UNIFORM_USER_DEFINED";
            default: return "";
        }
    }
    
} } // namespace cinder::mtl
