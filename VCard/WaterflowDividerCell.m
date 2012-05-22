//
//  WaterflowDividerCell.m
//  VCard
//
//  Created by 海山 叶 on 12-5-22.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "WaterflowDividerCell.h"

@implementation WaterflowDividerCell

@synthesize dividerViewController = _dividerViewController;

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier currentUser:(User*)currentUser_
{
    if(self = [super initWithReuseIdentifier:reuseIdentifier currentUser:currentUser_])
	{
		self.reuseIdentifier = reuseIdentifier;
        self.autoresizingMask = UIViewAutoresizingNone;
    }
	
	return self;
}

- (DividerViewController*)dividerViewController
{
    if (_dividerViewController == nil) {
        _dividerViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL] instantiateViewControllerWithIdentifier:@"DividerViewController"];
        
        CGRect frame = _dividerViewController.view.frame;
        frame.origin = CGPointMake(0, 0);
        _dividerViewController.view.frame = frame;
        
        [self addSubview:_dividerViewController.view];
    }
    return _dividerViewController;
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