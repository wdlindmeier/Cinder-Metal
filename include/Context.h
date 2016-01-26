//
//  Context.hpp
//  Batch
//
//  Created by William Lindmeier on 1/20/16.
//
//

#pragma once

//#include "cinder/gl/platform.h"
//#include "cinder/Camera.h"
//#include "cinder/Color.h"
//#include "cinder/GeomIo.h"
//#include "cinder/Matrix44.h"

#include "cinder/Cinder.h"
#include "RenderEncoder.h"
#include "RenderPipelineState.h"
#include "DataBuffer.h"
//#include "metal.h"

namespace cinder { namespace mtl {
    
    class Context;
    typedef std::shared_ptr<Context>		ContextRef;
//    class Vbo;
//    typedef std::shared_ptr<Vbo>			VboRef;
//    class Vao;
//    typedef std::shared_ptr<Vao>			VaoRef;
//    class BufferObj;
//    typedef std::shared_ptr<BufferObj>		BufferObjRef;
//    class TransformFeedbackObj;
//    typedef std::shared_ptr<TransformFeedbackObj>	TransformFeedbackObjRef;
//    class Texture2d;
//    typedef std::shared_ptr<Texture2d>		Texture2dRef;
//    class GlslProg;
//    typedef std::shared_ptr<GlslProg>		GlslProgRef;
//    class Fbo;
//    typedef std::shared_ptr<Fbo>			FboRef;
//    class VertBatch;
//    typedef std::shared_ptr<VertBatch>		VertBatchRef;
//    class Renderbuffer;
    
//    class TextureBase;
    
    class Context {
        public:
        struct PlatformData {
            PlatformData() : mDebug( false ), mObjectTracking( false ), mDebugLogSeverity( 0 ), mDebugBreakSeverity( 0 )
            {}
            
            virtual ~PlatformData() {}
            
            bool		mDebug, mObjectTracking;
            GLenum		mDebugLogSeverity, mDebugBreakSeverity;
        };
        
        //! Creates a new OpenGL context, sharing resources and pixel format with sharedContext. This (essentially) must be done from the primary thread on MSW. ANGLE doesn't support multithreaded use. Destroys the platform Context on destruction.
        static ContextRef	create( const Context *sharedContext );
        //! Creates based on an existing platform-specific GL context. \a platformContext is CGLContextObj on Mac OS X, EAGLContext on iOS, HGLRC on MSW. \a platformContext is an HDC on MSW and ignored elsewhere. Does not assume ownership of the platform's context.
        static ContextRef	createFromExisting( const std::shared_ptr<PlatformData> &platformData );
        
        ~Context();
        
        //! Returns the platform-specific OpenGL Context. CGLContextObj on Mac OS X, EAGLContext on iOS
        const std::shared_ptr<PlatformData>		getPlatformData() const { return mPlatformData; }
        
