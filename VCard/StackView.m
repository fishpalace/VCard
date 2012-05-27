//
//  StackView.m
//  VCard
//
//  Created by 海山 叶 on 12-5-26.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "StackView.h"
#import "UIView+Resize.h"

#define PageWidth 430.0
#define ScrollViewWidth 384.0


@interface StackView () {
    NSInteger _currentPageIndex;
}

@end

@implementation StackView

@synthesize scrollView = _scrollView;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpScrollView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setUpScrollView];
    }
    return self;
}

#pragma mark - Handle Changes To The Stack

- (void)setUpScrollView
{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(self.frame.size.width - ScrollViewWidth, 0.0, ScrollViewWidth, self.frame.size.height)];
    _scrollView.clipsToBounds = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.delegate = self;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    [self addSubview:_scrollView];
}

- (void)addNewPage:(UIView *)newPage replacingView:(BOOL)replacing
{
    int pageNumber = [_delegate pageNumber];
    int width = pageNumber == 1 ? ScrollViewWidth + 1 : ScrollViewWidth * pageNumber;
    
    newPage.frame = [self frameForNewView:pageNumber];
    
    [_scrollView setContentSize:CGSizeMake(width, 705.0)];
    [_scrollView addSubview:newPage];
    
    if (replacing) {
        [newPage resetOriginX:newPage.frame.origin.x + ScrollViewWidth];
        [UIView animateWithDuration:0.3 animations:^{
            [newPage resetOriginX:newPage.frame.origin.x - ScrollViewWidth];
        }];
    }
    
    
    [UIView animateWithDuration:0.3 animations:^{
        [_scrollView setContentOffset:CGPointMake(newPage.frame.origin.x, 0.0)];
    }];
}

- (CGRect)frameForNewView:(int)pageNumber
{
    return CGRectMake((pageNumber - 1) * ScrollViewWidth, 0.0, PageWidth, self.frame.size.height);
}

- (void)removeLastView:(UIView *)lastView
{
    [UIView animateWithDuration:0.3 animations:^{
        [lastView resetOriginX:lastView.frame.origin.x + ScrollViewWidth];
    } completion:^(BOOL finished) {
        [lastView removeFromSuperview];
    }];
}

#pragma mark - Handle Touch Event

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint cp = [self convertPoint:point toView:_scrollView];
    if ([_scrollView pointInside:cp withEvent:event]) {
        return [_scrollView hitTest:cp withEvent:event];
    }
    
    CGPoint superPoint = [self convertPoint:point toView:self.superview];
    int touchedPageIndex = [self touchedPageIndex:superPoint];
    if (touchedPageIndex >= 0) {
        
        CGPoint subPoint = [self convertPoint:superPoint];
        UIView *pageView = [_delegate viewForPageIndex:touchedPageIndex];
        
        for(UIView *subview in pageView.subviews) {
            UIView *view = [subview hitTest:subPoint withEvent:event];
            if (view) 
                return view;
        }
        return _scrollView;
        
    } else {
        return _scrollView;
    }
}

- (int)touchedPageIndex:(CGPoint)point
{
    CGFloat screenWidth = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 1024.0 : 768.0;
    int currentPageIndex = _scrollView.contentOffset.x / ScrollViewWidth;
    int touchedPageIndex;
    if (point.x > screenWidth - ScrollViewWidth) {
        touchedPageIndex = currentPageIndex;
    } else if (point.x > screenWidth - ScrollViewWidth * 2){
        touchedPageIndex = currentPageIndex - 1;
    } else {
        touchedPageIndex = currentPageIndex - 2;
    }
    return touchedPageIndex;
}

- (CGPoint)convertPoint:(CGPoint)point
{
    CGPoint result = point;
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        if (result.x > ScrollViewWidth) {
            result.x -= 256.0;
        } else {
            result.x = -result.x;
        }
    }
    return result;
}

@end
