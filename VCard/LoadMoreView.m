//
//  LoadMoreView.m
//  VCard
//
//  Created by 海山 叶 on 12-5-30.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "LoadMoreView.h"


@implementation LoadMoreView

@synthesize delegate = _delegate; 
@synthesize scrollView = _scrollView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithScrollView:(UIScrollView *)scroll {
    CGRect frame = CGRectMake(0.0f, scroll.contentSize.height, scroll.bounds.size.width, 67.0);
    
    if ((self = [super initWithFrame:frame])) {
        self.scrollView = scroll;
        
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityView.frame = CGRectMake(0.0f, self.scrollView.contentSize.height, self.frame.size.width, 67.0f);
        _activityView.autoresizingMask = UIViewAutoresizingNone;
        [self addSubview:_activityView];
        
		[self setState:LoadMoreViewStateLoading];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(resetLayoutToOrientation:)
                                                     name:kNotificationNameOrientationWillChange
                                                   object:nil];
    }
    
    return self;
}

- (void)finishedLoading:(BOOL)hasMoreViews
{
    if (hasMoreViews) {
        [self setState:LoadMoreViewStateLoading];
    } else {
        [self setState:LoadMoreViewStateHidden];
    }
    [self resetOriginY:self.scrollView.contentSize.height];
}

- (void)startLoadingAnimation
{
    [_activityView startAnimating];
}

- (void)stopLoadingAnimation
{
    [_activityView stopAnimating];
}

- (void)setState:(LoadMoreViewState)state {
    _state = state;
    
    UIEdgeInsets inset = self.scrollView.contentInset;
	switch (_state) {
		case LoadMoreViewStateHidden:
            inset.bottom = 0.0;
            self.scrollView.contentInset = inset;
            [self stopLoadingAnimation];
			break;
		case LoadMoreViewStateLoading:
            inset.bottom = 67.0;
            self.scrollView.contentInset = inset;
            [self startLoadingAnimation];
			break;
            
		default:
			break;
	}
}

- (void)resetLayoutToOrientation:(NSNotification *)notification
{
    CGFloat width = [(NSString *)notification.object isEqualToString:kOrientationPortrait] ? 768.0 : 1024;
    [_activityView resetWidth:width];
}


@end