        //! Makes this the currently active OpenGL Context. If \a force then the cached pointer to the current Context is ignored.
        void			makeCurrent( bool force = false ) const;
        //! Returns the thread's currently active OpenGL Context
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
        
//        //! Binds a VAO. Consider using a ScopedVao instead.
//        void		bindVao( Vao *vao );
//        //! Binds a VAO. Consider using a ScopedVao instead.
//        void		bindVao( VaoRef &vao ) { bindVao( vao.get() ); }
//        //! Pushes and binds the VAO \a vao
//        void		pushVao( Vao *vao );
//        //! Pushes and binds the VAO \a vao
//        void		pushVao( const VaoRef &vao ) { pushVao( vao.get() ); }
//        //! Duplicates and pushes the current VAO binding
//        void		pushVao();
//        //! Pops the current VAO binding
//        void		popVao();
//        //! Returns the currently bound VAO
//        Vao*		getVao();
//        //! Restores the VAO binding when code that is not caching aware has invalidated it. Not typically necessary.
//        void		restoreInvalidatedVao();
//        //! Used by object tracking.
//        void		vaoCreated( const Vao *vao );
//        //! Used by object tracking.
//        void		vaoDeleted( const Vao *vao );
        
//        //! Analogous to glViewport(). Sets the viewport based on a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively
//        void					viewport( const std::pair<ivec2, ivec2> &viewport );
//        //! Pushes the viewport based on a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively
//        void					pushViewport( const std::pair<ivec2, ivec2> &viewport );
//        //! Duplicates and pushes the top of the Viewport stack
//        void					pushViewport();
//        //! Pops the viewport. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void					popViewport( bool forceRestore = false );
//        //! Returns a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively of the viewport
//        std::pair<ivec2,ivec2>	getViewport();
//
//        //! Sets the scissor box based on a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively
//        void					setScissor( const std::pair<ivec2, ivec2> &scissor );
//        //! Pushes the scissor box based on a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively
//        void					pushScissor( const std::pair<ivec2, ivec2> &scissor );
//        //! Duplicates and pushes the top of the Scissor box stack
//        void					pushScissor();
//        //! Pushes the scissor box based on a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void					popScissor( bool forceRestore = false );
//        //! Returns a pair<ivec2,ivec2> representing the position of the lower-left corner and the size, respectively of the scissor box
//        std::pair<ivec2, ivec2>	getScissor();
//        
//        //! Analogous to glCullFace( \a face ). Valid arguments are \c GL_FRONT and \c GL_BACK.
//        void					cullFace( GLenum face );
//        //! Pushes the cull face \a face. Valid arguments are \c GL_FRONT and \c GL_BACK.
//        void					pushCullFace( GLenum face );
//        //! Duplicates and pushes the top of the Cull Face stack.
//        void					pushCullFace();
//        //! Pops the top of the Cull Face stack. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void					popCullFace( bool forceRestore = false );
//        //! Returns a GLenum representing the current cull face. Either \c GL_FRONT or \c GL_BACK.
//        GLenum					getCullFace();
//        
//        //! Set the winding order defining front-facing polygons. Valid arguments are \c GL_CW and \c GL_CCW. Default is \c GL_CCW.
//        void					frontFace( GLenum mode );
//        //! Push the winding order defining front-facing polygons. Valid arguments are \c GL_CW and \c GL_CCW. Default is \c GL_CCW.
//        void					pushFrontFace( GLenum mode );
//        //! Push the winding order defining front-facing polygons.
//        void					pushFrontFace();
//        //! Pops the winding order defining front-facing polygons. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void					popFrontFace( bool forceRestore = false );
//        //! Returns the winding order defining front-facing polygons, either \c GL_CW or \c GL_CCW (the default).
//        GLenum					getFrontFace();
//
//#if ! defined( CINDER_GL_ES )
//        //! Analogous to glLogicOp( \a mode ). Valid arguments are \c GL_CLEAR, \c GL_SET, \c GL_COPY, \c GL_COPY_INVERTED, \c GL_NOOP, \c GL_INVERT, \c GL_AND, \c GL_NAND, \c GL_OR, \c GL_NOR, \c GL_XOR, \c GL_EQUIV, \c GL_AND_REVERSE, \c GL_AND_INVERTED, \c GL_OR_REVERSE, or \c GL_OR_INVERTED.
//        void		logicOp( GLenum mode );
//        //! Pushes the logical operation \a mode. Valid arguments are \c GL_CLEAR, \c GL_SET, \c GL_COPY, \c GL_COPY_INVERTED, \c GL_NOOP, \c GL_INVERT, \c GL_AND, \c GL_NAND, \c GL_OR, \c GL_NOR, \c GL_XOR, \c GL_EQUIV, \c GL_AND_REVERSE, \c GL_AND_INVERTED, \c GL_OR_REVERSE, or \c GL_OR_INVERTED.
//        void		pushLogicOp( GLenum mode );
//        //! Pops the top of the Logic Op stack. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popLogicOp( bool forceRestore = false );
//        //! Returns a GLenum representing the current logical operation.
//        GLenum		getLogicOp();
//#endif
//        
//        //! Analogous to glBindBuffer( \a target, \a id )
//        void		bindBuffer( GLenum target, GLuint id );
//        //! Pushes and binds buffer object \a id for the target \a target
//        void		pushBufferBinding( GLenum target, GLuint id );
//        //! Duplicates and pushes the buffer binding for the target \a target
//        void		pushBufferBinding( GLenum target );
//        //! Pops the buffer binding for the target \a target
//        void		popBufferBinding( GLenum target );
//        //! Returns the current object binding for \a target. If not cached, queries the GL for the current value (and caches it).
//        GLuint		getBufferBinding( GLenum target );
//        //! Updates the binding stack without rebinding. Not generally necessary to call directly.
//        void		reflectBufferBinding( GLenum target, GLuint id );
//        //! Used by object tracking.
//        void		bufferCreated( const BufferObj *buffer );
//        //! No-op if BufferObj wasn't bound, otherwise reflects the binding as 0 (in accordance with what GL has done automatically). Also used by object tracking.
//        void		bufferDeleted( const BufferObj *buffer );
//        //! Marks the cache of \a target's buffer binding as invalid. Typically called when a VAO is unbound, against GL_ELEMENT_ARRAY_BUFFER.
//        void		invalidateBufferBindingCache( GLenum target );
//        //! Restores a buffer binding when code that is not caching aware has invalidated it. Not typically necessary.
//        void		restoreInvalidatedBufferBinding( GLenum target );
//        
//        //! Analogous to glBindRenderbuffer( \a target, \a id )
//        void		bindRenderbuffer( GLenum target, GLuint id );
//        //! Pushes and binds renderbuffer object \a id for the target \a target
//        void		pushRenderbufferBinding( GLenum target, GLuint id );
//        //! Duplicates and pushes the renderbuffer binding for the target \a target
//        void		pushRenderbufferBinding( GLenum target );
//        //! Pops the renderbuffer binding for the target \a target
//        void		popRenderbufferBinding( GLenum target );
//        //! Returns the current renderbuffer binding for \a target. If not cached, queries the GL for the current value (and caches it).
//        GLuint		getRenderbufferBinding( GLenum target );
//        //! No-op if Renderbuffer wasn't bound, otherwise reflects the binding as 0 (in accordance with what GL has done automatically).
//        void		renderbufferDeleted( const Renderbuffer *buffer );
//        
//        //! Binds GLSL program \a prog. Analogous to glUseProgram()
//        void				bindGlslProg( const GlslProg* prog );
//        void				bindGlslProg( GlslProgRef& prog ) { bindGlslProg( prog.get() ); }
//        //! Pushes and binds GLSL program \a prog.
//        void				pushGlslProg( const GlslProg* prog );
//        void				pushGlslProg( GlslProgRef& prog ) { pushGlslProg( prog.get() ); }
//        //! Duplicates and pushes the top of the GlslProg stack.
//        void				pushGlslProg();
//        //! Pops the GlslProg stack. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void				popGlslProg( bool forceRestore = false );
//        //! Returns the currently bound GlslProg
//        const GlslProg*		getGlslProg();
        RenderPipelineStateRef  getRenderPipeline();
//        //! Used by object tracking.
//        void				glslProgCreated( const GlslProg *glslProg );
//        //! Used by object tracking.
//        void				glslProgDeleted( const GlslProg *glslProg );
//        
//#if ! defined( CINDER_GL_ES_2 )
//        //! Binds \a ref to the specific \a index within \a target. Analogous to glBindBufferBase()
//        void bindBufferBase( GLenum target, GLuint index, const BufferObjRef &buffer );
//        //! Binds \a ref to the specific \a index within \a target. Analogous to glBindBufferBase()
//        void bindBufferBase( GLenum target, GLuint index, GLuint id );
//        //! Analogous to glBindBufferRange()
//        void bindBufferRange( GLenum target, GLuint index, const BufferObjRef &buffer, GLintptr offset, GLsizeiptr size );
//#endif // ! defined( CINDER_GL_ES_2 )
//#if defined( CINDER_GL_HAS_TRANSFORM_FEEDBACK )
//        //! Binds \a feedbackObj as the current Transform Feedback Object. Also, unbinds currently bound Transform Feedback Obj if one exists.
//        void bindTransformFeedbackObj( const TransformFeedbackObjRef &feedbackObj );
//        //! Calls the currently bound Transform Feedback Object's begin method. Alternatively, if mCachedTransformFeedbackObj is null, this method calls glBeginTransformFeedback.
//        void beginTransformFeedback( GLenum primitiveMode );
//        //! Calls the currently bound Transform Feedback Object's pause method. Alternatively, if mCachedTransformFeedbackObj is null, this method calls glPauseTransformFeedback.
//        void pauseTransformFeedback();
//        //! Calls the currently bound Transform Feedback Object's resume method. Alternatively, if mCachedTransformFeedbackObj is null, this method calls glResumeTransformFeedback.
//        void resumeTransformFeedback();
//        //! Calls the currently bound Transform Feedback Object's end method. Alternatively, if mCachedTransformFeedbackObj is null, this method calls glEndTransformFeedback.
//        void endTransformFeedback();
//        //! Returns mCachedTransformFeedbackObj.
//        TransformFeedbackObjRef transformFeedbackObjGet();
//#endif // defined( CINDER_GL_HAS_TRANSFORM_FEEDBACK )
//        
//        //! Analogous to glBindTexture( \a target, \a textureId ) for the active texture unit
//        void		bindTexture( GLenum target, GLuint textureId );
//        //! Analogous to glBindTexture( \a target, \a textureId ) for texture unit \a textureUnit
//        void		bindTexture( GLenum target, GLuint textureId, uint8_t textureUnit );
//        //! Duplicates and pushes the binding for the target \a target for texture unit \a textureUnit
//        void		pushTextureBinding( GLenum target, uint8_t textureUnit );
//        //! Pushes and binds \a textureId for the target \a target for texture unit \a textureUnit
//        void		pushTextureBinding( GLenum target, GLuint textureId, uint8_t textureUnit );
//        //! Pops the texture binding for the target \a target for texture unit \a textureUnit. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popTextureBinding( GLenum target, uint8_t textureUnit, bool forceRestore = false );
//        //! Returns the current texture binding for \a target for the active texture unit. If not cached, queries the GL for the current value (and caches it).
//        GLuint		getTextureBinding( GLenum target );
//        //! Returns the current texture binding for \a target for texture unit \a textureUnit. If not cached, queries the GL for the current value (and caches it).
//        GLuint		getTextureBinding( GLenum target, uint8_t textureUnit );
//        //! Used by object tracking.
//        void		textureCreated( const TextureBase *texture );
//        //! No-op if texture wasn't bound, otherwise reflects the texture unit's binding as 0 (in accordance with what GL has done automatically). Also used by object tracking.
//        void		textureDeleted( const TextureBase *texture );
//        
//        //! Sets the active texture unit; expects values relative to \c 0, \em not GL_TEXTURE0
//        void		setActiveTexture( uint8_t textureUnit );
//        //! Pushes and sets the active texture unit; expects values relative to \c 0, \em not GL_TEXTURE0
//        void		pushActiveTexture( uint8_t textureUnit );
//        //! Duplicates and pushes the active texture unit
//        void		pushActiveTexture();
//        //! Sets the active texture unit; expects values relative to \c 0, \em not GL_TEXTURE0. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popActiveTexture( bool forceRestore = false );
//        //! Returns the active texture unit with values relative to \c 0, \em not GL_TEXTURE0
//        uint8_t		getActiveTexture();
//        
//        //! Analogous to glBindFramebuffer()
//        void		bindFramebuffer( const FboRef &fbo, GLenum target = GL_FRAMEBUFFER );
//        //! Analogous to glBindFramebuffer(). Prefer the FboRef variant when possible. This does not allow gl::Fbo to mark itself as needing multisample resolution.
//        void		bindFramebuffer( GLenum target, GLuint framebuffer );
//        //! Pushes and sets the active framebuffer.
//        void		pushFramebuffer( const FboRef &fbo, GLenum target = GL_FRAMEBUFFER );
//        //! Pushes and sets the active framebuffer. Prefer the FboRef variant when possible. This does not allow gl::Fbo to mark itself as needing multisample resolution.
//        void		pushFramebuffer( GLenum target, GLuint framebuffer = GL_FRAMEBUFFER );
//        //! Duplicates and pushes the active framebuffer.
//        void		pushFramebuffer( GLenum target = GL_FRAMEBUFFER );
//        //! Pops the active framebuffer
//        void		popFramebuffer( GLuint framebuffer = GL_FRAMEBUFFER );
//        //! Unbinds the current FBO (binding the default (screen) framebuffer)
//        void		unbindFramebuffer();
//        //! Returns the ID of the framebuffer currently bound to \a target
//        GLuint		getFramebuffer( GLenum target = GL_FRAMEBUFFER );
//        //! Used by object tracking.
//        void		framebufferCreated( const Fbo *fbo );
//        //! Used by object tracking.
//        void		framebufferDeleted( const Fbo *fbo );
//        
//        //! Analogous to glEnable() or glDisable(). Enables or disables OpenGL capability \a cap
//        void		setBoolState( GLenum cap, GLboolean value );
//        //! Pushes and sets the state stack for OpenGL capability \a cap to \a value.
//        void		pushBoolState( GLenum cap, GLboolean value );
//        //! Duplicates and pushes the state stack for OpenGL capability \a cap.
//        void		pushBoolState( GLenum cap );
//        //! Pops the state stack for OpenGL capability \a cap. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popBoolState( GLenum cap, bool forceRestore = false );
//        //! Synonym for setBoolState(). Enables or disables OpenGL capability \a cap.
//        void		enable( GLenum cap, GLboolean value = true );
//        //! Analogous to glIsEnabled(). Returns whether a given OpenGL capability is enabled or not
//        GLboolean	getBoolState( GLenum cap );
//        //! Enables or disables OpenGL capability \a cap. Calls \a setter rather than glEnable or glDisable. Not generally necessary to call directly.
//        void		setBoolState( GLenum cap, GLboolean value, const std::function<void(GLboolean)> &setter );
//        
//        //! Analogous glBlendFunc(). Consider using a ScopedBlend instead.
//        void		blendFunc( GLenum sfactor, GLenum dfactor );
//        //! Analogous to glBlendFuncSeparate(). Consider using a ScopedBlend instead.
//        void		blendFuncSeparate( GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha );
//        //! Analogous to glBlendFuncSeparate, but pushes values rather than replaces them
//        void		pushBlendFuncSeparate( GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha );
//        //! Duplicates and pushes the glBlendFunc state stack.
//        void		pushBlendFuncSeparate();
//        //! Pops the current blend functions. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popBlendFuncSeparate( bool forceRestore = false );
//        //! Returns the current values for glBendFuncs
//        void		getBlendFuncSeparate( GLenum *resultSrcRGB, GLenum *resultDstRGB, GLenum *resultSrcAlpha, GLenum *resultDstAlpha );
//        
//        //! Sets the current line width
//        void		lineWidth( float lineWidth );
//        //! Pushes and sets the current line width
//        void		pushLineWidth( float lineWidth );
//        //! Duplicates and pushes the current line width.
//        void		pushLineWidth();
//        //! Sets the current line width. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popLineWidth( bool forceRestore = false );
//        //! Returns the current line width.
//        float		getLineWidth();
//        
//        //! Analogous to glDepthMask(). Enables or disables writing into the depth buffer.
//        void		depthMask( GLboolean enable );
//        //! Push the depth buffer writing flag.
//        void		pushDepthMask( GLboolean enable );
//        //! Push the depth buffer writing flag.
//        void		pushDepthMask();
//        //! Pops the depth buffer writing flag. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popDepthMask( bool forceRestore = false );
//        //! Returns the depth buffer writing flag.
//        GLboolean	getDepthMask();
//        
//        //! Set the depth buffer comparison function. Analogous to glDepthFunc(). Valid arguments are \c GL_NEVER, \c GL_LESS, \c GL_EQUAL, \c GL_LEQUAL, \c GL_GREATER, \c GL_NOTEQUAL, \c GL_GEQUAL and \c GL_ALWAYS. Default is \c GL_LESS.
//        void		depthFunc( GLenum func );
//        //! Push the depth buffer comparison function. Valid arguments are \c GL_NEVER, \c GL_LESS, \c GL_EQUAL, \c GL_LEQUAL, \c GL_GREATER, \c GL_NOTEQUAL, \c GL_GEQUAL and \c GL_ALWAYS. Default is \c GL_LESS.
//        void		pushDepthFunc( GLenum func );
//        //! Push the depth buffer comparison function.
//        void		pushDepthFunc();
//        //! Pops the depth buffer comparison function. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popDepthFunc( bool forceRestore = false );
//        //! Returns the depth buffer comparison function, either \c GL_NEVER, \c GL_LESS, \c GL_EQUAL, \c GL_LEQUAL, \c GL_GREATER, \c GL_NOTEQUAL, \c GL_GEQUAL or \c GL_ALWAYS.
//        GLenum		getDepthFunc();

//#if ! defined( CINDER_GL_ES )
//        //! Sets the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK. \c GL_POINT, \c GL_LINE & \c GL_FILL are legal values for \a mode.
//        void		polygonMode( GLenum face, GLenum mode );
//        //! Pushes the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK. \c GL_POINT, \c GL_LINE & \c GL_FILL are legal values for \a mode.
//        void		pushPolygonMode( GLenum face, GLenum mode );
//        //! Pushes the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK.
//        void		pushPolygonMode( GLenum face );
//        //! Pops the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK. If \a forceRestore then redundancy checks are skipped and the hardware state is always set.
//        void		popPolygonMode( GLenum face, bool forceRestore = false );
//        //! Returns the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK.
//        GLenum		getPolygonMode( GLenum face );
//#endif
//        
//        void		sanityCheck();
//        void		printState( std::ostream &os ) const;
//        
//        // Object Tracking
//        //! Returns the container of live Textures. Requires object tracking to be enabled.
//        const std::set<const TextureBase*>&	getLiveTextures() const { return mLiveTextures; }
//        //! Returns the container of live BufferObjs. Requires object tracking to be enabled.
//        const std::set<const BufferObj*>&	getLiveBuffers() const { return mLiveBuffers; }
//        //! Returns the container of live GlslProgs. Requires object tracking to be enabled.
//        const std::set<const GlslProg*>&	getLiveGlslProgs() const { return mLiveGlslProgs; }
//        //! Returns the container of live Vaos. Requires object tracking to be enabled.
//        const std::set<const Vao*>&			getLiveVaos() const { return mLiveVaos; }
//        //! Returns the container of live Fbos. Requires object tracking to be enabled.
//        const std::set<const Fbo*>&			getLiveFbos() const { return mLiveFbos; }
//        
//        // Vertex Attributes
//        //! Analogous to glEnableVertexAttribArray()
//        void		enableVertexAttribArray( GLuint index );
//        //! Analogous to glDisableVertexAttribArray()
//        void		disableVertexAttribArray( GLuint index );
//        //! Analogous to glVertexAttribPointer()
//        void		vertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer );
//#if ! defined( CINDER_GL_ES_2 )
//        //! Analogous to glVertexAttribIPointer()
//        void		vertexAttribIPointer( GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer );
//#endif // ! defined( CINDER_GL_ES )
//        //! Analogous to glVertexAttribDivisor()
//        void		vertexAttribDivisor( GLuint index, GLuint divisor );
//        //! Analogous to glVertexAttrib1f()
//        void		vertexAttrib1f( GLuint index, float v0 );
//        //! Analogous to glVertexAttrib2f()
//        void		vertexAttrib2f( GLuint index, float v0, float v1 );
//        //! Analogous to glVertexAttrib3f()
//        void		vertexAttrib3f( GLuint index, float v0, float v1, float v2 );
//        //! Analogous to glVertexAttrib4f()
//        void		vertexAttrib4f( GLuint index, float v0, float v1, float v2, float v3 );
//        
//        //! Analogous to glDrawArrays()
//        void		drawArrays( GLenum mode, GLint first, GLsizei count );
//        //! Analogous to glDrawElements()
//        void		drawElements( GLenum mode, GLsizei count, GLenum type, const GLvoid *indices );
//#if defined( CINDER_GL_HAS_DRAW_INSTANCED )
//        //! Analogous to glDrawArraysInstanced()
//        void		drawArraysInstanced( GLenum mode, GLint first, GLsizei count, GLsizei primcount );
//        //! Analogous to glDrawElementsInstanced()
//        void		drawElementsInstanced( GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei primcount );
//#endif // defined( CINDER_GL_HAS_DRAW_INSTANCED )
        
