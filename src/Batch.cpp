//
//  Batch.cpp
//  Batch
//
//  Created by William Lindmeier on 1/10/16.
//
//

#include "Batch.h"
#include "cinder/Log.h"
#include "Context.h"

using namespace cinder;
using namespace cinder::mtl;

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
        // And plural for attribute buffers
        sDefaultAttribNameToSemanticMap["ciPositions"] = ci::geom::Attrib::POSITION;
        sDefaultAttribNameToSemanticMap["ciNormals"] = ci::geom::Attrib::NORMAL;
        sDefaultAttribNameToSemanticMap["ciTangents"] = ci::geom::Attrib::TANGENT;
        sDefaultAttribNameToSemanticMap["ciBitangents"] = ci::geom::Attrib::BITANGENT;
        sDefaultAttribNameToSemanticMap["ciTexCoords0"] = ci::geom::Attrib::TEX_COORD_0;
        sDefaultAttribNameToSemanticMap["ciTexCoords1"] = ci::geom::Attrib::TEX_COORD_1;
        sDefaultAttribNameToSemanticMap["ciTexCoords2"] = ci::geom::Attrib::TEX_COORD_2;
        sDefaultAttribNameToSemanticMap["ciTexCoords3"] = ci::geom::Attrib::TEX_COORD_3;
        sDefaultAttribNameToSemanticMap["ciColors"] = ci::geom::Attrib::COLOR;
        sDefaultAttribNameToSemanticMap["ciBoneIndices"] = ci::geom::Attrib::BONE_INDEX;
        sDefaultAttribNameToSemanticMap["ciBoneWeights"] = ci::geom::Attrib::BONE_WEIGHT;
        initialized = true;
    }
    
    return sDefaultAttribNameToSemanticMap;
}

Batch::Batch( const VertexBufferRef &vertexBuffer,
              const RenderPipelineStateRef & pipeline,
              const AttributeMapping &attributeMapping )
:
mRenderPipeline(pipeline),
mVertexBuffer(vertexBuffer)
{
    // NOTE: We're not really generating or formatting any vert data here,
    // just checking that the shader and the VertBuffer are in agreement.
    initBufferLayout( attributeMapping );
    checkBufferLayout();
}

Batch::Batch( const ci::geom::Source &source,
              const RenderPipelineStateRef &pipeline,
              const AttributeMapping &attributeMapping )
: mRenderPipeline(pipeline)
{
    initBufferLayout( attributeMapping );
    mVertexBuffer = mtl::VertexBuffer::create( source, mInterleavedAttribs );
    checkBufferLayout();
}

void Batch::initBufferLayout( const AttributeMapping &attributeMapping )
{
    std::map<std::string, ci::geom::Attrib> inverseMapping;
    
    for ( auto kvp : attributeMapping )
    {
        inverseMapping[kvp.second] = kvp.first;
    }
    
    std::vector<ci::geom::Attrib> interleavedAttribs;
    std::map<ci::geom::Attrib, int> attribBufferIndices;

    AttribSemanticMap & defaultAttribMap = getDefaultAttribNameToSemanticMap();
    
    // and then the attributes references by the Pipeline
    for( ci::mtl::Argument argument : mRenderPipeline->getVertexArguments() )
    {
        mtl::ArgumentType aType = argument.getType();
        if ( aType == mtl::ArgumentTypeBuffer )
        {
            std::string argName = argument.getName();
            
            if ( argName == "ciVerts" )
            {
                mtl::DataType t = argument.getBufferDataType();
                if ( t == mtl::DataTypeStruct )
                {
                    mtl::StructType s = argument.getBufferStructType();
                    for ( const mtl::StructMember m : s.members )
                    {
                        std::string attrName = m.name;
                        // NOTE: Check inverseMapping first so it trumps the default.
                        if ( inverseMapping.count( attrName ) != 0 )
                        {
                            ci::geom::Attrib a = inverseMapping[attrName];
                            interleavedAttribs.push_back(a);
                        }
                        else if ( defaultAttribMap.count( attrName ) != 0 )
                        {
                            ci::geom::Attrib a = defaultAttribMap[attrName];
                            interleavedAttribs.push_back(a);
                        }
                        else
                        {
                            CI_LOG_E( "Don't know how to handle attrib: " << attrName << ". Ignoring");
                        }
                    }
                }
                else
                {
                    CI_LOG_E( "ciVerts must be defined as a struct" );
                    assert(false);
                }
            }
            else
            {
                // Check if we know the name
                // NOTE: Check inverseMapping first so it trumps the default.
                if ( inverseMapping.count( argName ) != 0 )
                {
                    ci::geom::Attrib a = inverseMapping[argName];
                    mAttribBufferIndices[a] = argument.getIndex();
                }
                else if ( defaultAttribMap.count( argName ) != 0 )
                {
                    ci::geom::Attrib a = defaultAttribMap[argName];
                    mAttribBufferIndices[a] = argument.getIndex();
                }
//                else
//                {
//                    CI_LOG_E( "Don't know what to do attrib: " << argName << ". Ignoring" );
//                }
            }
        }
    }

    mInterleavedAttribs = interleavedAttribs;
    mAttribBufferIndices = attribBufferIndices;
    mAttribMapping = attributeMapping;
}

