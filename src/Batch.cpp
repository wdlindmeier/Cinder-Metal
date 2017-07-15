//
//  Batch.cpp
//
//  Created by William Lindmeier on 1/10/16.
//
//

#include "Batch.h"
#include "cinder/app/App.h"
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

const static uint DimensionsForAttributeOfType( mtl::DataType type, size_t *size )
{
    switch (type)
    {
        case DataTypeFloat:
        case DataTypeFloat2:
        case DataTypeFloat3:
        case DataTypeFloat4:
        case DataTypeFloat2x2:
        case DataTypeFloat2x3:
        case DataTypeFloat2x4:
        case DataTypeFloat3x2:
        case DataTypeFloat3x3:
        case DataTypeFloat3x4:
        case DataTypeFloat4x2:
        case DataTypeFloat4x3:
        case DataTypeFloat4x4:
            *size = sizeof(float);
            break;
        case DataTypeHalf:
        case DataTypeHalf2:
        case DataTypeHalf3:
        case DataTypeHalf4:
        case DataTypeHalf2x2:
        case DataTypeHalf2x3:
        case DataTypeHalf2x4:
        case DataTypeHalf3x2:
        case DataTypeHalf3x3:
        case DataTypeHalf3x4:
        case DataTypeHalf4x2:
        case DataTypeHalf4x3:
        case DataTypeHalf4x4:
            *size = sizeof(half_float);
            break;
        case DataTypeInt:
        case DataTypeInt2:
        case DataTypeInt3:
        case DataTypeInt4:
            *size = sizeof(int);
            break;
        case DataTypeUInt:
        case DataTypeUInt2:
        case DataTypeUInt3:
        case DataTypeUInt4:
            *size = sizeof(uint);
            break;
        case DataTypeShort:
        case DataTypeShort2:
        case DataTypeShort3:
        case DataTypeShort4:
            *size = sizeof(short);
            break;
        case DataTypeUShort:
        case DataTypeUShort2:
        case DataTypeUShort3:
        case DataTypeUShort4:
            *size = sizeof(ushort);
            break;
        case DataTypeChar:
        case DataTypeChar2:
        case DataTypeChar3:
        case DataTypeChar4:
            *size = sizeof(char);
            break;
        case DataTypeUChar:
        case DataTypeUChar2:
        case DataTypeUChar3:
        case DataTypeUChar4:
            *size = sizeof(u_char);
            break;
        case DataTypeBool:
        case DataTypeBool2:
        case DataTypeBool3:
        case DataTypeBool4:
            *size = sizeof(bool);
            break;
        default:
            assert(false);
            CI_LOG_F("ERROR: Unsopported data type in ciVerts");
            break;
    }
    
    switch (type)
    {
        case DataTypeFloat:
        case DataTypeHalf:
        case DataTypeInt:
        case DataTypeUInt:
        case DataTypeShort:
        case DataTypeUShort:
        case DataTypeChar:
        case DataTypeUChar:
        case DataTypeBool:
            return 1;
        case DataTypeFloat2:
        case DataTypeHalf2:
        case DataTypeInt2:
        case DataTypeUInt2:
        case DataTypeShort2:
        case DataTypeUShort2:
        case DataTypeChar2:
        case DataTypeUChar2:
        case DataTypeBool2:
            return 2;
            break;
        case DataTypeFloat3:
        case DataTypeHalf3:
        case DataTypeInt3:
        case DataTypeUInt3:
        case DataTypeShort3:
        case DataTypeUShort3:
        case DataTypeChar3:
        case DataTypeUChar3:
        case DataTypeBool3:
            return 3;
            break;
        case DataTypeFloat4:
        case DataTypeHalf4:
        case DataTypeInt4:
        case DataTypeUInt4:
        case DataTypeShort4:
        case DataTypeUShort4:
        case DataTypeChar4:
        case DataTypeUChar4:
        case DataTypeBool4:
            return 4;
            break;
        case DataTypeFloat2x3:
        case DataTypeHalf2x3:
            return 6;
            break;
        case DataTypeFloat2x4:
        case DataTypeHalf2x4:
            return 8;
            break;
        case DataTypeFloat3x3:
        case DataTypeHalf3x3:
            return 9;
            break;
        case DataTypeFloat3x4:
        case DataTypeHalf3x4:
        case DataTypeFloat4x3:
        case DataTypeHalf4x3:
            return 12;
            break;
        case DataTypeFloat4x4:
        case DataTypeHalf4x4:
            return 16;
            break;
        default:
            assert(false);
            CI_LOG_F("ERROR: Unsopported data type in ciVerts");
            break;
    }
    return 0;
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
    mVertexBuffer = mtl::VertexBuffer::create( source, mInterleavedLayout );
//    mVertexBuffer->setIndicesBufferIndex(mIndicesBufferIndex);
    checkBufferLayout();
}

void Batch::initBufferLayout( const AttributeMapping &attributeMapping )
{
    std::map<std::string, ci::geom::Attrib> inverseMapping;
    
    for ( auto kvp : attributeMapping )
    {
        inverseMapping[kvp.second] = kvp.first;
    }
    
    ci::geom::BufferLayout interleavedLayout;

    std::map<ci::geom::Attrib, unsigned long> attribBufferIndices;

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
                    
                    // First calculate the stride
                    size_t stride = 0;
                    for ( const mtl::StructMember m : s.members )
                    {
                        std::string attrName = m.name;
                        size_t sizeOfComponent;
                        uint dimensions = DimensionsForAttributeOfType(m.dataType, &sizeOfComponent);
                        stride += dimensions * sizeOfComponent;
                    }
                    
                    // Then build the layout.
                    size_t offset = 0;
                    for ( const mtl::StructMember m : s.members )
                    {
                        std::string attrName = m.name;
                        assert(defaultAttribMap.count(attrName));
                        ci::geom::Attrib attrib;
                        // Check the custom mapping first before the defaults.
                        if ( inverseMapping.count( attrName ) )
                        {
                            attrib = inverseMapping[attrName];
                        }
                        else if ( defaultAttribMap.count( attrName ) )
                        {
                            attrib = defaultAttribMap[attrName];
                        }
                        else
                        {
                            ci::app::console() << "Unknown attribute name: " << attrName << std::endl;
                            assert(false);
                            return;
                        }
                        size_t sizeOfComponent;
                        uint dimensions = DimensionsForAttributeOfType(m.dataType, &sizeOfComponent);
                        interleavedLayout.append(attrib, dimensions, stride, offset);
                        offset += dimensions * sizeOfComponent;
                    }
                    assert(offset == stride);
                }
                else
                {
                    CI_LOG_E( "ciVerts must be defined as a struct." );
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

    mInterleavedLayout = interleavedLayout;
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
            unsigned long attrIndex = mVertexBuffer->getAttributeBufferIndex(attrWithIndex.first);
            if ( attrIndex == -1 )
            {
                // Should this be a negative assertion?
                mVertexBuffer->setAttributeBufferIndex(attrWithIndex.first,
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
    else if ( mInterleavedLayout.getAttribs().size() > 0 )
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
