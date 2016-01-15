//
//  Batch.cpp
//  Batch
//
//  Created by William Lindmeier on 1/10/16.
//
//

#include "Batch.h"
#include "cinder/Log.h"

using namespace cinder;
using namespace cinder::mtl;

//typedef std::map<std::string,ci::mtl::UniformSemantic>	UniformSemanticMap;
typedef std::map<std::string,ci::geom::Attrib>	AttribSemanticMap;

static AttribSemanticMap sDefaultAttribNameToSemanticMap;

static AttribSemanticMap & getDefaultAttribNameToSemanticMap()
{
    static bool initialized = false;
    if( !initialized )
    {
        sDefaultAttribNameToSemanticMap["ciPosition"] = ci::geom::Attrib::POSITION;
        sDefaultAttribNameToSemanticMap["ciNormal"] = ci::geom::Attrib::NORMAL;
        sDefaultAttribNameToSemanticMap["ciTangent"] = ci::geom::Attrib::TANGENT;
        sDefaultAttribNameToSemanticMap["ciBitangent"] = ci::geom::Attrib::BITANGENT;
        sDefaultAttribNameToSemanticMap["ciTexCoord0"] = ci::geom::Attrib::TEX_COORD_0;
        sDefaultAttribNameToSemanticMap["ciTexCoord1"] = ci::geom::Attrib::TEX_COORD_1;
        sDefaultAttribNameToSemanticMap["ciTexCoord2"] = ci::geom::Attrib::TEX_COORD_2;
        sDefaultAttribNameToSemanticMap["ciTexCoord3"] = ci::geom::Attrib::TEX_COORD_3;
        sDefaultAttribNameToSemanticMap["ciColor"] = ci::geom::Attrib::COLOR;
        sDefaultAttribNameToSemanticMap["ciBoneIndex"] = ci::geom::Attrib::BONE_INDEX;
        sDefaultAttribNameToSemanticMap["ciBoneWeight"] = ci::geom::Attrib::BONE_WEIGHT;
        initialized = true;
    }
    
    return sDefaultAttribNameToSemanticMap;
}

// TODO
Batch::Batch( const VertexBufferRef &vertexBuffer,
              const RenderPipelineStateRef & pipeline,
              const AttributeMapping &attributeMapping )
:
mRenderPipeline(pipeline),
mVertexBuffer(vertexBuffer)
{
//    TODO: How do we add pipeline attrs to the vertexBuffer?
//    attrs = mRenderPipeline->getActiveAttributes();
//    mVertexBuffer -> addattrs(attrs)
    
    // TODO: Add attributes to the buffer
    // this may require that we re-create it

    // I guess we just assume that the attribute mapping is correct...
    initBufferLayout( attributeMapping );
}

Batch::Batch( const ci::geom::Source &source,
              const RenderPipelineStateRef &pipeline,
              const AttributeMapping &attributeMapping )
: mRenderPipeline(pipeline)
{
    initBufferLayout( attributeMapping );
    
    // TODO: Can we get / set the attributes by name?
    mVertexBuffer = mtl::VertexBuffer::create( source, mOrderedAttribs );
    //mVboMesh = gl::VboMesh::create( source, attribs );
}

