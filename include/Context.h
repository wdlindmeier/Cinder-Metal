//
//  Context.hpp
//
//  Created by William Lindmeier on 1/20/16.
//
//

#pragma once

#include "cinder/Color.h"
#include "cinder/Cinder.h"
#include "RenderEncoder.h"
#include "RenderPipelineState.h"
#include "DataBuffer.h"

namespace cinder { namespace mtl {
    
    class Context;
    typedef std::shared_ptr<Context> ContextRef;
    
    class ShaderDef;

    class Context {
        public:
        struct PlatformData {
            PlatformData() : mDebug( false ), mObjectTracking( false ), mDebugLogSeverity( 0 ), mDebugBreakSeverity( 0 )
            {}
            
            virtual ~PlatformData() {}
            
            bool		mDebug, mObjectTracking;
            unsigned int mDebugLogSeverity, mDebugBreakSeverity;
        };
        
        static ContextRef	create( const Context *sharedContext );
        static ContextRef	createFromExisting( const std::shared_ptr<PlatformData> &platformData );
        
        ~Context();
        
        const std::shared_ptr<PlatformData>		getPlatformData() const { return mPlatformData; }
        
        //! Makes this the currently active Metal Context. If \a force then the cached pointer to the current Context is ignored.
        void			makeCurrent( bool force = false ) const;
        //! Returns the thread's currently active Metal Context
        static Context*	getCurrent();
        //! Set thread's local storage to reflect \a context as the active Context
        static void		reflectCurrent( Context *context );
        
        //! Returns a reference to the stack of Model matrices
        std::vector<mat4>&			getModelMatrixStack() { return mModelMatrixStack; }
        //! Returns a const reference to the stack of Model matrices
        const std::vector<mat4>&	getModelMatrixStack() const { return mModelMatrixStack; }
        //! Returns a reference to the stack of View matrices
        std::vector<mat4>&			getViewMatrixStack() { return mViewMatrixStack; }
        //! Returns a const reference to the stack of Model matrices
        const std::vector<mat4>&	getViewMatrixStack() const { return mViewMatrixStack; }
        //! Returns a reference to the stack of Projection matrices
        std::vector<mat4>&			getProjectionMatrixStack() { return mProjectionMatrixStack; }
        //! Returns a const reference to the stack of Projection matrices
        const std::vector<mat4>&	getProjectionMatrixStack() const { return mProjectionMatrixStack; }
        
        //! Returns the current active color, used in immediate-mode emulation and as UNIFORM_COLOR
        const ColorAf&              getCurrentColor() const { return mColor; }
        void                        setCurrentColor( const ColorAf &color ) { mColor = color; }

        private:
        
        Context( const std::shared_ptr<PlatformData> &platformData );

        std::shared_ptr<PlatformData>	mPlatformData;

        ci::ColorAf                 mColor;
        std::vector<mat4>           mModelMatrixStack;
        std::vector<mat4>           mViewMatrixStack;
        std::vector<mat4>           mProjectionMatrixStack;

    };

    // Remember to add a matching case to uniformSemanticToString
    enum UniformSemantic {
        UNIFORM_MODEL_MATRIX,
        UNIFORM_MODEL_MATRIX_INVERSE,
        UNIFORM_MODEL_MATRIX_INVERSE_TRANSPOSE,
        UNIFORM_VIEW_MATRIX,
        UNIFORM_VIEW_MATRIX_INVERSE,
        UNIFORM_MODEL_VIEW,
        UNIFORM_MODEL_VIEW_INVERSE,
        UNIFORM_MODEL_VIEW_INVERSE_TRANSPOSE,
        UNIFORM_MODEL_VIEW_PROJECTION,
        UNIFORM_MODEL_VIEW_PROJECTION_INVERSE,
        UNIFORM_PROJECTION_MATRIX,
        UNIFORM_PROJECTION_MATRIX_INVERSE,
        UNIFORM_VIEW_PROJECTION,
        UNIFORM_NORMAL_MATRIX,
//        UNIFORM_VIEWPORT_MATRIX,
        UNIFORM_WINDOW_SIZE,
        UNIFORM_ELAPSED_SECONDS,
        UNIFORM_USER_DEFINED
    };
    
    Context* context();

    void setDefaultShaderVars( RenderEncoder & renderEncoder, RenderPipelineStateRef pipeline);

    //! Sets the View and Projection matrices based on a Camera
    void setMatrices( const ci::Camera &cam );
    void setModelMatrix( const ci::mat4 &m );
    void setViewMatrix( const ci::mat4 &m );
    void setProjectionMatrix( const ci::mat4 &m );
    void pushModelMatrix();
    void popModelMatrix();
    void pushViewMatrix();
    void popViewMatrix();
    void pushProjectionMatrix();
    void popProjectionMatrix();
    //! Pushes Model and View matrices
    void pushModelView();
    //! Pops Model and View matrices
    void popModelView();
    //! Pushes Model, View and Projection matrices
    void pushMatrices();
    //! Pops Model, View and Projection matrices
    void popMatrices();
    void multModelMatrix( const ci::mat4 &mtx );
    void multViewMatrix( const ci::mat4 &mtx );
    void multProjectionMatrix( const ci::mat4 &mtx );
    
