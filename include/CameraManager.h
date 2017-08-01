//
//  CameraManager.h
//  MetalCamSlices
//
//  Created by William Lindmeier on 2/10/17.
//
//

#include "cinder/cinder.h"
#include "metal.h"
#ifdef CINDER_COCOA_TOUCH
typedef void (^PixelBufferCallback)(CVPixelBufferRef pxBuffer);

class CameraManager
{
    
public:
    
    struct Options
    {
        int targetFramerate;
        int targetWidth;
        int targetHeight;
        bool isFrontFacing;
        bool useCinematicStabilization;
        int mipMapLevel;

        Options() :
        targetFramerate(60)
        ,targetWidth(640)
        ,targetHeight(480)
        ,isFrontFacing(false)
        ,mipMapLevel(1)
        ,useCinematicStabilization(false)
        {}
    };
    
    CameraManager( Options options = Options() );
    
    bool hasTexture();
	cinder::mtl::TextureBufferRef & getTexture( const int inflightBufferIndex = -1 );
	double getTimeLastFrame(); // Comes from a CFAbsoluteTime

    void startCapture();
    void stopCapture();
    bool isCapturing();
    bool isFrontFacing(){ return mOptions.isFrontFacing; }
    // restartWithOptions is good for toggling between front and back cameras with different resolutions, etc
    void restartWithOptions( const Options & options );
    void lockConfiguration( bool isExposureLocked = true, bool isWhiteBalanceLocked = true, bool isFocusLocked = true );
    void unlockConfiguration( bool isExposureUnlocked = true, bool isWhiteBalanceUnlocked = true, bool isFocusUnlocked = true );

	void setPixelBufferCallback( const PixelBufferCallback & pxBufferCallback );

protected:

    void init();
    void *mImpl;
    bool mIsCapturing;
    Options mOptions;

};
#endif
