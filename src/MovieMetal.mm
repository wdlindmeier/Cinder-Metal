//
//  MovieMetal.m
//  VideoMetalTexture
//
//  Created by William Lindmeier on 7/11/17.
//

#import "MovieMetal.h"
#ifdef CINDER_COCOA_TOUCH
#import <Foundation/Foundation.h>
#include "RendererMetalImpl.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#include "cinder/Log.h"

using namespace ci;
using namespace std;

static void *AVPlayerItemStatusContext = &AVPlayerItemStatusContext;

@interface MovieMetalImpl : NSObject <AVPlayerItemOutputPullDelegate>
{
    AVPlayerItemVideoOutput *_videoOutput;
    dispatch_queue_t _myVideoOutputQueue;
    id _notificationToken;
    CADisplayLink *_displayLink;
    CVMetalTextureCacheRef _videoTextureCache;
	BOOL _shouldLoop;
}

@property (nonatomic, readonly) ci::mtl::TextureBufferRef & textureLuma;
@property (nonatomic, readonly) ci::mtl::TextureBufferRef & textureChroma;
@property (nonatomic, readonly) AVPlayer *player;
@property (nonatomic, copy) void (^playbackCompleteHandler)(void);

@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation MovieMetalImpl

- (void)setupWithURL:(NSURL *)url options:( const mtl::MovieMetal::Options & )options
{
    assert(url != nil);

	_shouldLoop = options.getLoops();

    CVMetalTextureCacheCreate(NULL, NULL, [RendererMetalImpl sharedRenderer].device,
                              NULL, &_videoTextureCache);
    
    _player = [[AVPlayer alloc] init];
    [self setupPlaybackForURL:url];

    NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    _videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
    _videoOutput.suppressesPlayerRendering = YES;
    _myVideoOutputQueue = dispatch_queue_create("myVideoOutputQueue", DISPATCH_QUEUE_SERIAL);
    [_videoOutput setDelegate:self queue:_myVideoOutputQueue];
    
    [self addObserver:self
           forKeyPath:@"player.currentItem.status"
              options:NSKeyValueObservingOptionNew
              context:AVPlayerItemStatusContext];
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_displayLink setPaused:YES];
}

# define ONE_FRAME_DURATION 0.03

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender
{
    if ( _isPlaying )
    {
        [_displayLink setPaused:NO];
    }
}

- (void)setIsPlaying:(int)isPlaying
{
    _isPlaying = isPlaying;
	if ( _isPlaying )
	{
		[_player play];
	}
	else
	{
		[_player pause];
	}
    [_displayLink setPaused:!_isPlaying];
}

- (void)outputSequenceWasFlushed:(AVPlayerItemOutput *)output
{
    //NSLog(@"outputSequenceWasFlushed");
}