    mat4 getModelMatrix();
    mat4 getViewMatrix();
    mat4 getProjectionMatrix();
    mat4 getModelView();
    mat4 getModelViewProjection();
    mat4 calcViewMatrixInverse();
    mat3 calcModelMatrixInverseTranspose();
    mat3 calcNormalMatrix();
//    mat4 calcViewportMatrix();
    
    mtl::RenderPipelineStateRef & getStockPipeline( const mtl::ShaderDef &shaderDef );

    void setMatricesWindowPersp( int screenWidth, int screenHeight, float fovDegrees = 60.0f, float nearPlane = 1.0f, float farPlane = 1000.0f, bool originUpperLeft = true );
    void setMatricesWindowPersp( const ci::ivec2 &screenSize, float fovDegrees = 60.0f, float nearPlane = 1.0f, float farPlane = 1000.0f, bool originUpperLeft = true );
    void setMatricesWindow( int screenWidth, int screenHeight, bool originUpperLeft = true );
    void setMatricesWindow( const ci::ivec2 &screenSize, bool originUpperLeft = true );
    
    void rotate( const quat &quat );
    //! Rotates the Model matrix by \a angleRadians around the \a axis
    void rotate( float angleRadians, const ci::vec3 &axis );
    //! Rotates the Model matrix by \a angleRadians around the axis (\a x,\a y,\a z)
    inline void rotate( float angleRadians, float xAxis, float yAxis, float zAxis ) { rotate( angleRadians, ci::vec3(xAxis, yAxis, zAxis) ); }
    //! Rotates the Model matrix by \a zRadians around the z-axis
    inline void rotate( float zRadians ) { rotate( zRadians, vec3( 0, 0, 1 ) ); }
    
    //! Scales the Model matrix by \a v
    void scale( const ci::vec3 &v );
    //! Scales the Model matrix by (\a x,\a y, \a z)
    inline void scale( float x, float y, float z ) { scale( vec3( x, y, z ) ); }
    //! Scales the Model matrix by \a v
    inline void scale( const ci::vec2 &v ) { scale( vec3( v.x, v.y, 1 ) ); }
    //! Scales the Model matrix by (\a x,\a y, 1)
    inline void scale( float x, float y ) { scale( vec3( x, y, 1 ) ); }
    
    //! Translates the Model matrix by \a v
    void translate( const ci::vec3 &v );
    //! Translates the Model matrix by (\a x,\a y,\a z )
    inline void translate( float x, float y, float z ) { translate( vec3( x, y, z ) ); }
    //! Translates the Model matrix by \a v
    inline void translate( const ci::vec2 &v ) { translate( vec3( v, 0 ) ); }
    //! Translates the Model matrix by (\a x,\a y)
    inline void translate( float x, float y ) { translate( vec3( x, y, 0 ) ); }
    
    //! Returns the object space coordinate of the specified window \a coordinate, using the specified \a modelMatrix and the currently active view and projection matrices.
    vec3 windowToObjectCoord( const mat4 &modelMatrix, const vec2 &coordinate, const std::pair<vec2,vec2> & viewport, float z = 0.0f );
    //! Returns the window coordinate of the specified world \a coordinate, using the specified \a modelMatrix and the currently active view and projection matrices.
    vec3 objectToWindowCoord( const mat4 &modelMatrix, const vec3 &coordinate, const std::pair<vec2,vec2> & viewport );
    //vec2 objectToWindowCoord( const mat4 &modelMatrix, const vec3 &coordinate, const std::pair<vec2,vec2> & viewport );
    //! Returns the object space coordinate of the specified window \a coordinate, using the currently active model, view and projection matrices.
    inline vec3 windowToObjectCoord( const vec2 &coordinate, const std::pair<vec2,vec2> &viewport, float z = 0.0f ) { return windowToObjectCoord( mtl::getModelMatrix(), coordinate, viewport, z ); }
    //! Returns the window coordinate of the specified world \a coordinate, using the currently active model, view and projection matrices.
    inline vec3 objectToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> &viewport ) { return objectToWindowCoord( mtl::getModelMatrix(), coordinate, viewport ); }
//    inline vec2 objectToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> &viewport ) { return objectToWindowCoord( mtl::getModelMatrix(), coordinate, viewport ); }
    //! Returns the world space coordinate of the specified window \a coordinate, using the currently active view and projection matrices.
    inline vec3 windowToWorldCoord( const vec2 &coordinate, const std::pair<vec2,vec2> &viewport, float z = 0.0f ) { return windowToObjectCoord( mat4(), coordinate, viewport, z ); }
    //! Returns the window coordinate of the specified world \a coordinate, using the currently active view and projection matrices.
//    inline vec2 worldToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> & viewport ) { return objectToWindowCoord( mat4(), coordinate, viewport ); }
    inline vec3 worldToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> & viewport ) { return objectToWindowCoord( mat4(), coordinate, viewport ); }
    
    void color( float r, float g, float b );
    void color( float r, float g, float b, float a );
    void color( const ci::Color &c );
    void color( const ci::ColorA &c );
    void color( const ci::Color8u &c );
    void color( const ci::ColorA8u &c );
    
    //! Converts a UniformSemantic to its name
    std::string uniformSemanticToString( UniformSemantic uniformSemantic );
    
    class Exception : public cinder::Exception {
        public:
        Exception()	{}
        Exception( const std::string &description ) : cinder::Exception( description )	{}
    };
    
    class ExceptionUnknownTarget : public Exception {
    };
    
} } // namespace cinder::mtl

