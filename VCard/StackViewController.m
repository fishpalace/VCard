//
//  StackViewController.m
//  VCard
//
//  Created by 海山 叶 on 12-5-26.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "StackViewController.h"
#import "StackViewPageController.h"
#import "UIView+Resize.h"

@interface StackViewController ()

@end

@implementation StackViewController

@synthesize stackView = _stackView;
@synthesize controllerStack = _controllerStack;
@synthesize delegate = _delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.stackView.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addNewStackPage:)
                                                 name:kNotificationNameAddNewStackPage
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(stackViewSendShowBGNotification) 
                                                 name:kNotificationNameOrientationWillChange 
                                               object:nil];
    
    //FIXME: Debug
    //    self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)stackViewSendShowBGNotification
{
    [self.stackView sendShowBGNotification];
}

- (void)insertStackPage:(StackViewPageController *)vc
                atIndex:(int)targetIndex
           withPageType:(StackViewPageType)pageType
        pageDescription:(NSString *)pageDescription;
{
    StackViewPageController *searchResult = [self checkStackForType:pageType description:pageDescription];
    if (searchResult) {
        [self.stackView scrollToTargetView:searchResult.view];
    } else {
        [self addViewController:vc atIndex:targetIndex];
    }
}

- (StackViewPageController *)checkStackForType:(StackViewPageType)pageType description:(NSString *)pageDescription
{
    StackViewPageController *result = nil;
    for (StackViewPageController *vc in self.controllerStack) {
        if (vc.pageType == pageType && [vc.pageDescription isEqualToString:pageDescription]) {
            result = vc;
        }
    }
    return result;
}

- (void)addViewController:(StackViewPageController *)vc 
                  atIndex:(int)targetIndex
{
    BOOL replacingOtherView = NO;
    if (self.controllerStack.count != 0) {
        while (self.controllerStack.count - 1 > targetIndex) {
            StackViewPageController *lastViewController = [self.controllerStack lastObject];
            [self.stackView removeLastView:lastViewController.view];
            [self.controllerStack removeLastObject];
            replacingOtherView = YES;
        }
    }
    
    vc.pageIndex = _controllerStack.count;
    vc.currentUser = self.currentUser;
    
    [vc.view resetHeight:self.view.frame.size.height];
    
    [self.controllerStack addObject:vc];
    for (StackViewPageController *animationVC in self.controllerStack) {
        //TODO: Implement Swing Animation
        [animationVC stackScrolling];
        // [animationVC stackScrollingStart];
        // [animationVC stackScrollingEnd];
        // [animationVC performSelector:@selector(stackScrollingEnd) withObject:nil afterDelay:0.1];
    }
    [self.stackView addNewPage:vc.view replacingView:replacingOtherView completion:^{
        [vc initialLoad];
    }];
}

#pragma mark - Stack View Delegate

- (int)pageNumber
{
    return self.controllerStack.count;
}

- (UIView *)viewForPageIndex:(int)index
{
    if (index >= self.controllerStack.count) {
        return nil;
    }
    
    StackViewPageController *vc = [self.controllerStack objectAtIndex:index];
    return vc.view;
}

- (void)stackBecomedEmpty
{
    [_delegate clearStack];
}

- (void)stackViewDidScroll
{
    [_delegate stackViewScrolledWithOffset:_stackView.scrollView.contentOffset.x width:_stackView.scrollView.contentSize.width - 384.0];
}

#pragma mark - Property

- (NSMutableArray *)controllerStack
{
    if (!_controllerStack) {
        _controllerStack = [[NSMutableArray alloc] init];
    }
    return _controllerStack;
}

@end
