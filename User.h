//
//  User.h
//  VCard
//
//  Created by 海山 叶 on 12-4-17.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, User;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * blogURL;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * domainURL;
@property (nonatomic, retain) NSString * favouritesCount;
@property (nonatomic, retain) NSString * followersCount;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSString * friendsCount;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * profileImageURL;
@property (nonatomic, retain) NSString * screenName;
@property (nonatomic, retain) NSString * selfDescription;
@property (nonatomic, retain) NSString * statusesCount;
@property (nonatomic, retain) NSDate * updateDate;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * verified;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *commentsToMe;
@property (nonatomic, retain) NSSet *favorites;
@property (nonatomic, retain) NSSet *followers;
@property (nonatomic, retain) NSSet *friends;
@property (nonatomic, retain) NSSet *friendsStatuses;
@property (nonatomic, retain) NSSet *statuses;

+ (User *)insertUser:(NSDictionary *)dict inManagedObjectContext:(NSManagedObjectContext *)context;
+ (User *)userWithID:(NSString *)userID inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)deleteAllObjectsInManagedObjectContext:(NSManagedObjectContext *)context;
- (BOOL)isEqualToUser:(User *)user;

@end

@interface User (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addCommentsToMeObject:(Comment *)value;
- (void)removeCommentsToMeObject:(Comment *)value;
- (void)addCommentsToMe:(NSSet *)values;
- (void)removeCommentsToMe:(NSSet *)values;

- (void)addFavoritesObject:(NSManagedObject *)value;
- (void)removeFavoritesObject:(NSManagedObject *)value;
- (void)addFavorites:(NSSet *)values;
- (void)removeFavorites:(NSSet *)values;

- (void)addFollowersObject:(User *)value;
- (void)removeFollowersObject:(User *)value;
- (void)addFollowers:(NSSet *)values;
- (void)removeFollowers:(NSSet *)values;

- (void)addFriendsObject:(User *)value;
- (void)removeFriendsObject:(User *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

- (void)addFriendsStatusesObject:(NSManagedObject *)value;
- (void)removeFriendsStatusesObject:(NSManagedObject *)value;
- (void)addFriendsStatuses:(NSSet *)values;
- (void)removeFriendsStatuses:(NSSet *)values;

- (void)addStatusesObject:(NSManagedObject *)value;
- (void)removeStatusesObject:(NSManagedObject *)value;
- (void)addStatuses:(NSSet *)values;
- (void)removeStatuses:(NSSet *)values;

@end