        //! Returns the current active color, used in immediate-mode emulation and as UNIFORM_COLOR
//        const ColorAf&		getCurrentColor() const { return mColor; }
//        void				setCurrentColor( const ColorAf &color ) { mColor = color; }
//        GlslProgRef&		getStockShader( const ShaderDef &shaderDef );
//        void				setDefaultShaderVars();
        
//        //! Returns default VBO for vertex array data, ensuring it is at least \a requiredSize bytes. Designed for use with convenience functions.
//        VboRef			getDefaultArrayVbo( size_t requiredSize = 0 );
//        //! Returns default VBO for element array data, ensuring it is at least \a requiredSize bytes. Designed for use with convenience functions.
//        VboRef			getDefaultElementVbo( size_t requiredSize = 0 );
//        //! Returns default VAO, designed for use with convenience functions.
//        Vao*			getDefaultVao();
//        //! Returns a VBO for drawing textured rectangles; used by gl::draw(TextureRef)
//        VboRef			getDrawTextureVbo();
//        //! Returns a VBO for drawing textured rectangles; used by gl::draw(TextureRef)
//        Vao*			getDrawTextureVao();
//        
//        //! Returns a reference to the immediate mode emulation structure. Generally use gl::begin() and friends instead.
//        VertBatch&		immediate() { return *mImmediateMode; }
        
//#if defined( CINDER_GL_HAS_DEBUG_OUTPUT )
//        static void	 __stdcall debugMessageCallback( GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *message, void *userParam );
//#endif
//        
        protected:
        //! Returns \c true if \a value is different from the previous top of the stack
        template<typename T>
        bool		pushStackState( std::vector<T> &stack, T value );
        //! Returns \c true if the new top of \a stack is different from the previous top, or the stack is empty
        template<typename T>
        bool		popStackState( std::vector<T> &stack );
        //! Returns \c true if \a value is different from the previous top of the stack
        template<typename T>
        bool		setStackState( std::vector<T> &stack, T value );
        //! Returns \c true if \a result is valid; will return \c false when \a stack was empty
        template<typename T>
        bool		getStackState( std::vector<T> &stack, T *result );
        
//        void allocateDefaultVboAndVao();
        
//        std::map<ShaderDef,GlslProgRef>		mStockShaders;
//        
//        std::map<GLenum,std::vector<int>>	mBufferBindingStack;
//        std::map<GLenum,std::vector<int>>	mRenderbufferBindingStack;
//        std::vector<const GlslProg*>		mGlslProgStack;
//        std::vector<Vao*>					mVaoStack;
//        
//#if defined( CINDER_GL_HAS_TRANSFORM_FEEDBACK )
//        TransformFeedbackObjRef				mCachedTransformFeedbackObj;
//#endif // defined( CINDER_GL_HAS_TRANSFORM_FEEDBACK )
//        
//        // Blend state stacks
//        std::vector<GLint>					mBlendSrcRgbStack, mBlendDstRgbStack;
//        std::vector<GLint>					mBlendSrcAlphaStack, mBlendDstAlphaStack;
//
        // TODO: ?
//#if defined( CINDER_GL_ES_2 ) && (! defined( CINDER_COCOA_TOUCH )) && (! defined( CINDER_GL_ANGLE ))
//        std::vector<GLint>			mFramebufferStack;
//#else
//        std::vector<GLint>			mReadFramebufferStack, mDrawFramebufferStack;
//#endif
        