- (void)setupPlaybackForURL:(NSURL *)URL
{
    // Remove video output from old item, if any.
    [[_player currentItem] removeOutput:_videoOutput];
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:URL];
	AVAsset *asset = [item asset];
    
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^
    {
        if ( [asset statusOfValueForKey:@"tracks" error:nil] == AVKeyValueStatusLoaded )
        {
            NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if ([tracks count] > 0)
			{
                // Choose the first video track.
                AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
                [videoTrack loadValuesAsynchronouslyForKeys:@[@"preferredTransform"] completionHandler:^
                {
                    if ( [videoTrack statusOfValueForKey:@"preferredTransform" error:nil] == AVKeyValueStatusLoaded )
                    {
                        [self addDidPlayToEndTimeNotificationForPlayerItem:item];
                        
                        dispatch_async(dispatch_get_main_queue(), ^
                        {
                            [item addOutput:_videoOutput];
                            [_player replaceCurrentItemWithPlayerItem:item];
                            [_videoOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:ONE_FRAME_DURATION];
                        });
                    }
                }];
            }
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVPlayerItemStatusContext)
    {
        AVPlayerStatus status = (AVPlayerStatus)[change[NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerItemStatusUnknown:
                CI_LOG_I(@"STATUS UNKNOWN");
                break;
            case AVPlayerItemStatusReadyToPlay:
                CI_LOG_I(@"READY TO PLAY");
                break;
            case AVPlayerItemStatusFailed:
                CI_LOG_E(@"LOAD FAILED");
                break;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)addDidPlayToEndTimeNotificationForPlayerItem:(AVPlayerItem *)item
{
    if (_notificationToken)
    {
        _notificationToken = nil;
    }
     // Setting actionAtItemEnd to None prevents the movie from getting paused at item end. A very simplistic, and not gapless, looped playback.
    _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
	_notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
																		   object:item
																			queue:[NSOperationQueue mainQueue]
																	   usingBlock:^(NSNotification *note)
	{
		// Simple item playback rewind.
		if ( _shouldLoop )
		{
			[[_player currentItem] seekToTime:kCMTimeZero];
		}
		if ( self.playbackCompleteHandler )
		{
			self.playbackCompleteHandler();
		}
	}];
}

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    CMTime outputItemTime = kCMTimeInvalid;
    
    // Calculate the nextVsync time which is when the screen will be refreshed next.
    CFTimeInterval nextVSync = ([sender timestamp] + [sender duration]);
    
    outputItemTime = [_videoOutput itemTimeForHostTime:nextVSync];
    
    if ( [_videoOutput hasNewPixelBufferForItemTime:outputItemTime] )
    {
        CVPixelBufferRef pixelBuffer = NULL;
        pixelBuffer = [_videoOutput copyPixelBufferForItemTime:outputItemTime itemTimeForDisplay:NULL];
        
        if ( CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 )
        {
            [self createOrUpdateTextureFromPixelBuffer:_textureLuma
                                           pixelBuffer:pixelBuffer
                                              pxFormat:mtl::PixelFormatR8Unorm
                                            planeIndex:0];
            
            [self createOrUpdateTextureFromPixelBuffer:_textureChroma
                                           pixelBuffer:pixelBuffer
                                              pxFormat:mtl::PixelFormatRG8Unorm
                                            planeIndex:1];
        }
        else
        {
            NSLog(@"ERROR: Pixel Buffer has < 2 planes");
        }
        
        if (pixelBuffer != NULL)
        {
            CFRelease(pixelBuffer);
        }
    }
}

- (void)createOrUpdateTextureFromPixelBuffer:(mtl::TextureBufferRef &) texture
                                 pixelBuffer:(CVPixelBufferRef)pixelBuffer
                                    pxFormat:(mtl::PixelFormat)pxFormat
                                  planeIndex:(NSInteger)planeIndex
{
    id <MTLTexture> nativeTex = [self createTextureFromPixelBuffer:pixelBuffer
                                                            format:(MTLPixelFormat)pxFormat
                                                        planeIndex:planeIndex];
    if ( texture )
    {
        texture->update((__bridge void *)nativeTex);
    }
    else
    {
        texture = mtl::TextureBuffer::create((__bridge void *)nativeTex);
    }
}

- (id <MTLTexture>)createTextureFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
                                         format:(MTLPixelFormat)pixelFormat
                                     planeIndex:(NSInteger)planeIndex
{
    id<MTLTexture> mtlTexture = nil;
    const size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex);
    const size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex);
    CVMetalTextureRef texture = NULL;
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, _videoTextureCache,
                                                                pixelBuffer, NULL, pixelFormat, width, height,
                                                                planeIndex, &texture);
    if( status == kCVReturnSuccess )
    {
        mtlTexture = CVMetalTextureGetTexture(texture);
        CFRelease(texture);
    }
    return mtlTexture;
}

@end

mtl::MovieMetal::MovieMetal( const fs::path & movieURL, Options options )
:
mOptions(options)
,mLoops(false)
{
    mVideoDelegate = [MovieMetalImpl new];
    [mVideoDelegate setupWithURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:movieURL.c_str()]]
						 options:mOptions];
	mVideoDelegate.playbackCompleteHandler = ^{
		if ( mPlaybackCompleteHandler ) mPlaybackCompleteHandler(this);
	};
}

void mtl::MovieMetal::play( bool seekToZero )
{
	if ( seekToZero )
	{
		seekToTime(0);
	}
    mVideoDelegate.isPlaying = YES;
}

void mtl::MovieMetal::pause()
{
    mVideoDelegate.isPlaying = NO;
}

void mtl::MovieMetal::setRate(float rate)
{
    mVideoDelegate.player.rate = rate;
}

void mtl::MovieMetal::seekToTime(double secondsOffset)
{
    [[mVideoDelegate.player currentItem] seekToTime:CMTimeMakeWithSeconds(secondsOffset, 60) // eh? CMTimeMake(60*secondsOffset, 60) // eh?
                                  completionHandler:nil];
}

double mtl::MovieMetal::getDuration()
{
    return CMTimeGetSeconds([[mVideoDelegate.player currentItem] duration]);
}

float mtl::MovieMetal::getRate()
{
    return mVideoDelegate.player.rate;
}

mtl::TextureBufferRef & mtl::MovieMetal::getTextureLuma()
{
    return mVideoDelegate.textureLuma;
}

mtl::TextureBufferRef & mtl::MovieMetal::getTextureChroma()
{
    return mVideoDelegate.textureChroma;
}
#endif

