//
//  ActionPopoverViewController.h
//  EnterTheMatrix
//
//  Created by Mark Pospesel on 3/8/12.
//  Copyright (c) 2012 Mark Pospesel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ActionPopoverViewControllerDelegate;

@interface ActionPopoverViewController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIImageView *topBar;
@property (nonatomic, weak) IBOutlet UIView *centerBar;
@property (nonatomic, weak) IBOutlet UIImageView *bottomBar;
@property (nonatomic, weak) id<ActionPopoverViewControllerDelegate> delegate;

- (void)setCropView:(UIView *)view cropPosY:(CGFloat)y;
- (void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer;

@end

@protocol ActionPopoverViewControllerDelegate <NSObject>

- (void)actionPopoverViewDidDismiss;

@end
