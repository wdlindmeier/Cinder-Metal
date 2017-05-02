//
//  Library.h
//
//  Created by William Lindmeier on 1/13/16.
//
//

#pragma once

#include "cinder/Cinder.h"
#include "MetalHelpers.hpp"
#include "MetalEnums.h"

namespace cinder { namespace mtl {
    
    typedef std::shared_ptr<class Library> LibraryRef;

    class Library
    {
        
    public:
        
//        static Library::create( void * mtlLibrary )
//        {};
//        static Library::create( const std::string & libraryName )
//        {};
//        
    protected:
        
        void *mImpl; // <MTLLibrary>
        
    };
}}