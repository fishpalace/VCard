//
//  MotionsFilterTableViewController.h
//  VCard
//
//  Created by 紫川 王 on 12-4-12.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MotionsFilterTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView *tableView;

@end
