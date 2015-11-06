//
//  MetalHelpers.hpp
//  MetalCube
//
//  Created by William Lindmeier on 11/4/15.
//
//

#pragma once

#define FORMAT_OPTION(NAME, CAP_NAME, TYPE) \
    protected: \
        TYPE m##CAP_NAME; \
    public: \
        Format& NAME( TYPE NAME ) { set##CAP_NAME( NAME ); return *this; }; \
        void set##CAP_NAME( TYPE NAME ) { m##CAP_NAME = NAME; }; \
        TYPE get##CAP_NAME() { return m##CAP_NAME; }; \