        // TODO: ?
//        std::vector<GLenum>			mCullFaceStack;
//        std::vector<GLenum>			mFrontFaceStack;
//        
//#if ! defined( CINDER_GL_ES )
//        std::vector<GLenum>			mLogicOpStack;
//        std::vector<GLenum>			mPolygonModeStack;
//#endif
//        
//        std::vector<GLboolean>		mDepthMaskStack;
//        std::vector<GLenum>			mDepthFuncStack;
        
//        std::map<GLenum,std::vector<GLboolean>>	mBoolStateStack;
        // map<TextureUnit,map<TextureTarget,vector<Binding ID Stack>>>
//        std::map<uint8_t,std::map<GLenum,std::vector<GLint>>>	mTextureBindingStack;
//        std::vector<uint8_t>					mActiveTextureStack;
        
//        VaoRef						mDefaultVao;
//        VboRef						mDefaultArrayVbo[4], mDefaultElementVbo;
//        uint8_t						mDefaultArrayVboIdx;
//        VertBatchRef				mImmediateMode;
//        VaoRef						mDrawTextureVao;
//        VboRef						mDrawTextureVbo;
        
        private:
        
        Context( const std::shared_ptr<PlatformData> &platformData );
//
//        void	allocateDrawTextureVboAndVao();
//        
        std::shared_ptr<PlatformData>	mPlatformData;
        
//        std::vector<std::pair<ivec2,ivec2>>		mViewportStack;
//        std::vector<std::pair<ivec2,ivec2>>		mScissorStack;
        
//        VaoRef						mImmVao; // Immediate-mode VAO
//        VboRef						mImmVbo; // Immediate-mode VBO
        
//        ci::ColorAf					mColor;	
        std::vector<mat4>		mModelMatrixStack;
        std::vector<mat4>		mViewMatrixStack;	
        std::vector<mat4>		mProjectionMatrixStack;
//        std::vector<float>		mLineWidthStack;
        
//        // Debug
//        GLenum						mDebugLogSeverity;
//        GLenum						mDebugBreakSeverity;
        
