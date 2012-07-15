//
//  SettingViewController.h
//  VCard
//
//  Created by 王 紫川 on 12-7-12.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelfPageControl.h"

@interface TipsViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet ShelfPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIButton *finishButton;

- (void)show;

- (IBAction)didClickFinishButton:(UIButton *)sender;

@end
