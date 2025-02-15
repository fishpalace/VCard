//
//  CoreDataViewController.h
//  PushBox
//
//  Created by Xie Hasky on 11-7-24.
//  Copyright 2011年 同济大学. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface CoreDataViewController : UIViewController <NSFetchedResultsControllerDelegate> {
    NSManagedObjectContext *_managedObjectContext;
    NSFetchedResultsController *_fetchedResultsController;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSString *coreDataIdentifier;
@property (nonatomic, readonly) User *currentUser;

+ (User *)getCurrentUser;

@end

@interface CoreDataKernal : NSObject

@property (nonatomic, strong) User *currentUser;

+ (CoreDataKernal *)getKernalInstance;

@end