        // Object tracking
//        bool							mObjectTrackingEnabled;
//        std::set<const TextureBase*>	mLiveTextures;
//        std::set<const BufferObj*>		mLiveBuffers;
//        std::set<const GlslProg*>		mLiveGlslProgs;
//        std::set<const Vao*>			mLiveVaos;
//        std::set<const Fbo*>			mLiveFbos;
//        
//        friend class				Environment;
//        
//        friend class				Texture2d;
        
    };

//    typedef std::shared_ptr<class GlslProg>			GlslProgRef;
//    typedef std::shared_ptr<class BufferObj>		BufferObjRef;
    
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
//    class Environment* env();

    // TODO: ?
//    void enableVerticalSync( bool enable = true );
//    bool isVerticalSyncEnabled();
    
//    GLenum getError();
//    std::string getErrorString( GLenum err );
//    void checkError();
    
    //! Returns whether OpenGL Extension \a extName is implemented on the hardware. For example, \c "GL_EXT_texture_swizzle". Case insensitive.
//    bool isExtensionAvailable( const std::string &extName );
//    //! Returns the OpenGL version number as a pair<major,minor>
//    std::pair<GLint,GLint>	getVersion();
//    std::string getVersionString();
    
//    GlslProgRef& getStockShader( const class ShaderDef &shader );
//    void bindStockShader( const class ShaderDef &shader );
    void setDefaultShaderVars( RenderEncoder & renderEncoder, RenderPipelineStateRef pipeline);
    
//    void clear( const ColorA &color = ColorA::black(), bool clearDepthBuffer = true );
//    void clear( GLbitfield mask );
//    void clearColor( const ColorA &color );
//    void clearDepth( const double depth );
//    void clearDepth( const float depth );
//    void clearStencil( const int s );
    
//    void colorMask( GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha );
//    void depthMask( GLboolean flag );
//    void stencilMask( GLboolean mask );
//    
//    void stencilFunc( GLenum func, GLint ref, GLuint mask );
//    void stencilOp( GLenum fail, GLenum zfail, GLenum zpass );
    
//    std::pair<ivec2, ivec2> getViewport();
//    void viewport( const std::pair<ivec2, ivec2> positionAndSize );
//    inline void viewport( int x, int y, int width, int height ) { viewport( std::pair<ivec2, ivec2>( ivec2( x, y ), ivec2( width, height ) ) ); }
//    inline void viewport( const ivec2 &position, const ivec2 &size ) { viewport( std::pair<ivec2, ivec2>( position, size ) ); }
//    inline void viewport( const ivec2 &size ) { viewport( ivec2(), size ); }
//    void pushViewport( const std::pair<ivec2, ivec2> positionAndSize );
//    inline void pushViewport() { pushViewport( getViewport() ); }
//    inline void pushViewport( int x, int y, int width, int height ) { pushViewport( std::pair<ivec2, ivec2>( ivec2( x, y ), ivec2( width, height ) ) ); }
//    inline void pushViewport( const ivec2 &position, const ivec2 &size ) { pushViewport( std::pair<ivec2, ivec2>( position, size ) ); }
//    inline void pushViewport( const ivec2 &size ) { pushViewport( ivec2(), size ); }
//    void popViewport();
    
//    std::pair<ivec2, ivec2> getScissor();
//    void scissor( const std::pair<ivec2, ivec2> positionAndSize );
//    inline void scissor( int x, int y, int width, int height ) { scissor( std::pair<ivec2, ivec2>( ivec2( x, y ), ivec2( width, height ) ) ); }
//    inline void scissor( const ivec2 &position, const ivec2 &size ) { scissor( std::pair<ivec2, ivec2>( position, size ) ); }
    
//    void enable( GLenum state, bool enable = true );
//    inline void disable( GLenum state ) { enable( state, false ); }

