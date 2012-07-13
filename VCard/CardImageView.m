//
//  CardImageView.m
//  VCard
//
//  Created by 海山 叶 on 12-4-14.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "CardImageView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+URL.h"
#import "UIView+Resize.h"
#import "UIApplication+Addition.h"
#import "UIImage+animatedImageWithGIF.h"

@implementation CardImageView

@synthesize imageView = _imageView;
@synthesize gifIcon = _gifIcon;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _shadowView = [[CardImageViewShadowView alloc] initWithFrame:frame];
        [self insertSubview:_shadowView atIndex:0];
        self.imageView.layer.edgeAntialiasingMask = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self insertSubview:self.imageView atIndex:1];
        self.clearsContextBeforeDrawing = YES;
        self.imageView.layer.edgeAntialiasingMask = 0;
    }
    return self;
}

- (void)resetHeight:(CGFloat)height
{
    CGRect frame = CGRectMake(-4.0, 13.0, StatusImageWidth, height);
    self.transform = CGAffineTransformMakeRotation(0);
    self.frame = frame;
    
    frame.origin = CGPointMake(0.0, 0.0);
    self.imageView.frame = frame;
    
    _initialSize = self.imageView.frame.size;
    _initialFrame = self.layer.frame;
    
    [self.coverView resetOriginX:frame.origin.x - 5.0];
    [self.coverView resetOriginY:frame.origin.y - 4.0];
    [self.coverView resetWidth:frame.size.width + 10.0];
    [self.coverView resetHeight:frame.size.height + 10.0];
    
    CGFloat rotatingDegree = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * 4) - 2;
    _initialRotation = rotatingDegree * M_PI / 180;
    self.transform = CGAffineTransformMakeRotation(_initialRotation);
    
    _initialPosition = self.frame.origin;
}

- (void)pinchResizeToScale:(CGFloat)scale
{
    scale -= 1.0;
    if (scale >= 0.5) {
        scale = 0.5;
    }
    if (scale > 0.0) {
        scale /= 0.5;
        if (_deltaWidth != 0.0) {
            [self.imageView resetWidth:_initialSize.width + scale * _deltaWidth];
            [self.coverView resetWidth:self.imageView.frame.size.width + 10.0];
        } else {
            [self.imageView resetHeight:_initialSize.height + scale * _deltaHeight];
            [self.coverView resetHeight:self.imageView.frame.size.height + 10.0];
        }
    }
}

- (void)resetCurrentScale
{
    _currentScale = sqrt(self.transform.a * self.transform.a + self.transform.c * self.transform.c);
    _initialScale = _currentScale;
}

- (CGFloat)scaleOffset
{
    CGFloat offset = _currentScale - _initialScale;
    return offset;
}

- (void)playReturnAnimation
{
    if (_isGIF) {
        self.imageView.image = _staticGIFImage;
    }
    
    self.transform = CGAffineTransformIdentity;
    [self.imageView resetSize:_initialSize];
    [self.coverView resetSize:CGSizeMake(_initialSize.width + 10.0, _initialSize.height + 10.0)];
}

- (void)returnToInitialPosition
{
    [self resetSize:_initialSize];
    [self resetOrigin:_initialPosition];
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformMakeRotation(_initialRotation);
    }];
}

