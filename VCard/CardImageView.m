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

@implementation CardImageView

@synthesize imageView = _imageView;

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
        _shadowView = [[CardImageViewShadowView alloc] initWithFrame:self.frame];
        [self insertSubview:_shadowView atIndex:0];
        [self insertSubview:self.imageView atIndex:1];
        self.clearsContextBeforeDrawing = YES;
        self.imageView.layer.edgeAntialiasingMask = 0;
    }
    return self;
}

- (void)resetHeight:(CGFloat)height
{
    [_shadowView removeFromSuperview];
    _shadowView = nil;
    
    CGRect frame = CGRectMake(-4.0, 13.0, StatusImageWidth, height);
    self.transform = CGAffineTransformMakeRotation(0);
    self.frame = frame;
    
    frame.origin = CGPointMake(0.0, 0.0);
    self.imageView.frame = frame;

    _shadowView = [[CardImageViewShadowView alloc] initWithFrame:self.frame];
    [self insertSubview:_shadowView aboveSubview:self.imageView];
    
    CGFloat rotatingDegree = (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * 4) - 2;
    self.transform = CGAffineTransformMakeRotation(rotatingDegree * M_PI / 180);
}

- (UIImageView*)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.frame];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor colorWithRed:255.0/255 green:255.0/255 blue:255.0/255 alpha:1.0];
        [self insertSubview:_imageView belowSubview:_shadowView];
    }
    return _imageView;
}

- (UIImageView *)gifIcon
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.frame];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.backgroundColor = [UIColor colorWithRed:255.0/255 green:255.0/255 blue:255.0/255 alpha:1.0];
        [self insertSubview:_imageView belowSubview:_shadowView];
    }
    return _imageView;
}

- (void)loadImageFromURL:(NSString *)urlString 
              completion:(void (^)())completion
{
    
    [self.imageView kv_cancelImageDownload];
    NSURL *anImageURL = [NSURL URLWithString:urlString];
    [self.imageView kv_setImageAtURL:anImageURL];
	
}

- (void)loadTweetImageFromURL:(NSString *)urlString 
                   completion:(void (^)())completion
{
    [self.imageView kv_cancelImageDownload];
    NSURL *anImageURL = [NSURL URLWithString:urlString];
    [self.imageView kv_setImageAtURL:anImageURL];
	
}

- (void)clearCurrentImage
{
    self.imageView.image = nil;
}

- (BOOL)checkGif:(NSString*)url
{
    if (url == nil) {
        return NO;
    }
    
    NSString* extName = [url substringFromIndex:([url length] - 3)];
    
    return [extName compare:@"gif"] == NSOrderedSame;    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