void Batch::initBufferLayout( const AttributeMapping &attributeMapping )
{
    std::map<std::string, ci::geom::Attrib> inverseMapping;
    
    for ( auto kvp : attributeMapping )
    {
        inverseMapping[kvp.second] = kvp.first;
    }
    
    std::vector<ci::geom::Attrib> orderedAttribs;
    
    AttribSemanticMap & defaultAttribMap = getDefaultAttribNameToSemanticMap();
    
    // and then the attributes references by the GLSL
    for( ci::mtl::Argument argument : mRenderPipeline->getVertexArguments() )
    {
        mtl::ArgumentType aType = argument.getType();
        if ( aType == mtl::ArgumentTypeBuffer )
        {
            mtl::DataType t = argument.getBufferDataType();
            //            CI_LOG_I("vertex argument " << argument.getName() << " has type " << t);
            if ( t == mtl::DataTypeStruct )
            {
                // NOTE: The struct data must be at ciBufferIndexInterleavedVerts
                // or be named ciVerts and the member names must be known for this to work.
                if ( argument.getIndex() == ciBufferIndexInterleavedVerts ||
                     argument.getName() == "ciVerts" )
                {
                    mtl::StructType s = argument.getBufferStructType();
                    //                CI_LOG_I("struct with " << s.members.size() << " members");
                    //orderedAttribs.assign( s.members.size(), ci::geom::NUM_ATTRIBS );
                    for ( const mtl::StructMember m : s.members )
                    {
                        std::string attrName = m.name;
                        //int index = stoi(memberByName.first);
                        
                        if ( inverseMapping.count( attrName ) != 0 )
                        {
                            ci::geom::Attrib a = inverseMapping[attrName];
                            //attribs.insert( a );
//                            orderedAttribs.push_back(a);
                            orderedAttribs.push_back(a);
                        }
                        else if ( defaultAttribMap.count( attrName ) != 0 )
                        {
//                        TODO: Use the key for the order rather than the implicit order
                            ci::geom::Attrib a = defaultAttribMap[attrName];
                            //attribs.insert( a );
//                            orderedAttribs.push_back(a);
//                            orderedAttribs[index] = a;
                            orderedAttribs.push_back(a);
                        }
                        else
                        {
                            CI_LOG_E( "Don't know how to handle attrib: " << attrName );
                            //assert(false);
                        }
                    }
                }
                else
                {
                    CI_LOG_I( "Ignoring struct named: " << argument.getName() << " at index " <<  argument.getIndex() );
                }
            }
        }
    }
    
    if ( orderedAttribs.size() == 0 )
    {
        // If there are no attributes, add position
        // orderedAttribs.push_back(ci::geom::POSITION);
        CI_LOG_I("ERROR: No attriutes found in shader.");
        assert(false);
    }
    
    mOrderedAttribs = orderedAttribs;
    mAttribMapping = attributeMapping;
}

//void Batch::replaceGlslProg( const GlslProgRef& glsl )
void Batch::replacePipeline( const RenderPipelineStateRef& pipeline )
{
    //mGlsl = glsl;
    mRenderPipeline = pipeline;
    initBufferLayout( mAttribMapping );
}

void Batch::replaceVertexBuffer(const VertexBufferRef &vertexBuffer)
{
    CI_LOG_E("TODO: remap an existing buffer");
    assert(false);
    
    mVertexBuffer = vertexBuffer;
//    mVboMesh = vboMesh;
//    initVao( mAttribMapping );
    initBufferLayout( mAttribMapping );
}

//void Batch::draw( GLint first, GLsizei count )
//{
//    auto ctx = gl::context();
//    
//    gl::ScopedGlslProg ScopedGlslProg( mGlsl );
//    gl::ScopedVao ScopedVao( mVao );
//    ctx->setDefaultShaderVars();
//    mVboMesh->drawImpl( first, count );
//}
//
//#if defined( CINDER_GL_HAS_DRAW_INSTANCED )
//
//void Batch::drawInstanced( GLsizei instanceCount )
//{
//    auto ctx = gl::context();
//    
//    gl::ScopedGlslProg ScopedGlslProg( mGlsl );
//    gl::ScopedVao ScopedVao( mVao );
//    ctx->setDefaultShaderVars();
//    mVboMesh->drawInstancedImpl( instanceCount );
//}

void Batch::draw( RenderEncoder & renderEncoder )
{
    // Not sure this makes sense yet
//    setDefaultShaderVars();
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->draw(renderEncoder);
}

void Batch::drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount )
{
    // Not sure this makes sense yet
//    setDefaultShaderVars();
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->drawInstanced(renderEncoder, instanceCount);
}

void Batch::draw( RenderEncoder & renderEncoder,
                  size_t vertexStart,
                  size_t vertexLength,
                  size_t instanceCount )
{
    // Not sure this makes sense yet
//    setDefaultShaderVars();
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->draw(renderEncoder, vertexLength, vertexStart, instanceCount);
}

//#endif // defined( CINDER_GL_HAS_DRAW_INSTANCED )
//
//void Batch::bind()
//{
//    mGlsl->bind();
//    mVao->bind();
//}
//
//void Batch::reassignContext( Context *context )
//{
//    mVao->reassignContext( context );
//}