- (void)loadImageFromURL:(NSString *)urlString 
              completion:(void (^)())completion
{
    _loadingCompleted = NO;
    [self setUpGifIcon:urlString];
    [self.imageView kv_cancelImageDownload];
    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        gestureRecognizer.enabled = NO;
    }
    
    NSURL *url = [NSURL URLWithString:urlString];
    void (^imageLoadingCompletion)(BOOL succeeded) = ^(BOOL succeeded){
        CGFloat targetWidth = self.imageView.frame.size.width;
        CGFloat targetHeight = self.imageView.frame.size.height;
        CGFloat width = self.imageView.image.size.width;
        CGFloat height = self.imageView.image.size.height;
        
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        CGFloat scaleFactor = 0.0;
        
        CGFloat scaledWidth = 0.0;
        CGFloat scaledHeight = 0.0;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        _deltaWidth = scaledWidth - targetWidth;
        _deltaHeight = scaledHeight - targetHeight;
        
        widthFactor = 1024.0 / scaledWidth;
        heightFactor = 768.0 / scaledHeight;
        
        if (widthFactor > heightFactor)
            _targetHorizontalScale = heightFactor; // scale to fit height
        else
            _targetHorizontalScale = widthFactor; // scale to fit width
        
        widthFactor = 768.0 / scaledWidth;
        heightFactor = 1024.0 / scaledHeight;
        
        if (widthFactor > heightFactor)
            _targetVerticalScale = heightFactor; // scale to fit height
        else
            _targetVerticalScale = widthFactor; // scale to fit width
        
        _loadingCompleted = YES;
        if (succeeded) {
            for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
                gestureRecognizer.enabled = YES;
            }
        }
    };
    
    [self.imageView kv_setImageAtURL:url completion:imageLoadingCompletion];
}

- (void)loadDetailedImageFromURL:(NSString *)urlString
                      completion:(void (^)())completion
{
    if (_isGIF) {
        _staticGIFImage = self.imageView.image;
        urlString = [urlString stringByReplacingOccurrencesOfString:@"jpg" withString:@"gif"];
        urlString = [urlString stringByReplacingOccurrencesOfString:@"large" withString:@"bmiddle"];
        NSURL *url = [NSURL URLWithString:urlString];
        
        dispatch_queue_t downloadQueue = dispatch_queue_create("downloadQueue", NULL);
        
        dispatch_async(downloadQueue, ^{
                        
            NSData *imageData = [NSData dataWithContentsOfURL:url];
            UIImage *image = [UIImage animatedImageWithGIFData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.imageView.image = image;
                if (completion) {
                    completion();
                }
            });
            
        });
        
        dispatch_release(downloadQueue);
    } else {
        
        [self.imageView kv_setDetailedImageAtURL:urlString completion:completion];
    }
}

- (void)clearCurrentImage
{
    self.imageView.image = nil;
}

- (void)setUpGifIcon:(NSString *)urlString
{
    _isGIF = [self checkGif:urlString];
    self.gifIcon.hidden = !_isGIF;
    if (_isGIF) {
        [self bringSubviewToFront:self.gifIcon];
        [self.gifIcon resetOrigin:CGPointMake(self.frame.size.width - 50, self.frame.size.height - 40)];
    }
}

- (BOOL)checkGif:(NSString*)url
{
    if (url == nil) {
        return NO;
    }
    
    NSString* extName = [url substringFromIndex:([url length] - 3)];
    return  [extName compare:@"gif"] == NSOrderedSame;
}

- (void)reset
{
    self.gifIcon.hidden = YES;
    _isGIF = NO;
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (CGSize)targetSize
{
    return CGSizeMake(_initialSize.width +  _deltaWidth, _initialSize.height +  _deltaHeight);
}

- (UIImageView*)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.frame];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor colorWithRed:255.0/255 green:255.0/255 blue:255.0/255 alpha:1.0];
        [self addSubview:_imageView];
    }
    return _imageView;
}

-(UIImageView *)coverView
{
    if (!_coverView) {
        _coverView = [[UIImageView alloc] initWithFrame:CGRectMake(-5, -4, self.frame.size.width + 10.0, self.frame.size.height + 10.0)];
        self.coverView.image = [[UIImage imageNamed:@"card_image_edge.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(7.0, 8.0, 9.0, 8.0)];
        _coverView.contentMode = UIViewContentModeScaleToFill;
        _coverView.clipsToBounds = YES;
        [self insertSubview:_coverView aboveSubview:_imageView];
    }
    return _coverView;
}

- (UIImageView *)gifIcon
{
    if (!_gifIcon) {
        _gifIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kRLIconGif]];
        _gifIcon.contentMode = UIViewContentModeTop;
        _gifIcon.hidden = YES;
        
        [_gifIcon resetSize:CGSizeMake(32.0, 20.0)];
        [self addSubview:_gifIcon];
    }
    return _gifIcon;
}

@end