    // TODO: ?
//    void enableAlphaBlending( bool premultiplied = false );
//    void disableAlphaBlending();
//    void enableAdditiveBlending();

    // TODO: ?
//    //! Specifies whether polygons are culled. Equivalent to calling enable( \c GL_CULL_FACE, \a enable ). Specify front or back faces with gl::cullFace().
//    void enableFaceCulling( bool enable = true );
//    //! Specifies whether front or back-facing polygons are culled (as specified by \a face) when polygon culling is enabled. Valid values are \c GL_BACK and \c GL_FRONT.
//    void cullFace( GLenum face );
    

    // TODO: ?
//    void disableDepthRead();
//    void disableDepthWrite();
//    void enableDepthRead( bool enable = true );
//    void enableDepthWrite( bool enable = true );

    // TODO: ?
//    void enableStencilRead( bool enable = true );
//    void disableStencilRead();
//    void enableStencilWrite( bool enable = true );
//    void disableStencilWrite();
    
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
    vec2 objectToWindowCoord( const mat4 &modelMatrix, const vec3 &coordinate, const std::pair<vec2,vec2> & viewport );
    //! Returns the object space coordinate of the specified window \a coordinate, using the currently active model, view and projection matrices.
    inline vec3 windowToObjectCoord( const vec2 &coordinate, const std::pair<vec2,vec2> &viewport, float z = 0.0f ) { return windowToObjectCoord( mtl::getModelMatrix(), coordinate, viewport, z ); }
    //! Returns the window coordinate of the specified world \a coordinate, using the currently active model, view and projection matrices.
    inline vec2 objectToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> &viewport ) { return objectToWindowCoord( mtl::getModelMatrix(), coordinate, viewport ); }
    //! Returns the world space coordinate of the specified window \a coordinate, using the currently active view and projection matrices.
    inline vec3 windowToWorldCoord( const vec2 &coordinate, const std::pair<vec2,vec2> &viewport, float z = 0.0f ) { return windowToObjectCoord( mat4(), coordinate, viewport, z ); }
    //! Returns the window coordinate of the specified world \a coordinate, using the currently active view and projection matrices.
    inline vec2 worldToWindowCoord( const vec3 &coordinate, const std::pair<vec2,vec2> & viewport ) { return objectToWindowCoord( mat4(), coordinate, viewport ); }
    
//    void begin( GLenum mode );
//    void end();
//    
//#if ! defined( CINDER_GL_ES_2 )
//    void bindBufferBase( GLenum target, int index, BufferObjRef buffer );
//    
//    void beginTransformFeedback( GLenum primitiveMode );
//    void endTransformFeedback();
//    void resumeTransformFeedback();
//    void pauseTransformFeedback();
//    
//    // Tesselation
//    //! Specifies the parameters that will be used for patch primitives. Analogous to glPatchParameteri().
//    void patchParameteri( GLenum pname, GLint value );
//    //! Specifies the parameters that will be used for patch primitives. Analogous to glPatchParameterfv().
//    void patchParameterfv( GLenum pname, GLfloat *value );
//#endif

//    void color( float r, float g, float b );
//    void color( float r, float g, float b, float a );
//    void color( const ci::Color &c );
//    void color( const ci::ColorA &c );
//    void color( const ci::Color8u &c );
//    void color( const ci::ColorA8u &c );
//    
//    void texCoord( float s, float t );
//    void texCoord( float s, float t, float r );
//    void texCoord( float s, float t, float r, float q );
//    void texCoord( const ci::vec2 &v );
//    void texCoord( const ci::vec3 &v );
//    void texCoord( const ci::vec4 &v );
//    
//    void vertex( float x, float y );
//    void vertex( float x, float y, float z );
//    void vertex( float x, float y, float z, float w );
//    void vertex( const ci::vec2 &v );
//    void vertex( const ci::vec3 &v );
//    void vertex( const ci::vec4 &v );
//    
//#if ! defined( CINDER_GL_ES )
//    //! Sets the current polygon rasterization mode. \a face must be \c GL_FRONT_AND_BACK. \c GL_POINT, \c GL_LINE & \c GL_FILL are legal values for \a mode.
//    void polygonMode( GLenum face, GLenum mode );
//    //! Enables wireframe drawing by setting the \c PolygonMode to \c GL_LINE.
//    void enableWireframe();
//    //! Disables wireframe drawing.
//    void disableWireframe();
//    //! Returns whether wirefrom drawing is enabled.
//    bool isWireframeEnabled();
//    //! Toggles wireframe drawing according to \a enable.
//    inline void setWireframeEnabled( bool enable = true )	{ if( enable ) enableWireframe(); else disableWireframe(); }
//#endif

//    //! Sets the width of rasterized lines to \a width. The initial value is 1. Analogous to glLineWidth().
//    void	lineWidth( float width );
//#if ! defined( CINDER_GL_ES )
//    //! Specifies the rasterized diameter of points. If point size mode is disabled (via gl::disable \c GL_PROGRAM_POINT_SIZE), this value will be used to rasterize points. Otherwise, the value written to the shading language built-in variable \c gl_PointSize will be used. Analogous to glPointSize().
//    void	pointSize( float size );
//#endif
    
//    //! Converts a geom::Primitive to an OpenGL primitive mode( GL_TRIANGLES, GL_TRIANGLE_STRIP, etc )
//    GLenum toGl( geom::Primitive prim );
//    //! Converts an OpenGL primitive mode( GL_TRIANGLES, GL_TRIANGLE_STRIP, etc ) to a geom::Primitive
//    geom::Primitive toGeomPrimitive( GLenum prim );
    //! Converts a UniformSemantic to its name
    std::string uniformSemanticToString( UniformSemantic uniformSemantic );
    
//    // Vertex Attributes
//    //! Analogous to glVertexAttribPointer
//    void	vertexAttribPointer( GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer );
//#if ! defined( CINDER_GL_ES_2 )
//    //! Analogous to glVertexAttribIPointer
//    void	vertexAttribIPointer( GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer );
//#endif // ! defined( CINDER_GL_ES )
//    //! Analogous to glEnableVertexAttribArray
//    void	enableVertexAttribArray( GLuint index );
//    
//    void		vertexAttrib1f( GLuint index, float v0 );
//    inline void	vertexAttrib( GLuint index, float v0 ) { vertexAttrib1f( index, v0 ); }
//    void		vertexAttrib2f( GLuint index, float v0, float v1 );
//    inline void	vertexAttrib( GLuint index, float v0, float v1 ) { vertexAttrib2f( index, v0, v1 ); }
//    void		vertexAttrib3f( GLuint index, float v0, float v1, float v2 );
//    inline void	vertexAttrib( GLuint index, float v0, float v1, float v2 ) { vertexAttrib3f( index, v0, v1, v2 ); }
//    inline void	vertexAttrib( GLuint index, float v0, float v1 );
//    void		vertexAttrib4f( GLuint index, float v0, float v1, float v2, float v3 );
//    inline void	vertexAttrib( GLuint index, float v0, float v1, float v2, float v3 ) { vertexAttrib4f( index, v0, v1, v2, v3 ); }
//    
//    // Buffers
//    void	bindBuffer( const BufferObjRef &buffer );
//    //! Binds a named buffer object \a buffer to \a target. Analogous to glBindBuffer().
//    void	bindBuffer( GLenum target, GLuint buffer );
//#if ! defined( CINDER_GL_ES_2 )
//    //! Specifies a color buffer as the source for subsequent glReadPixels(), glCopyTexImage2D(), glCopyTexSubImage2D(), and glCopyTexSubImage3D() commands. Analogous to glReadBuffer().
//    void	readBuffer( GLenum src );
//    //! Specifies an array of buffers into which fragment color values or fragment data will be written for subsequent draw calls. Analogous to glDrawBuffers().
//    void	drawBuffers( GLsizei num, const GLenum *bufs );
//    //! Specifies a color buffer as the destination for subsequent draw calls. Analogous to glDrawBuffer(), and emulated on ES 3
//    void	drawBuffer( GLenum dst );
//#endif
//    
//    //! Reads a block of pixels from the framebuffer. Analogous to glReadPixels().
//    void	readPixels( GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *data );
//    
//    // Compute
//#if defined( CINDER_MSW ) && ! defined( CINDER_GL_ANGLE )
//    //! Launches one or more compute work groups. Analogous to glDispatchCompute(). 
//    inline void	dispatchCompute( GLuint numGroupsX, GLuint numGroupsY, GLuint numGroupsZ ) { glDispatchCompute( numGroupsX, numGroupsY, numGroupsZ ); }
//    //! Defines a barrier ordering memory transactions. Analogous to glMemoryBarrier().
//    inline void	memoryBarrier( GLbitfield barriers ) { glMemoryBarrier( barriers ); }
//    
//    //! Returns ivec3( GL_MAX_COMPUTE_WORK_GROUP_COUNT )
//    ivec3	getMaxComputeWorkGroupCount();
//    //! Returns ivec3( GL_MAX_COMPUTE_WORK_GROUP_SIZE )
//    ivec3	getMaxComputeWorkGroupSize();
//#endif
    
    class Exception : public cinder::Exception {
        public:
        Exception()	{}
        Exception( const std::string &description ) : cinder::Exception( description )	{}
    };
    
    class ExceptionUnknownTarget : public Exception {
    };
    
} } // namespace cinder::gl