void Batch::checkBufferLayout()
{
    if ( mAttribBufferIndices.size() > 0 )
    {
        // The shader wants attribute buffers.
        // Make sure that's the format of the VertexBuffer.
        assert( !mVertexBuffer->getIsInterleaved() );
        
        // Update the buffer indices to match the shader.
        // One might argue this is bad form...
        for ( auto attrWithIndex : mAttribBufferIndices )
        {
            // Make sure the buffer exists.
            assert( mVertexBuffer->getBufferForAttribute(attrWithIndex.first) );
            // Set the correct shader buffer index
            int attrIndex = mVertexBuffer->getAttributeShaderIndex(attrWithIndex.first);
            if ( attrIndex == -1 )
            {
                // Should this be a negative assertion?
                mVertexBuffer->setAttributeShaderIndex(attrWithIndex.first,
                                                       attrWithIndex.second);
            }
            else
            {
                if ( attrIndex != attrWithIndex.second )
                {
                    CI_LOG_E( "VertexBuffer and Pipeline disagree on attribute buffer index. VertexBuffer index: "
                              << attrIndex << " Pipeline index: " << attrWithIndex.second );
                    assert( false );
                }
            }
        }
    }
    else if ( mInterleavedAttribs.size() > 0 )
    {
        // The shader wants interleaved data.
        // Make sure that's the format of the VertexBuffer.
        assert( mVertexBuffer->getIsInterleaved() );
        
        // ...
        // Assume the data format is correct
    }
}

void Batch::replacePipeline( const RenderPipelineStateRef& pipeline )
{
    mRenderPipeline = pipeline;
    initBufferLayout( mAttribMapping );
}

void Batch::replaceVertexBuffer(const VertexBufferRef &vertexBuffer)
{
    mVertexBuffer = vertexBuffer;
    initBufferLayout( mAttribMapping );
}

void Batch::draw( RenderEncoder & renderEncoder )
{
    setDefaultShaderVars(renderEncoder, mRenderPipeline);
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->draw(renderEncoder);
}

void Batch::drawInstanced( RenderEncoder & renderEncoder, size_t instanceCount )
{
    setDefaultShaderVars(renderEncoder, mRenderPipeline);
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->drawInstanced(renderEncoder, instanceCount);
}

void Batch::draw( RenderEncoder & renderEncoder,
                  size_t vertexStart,
                  size_t vertexLength,
                  size_t instanceCount )
{
    setDefaultShaderVars(renderEncoder, mRenderPipeline);
    renderEncoder.setPipelineState(mRenderPipeline);
    mVertexBuffer->draw(renderEncoder, vertexLength, vertexStart, instanceCount);
}

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