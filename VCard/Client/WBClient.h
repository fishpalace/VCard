//
//  WBClient.h
//  VCard
//
//  Created by 海山 叶 on 12-3-28.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WBRequest.h"

#define kWBClientResetCountTypeStatus   @"status"
#define kWBClientResetCountTypeFollower @"follower"
#define kWBClientResetCountTypeComment  @"cmt"
#define kWBClientResetCountTypeMention  @"mention_status"
#define kWBClientResetCountTypeMetionComment @"mention_cmt"
#define kWBClientResetCountTypeMessage  @"dm"

typedef enum {
    RepostWeiboTypeCommentNone      = 0,
    RepostWeiboTypeCommentCurrent   = 1,
    RepostWeiboTypeCommentOrigin    = 2,
    RepostWeiboTypeCommentBoth      = 3,
} RepostWeiboType;


@class WBClient;

@protocol WBClientDelegate <NSObject>

@optional

// If you try to log in with logIn or logInUsingUserID method, and
// there is already some authorization info in the Keychain,
// this method will be invoked.
// You may or may not be allowed to continue your authorization,
// which depends on the value of isUserExclusive.
- (void)clientAlreadyLoggedIn:(WBClient *)client;

// Log in successfully.
- (void)clientDidLogIn:(WBClient *)client;

// Failed to log in.
// Possible reasons are:
// 1) Either username or password is wrong;
// 2) Your app has not been authorized by Sina yet.
- (void)client:(WBClient *)client didFailToLogInWithError:(NSError *)error;

// Log out successfully.
- (void)clientDidLogOut:(WBClient *)client;

// When you use the WBClient's request methods,
// you may receive the following four callbacks.
- (void)clientNotAuthorized:(WBClient *)client;
- (void)clientAuthorizeExpired:(WBClient *)client;

- (void)client:(WBClient *)client requestDidFailWithError:(NSError *)error;
- (void)client:(WBClient *)client requestDidSucceedWithResult:(id)result;

@end

typedef void (^WCCompletionBlock)(WBClient *client);

@interface WBClient : NSObject<WBRequestDelegate> {        
    // Determine whether user must log out before another logging in.
    BOOL            _isUserExclusive;
    
    WCCompletionBlock _completionBlock;
}

@property (nonatomic, copy) NSString *appKey;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *advancedToken;
@property (nonatomic, assign) NSTimeInterval expireTime;
@property (nonatomic, copy) NSString *redirectURI;
@property (nonatomic, assign) BOOL isUserExclusive;
@property (nonatomic, retain) WBRequest *request;
@property (nonatomic, assign) id<WBClientDelegate> delegate;

@property (nonatomic, copy) NSString *statusID;

@property (nonatomic, copy) WCCompletionBlock preCompletionBlock;

@property (nonatomic, assign) BOOL hasError;
@property (nonatomic, retain) id responseJSONObject;
@property (nonatomic, retain) NSError *responseError;

- (void)setCompletionBlock:(void (^)(WBClient* client))completionBlock;
- (WCCompletionBlock)completionBlock;

+ (id)client;

- (id)init;
- (void)logOut;
- (BOOL)isLoggedIn;
- (BOOL)isAuthorizeExpired;


- (void)sendWeiBoWithText:(NSString *)text image:(UIImage *)image;
- (void)sendWeiBoWithText:(NSString *)text 
                    image:(UIImage *)image
               longtitude:(NSString *)longtitude 
                 latitude:(NSString *)latitude;
- (void)sendRepostWithText:(NSString *)text
             weiboID:(NSString *)originID 
               commentType:(RepostWeiboType)type;
- (void)sendWeiboCommentWithText:(NSString *)text
              weiboID:(NSString *)originID 
               commentOrigin:(BOOL)repost;
- (void)sendReplyCommentWithText:(NSString *)text
                   weiboID:(NSString *)originID
                         replyID:(NSString *)replyID
                   commentOrigin:(BOOL)commentOrigin;

- (void)authorizeUsingUserID:(NSString *)userID password:(NSString *)password;
- (void)getUser:(NSString *)userID_;
- (void)getUserByScreenName:(NSString *)screenName_;
- (void)getUserBilateral;
- (void)getFriendsTimelineSinceID:(NSString *)sinceID 
                            maxID:(NSString *)maxID 
                   startingAtPage:(int)page 
                            count:(int)count
                          feature:(int)feature;
- (void)getUserTimeline:(NSString *)userID 
				SinceID:(NSString *)sinceID 
                  maxID:(NSString *)maxID 
		 startingAtPage:(int)page 
				  count:(int)count
                feature:(int)feature;
- (void)getAddressFromGeoWithCoordinate:(NSString *)coordinate;

- (void)getCommentOfStatus:(NSString *)statusID
                    maxID:(NSString *)maxID
                    count:(int)count
             authorFilter:(BOOL)filter;

- (void)getRepostOfStatus:(NSString *)statusID
                    maxID:(NSString *)maxID
                    count:(int)count
             authorFilter:(BOOL)filter;

- (void)getCommentsToMeSinceID:(NSString *)sinceID
                         maxID:(NSString *)maxID
                          page:(int)page
                         count:(int)count;

- (void)getCommentsByMeSinceID:(NSString *)sinceID
                         maxID:(NSString *)maxID
                          page:(int)page
                         count:(int)count;

- (void)getCommentsMentioningMeSinceID:(NSString *)sinceID
                                 maxID:(NSString *)maxID
                                  page:(int)page
                                 count:(int)count;

- (void)getMentionsSinceID:(NSString *)sinceID 
					 maxID:(NSString *)maxID 
					  page:(int)page 
					 count:(int)count;

- (void)getFriendsOfUser:(NSString *)userID cursor:(int)cursor count:(int)count;
- (void)getFollowersOfUser:(NSString *)userID cursor:(int)cursor count:(int)count;

- (void)getAtUsersSuggestions:(NSString *)q;
- (void)getTopicSuggestions:(NSString *)q;
- (void)getUserSuggestions:(NSString *)q;

- (void)follow:(NSString *)userID;
- (void)unfollow:(NSString *)userID;

- (void)favorite:(NSString *)statusID;
- (void)unFavorite:(NSString *)statusID;
- (void)getFavouriteIDs:(int)count;

- (void)deleteStatus:(NSString *)statusID;
- (void)deleteComment:(NSString *)commentID;
- (void)getUnreadCount:(NSString *)userID;
- (void)resetUnreadCount:(NSString *)type;

- (void)searchUser:(NSString *)q page:(int)page count:(int)count;

- (void)searchTopic:(NSString *)q
         startingAt:(NSDate *)startDate
           clearDup:(BOOL)dup
              count:(int)count;
- (void)searchTopic:(NSString *)q
     startingAtPage:(int)page
              count:(int)count;

- (void)getGroups;
- (void)getTrends;
- (void)getHotTopics;
- (void)checkIsTrendFollowed:(NSString *)trendName;
- (void)followTrend:(NSString *)trendName;
- (void)unfollowTrend:(NSString *)trendName;
- (void)deleteGroup:(NSString *)groupID;
- (void)getGroupInfoOfUser:(NSString *)userID;

- (void)addUser:(NSString *)userID toGroup:(NSString *)group;
- (void)removeUser:(NSString *)userID fromGroup:(NSString *)group;

- (void)getDirectMessageConversationListWithCursor:(int)cursor count:(int)count;
- (void)getDirectMessageConversionMessagesOfUser:(NSString *)userID
                                         sinceID:(NSString *)sinceID
                                           maxID:(NSString *)maxID
                                  startingAtPage:(int)page
                                           count:(int)count;
- (void)sendDirectMessage:(NSString *)text toUser:(NSString *)screenName;
- (void)deleteDirectMessage:(NSString *)messageID;
- (void)deleteConversationWithUser:(NSString *)userID;
- (void)isMessageAvailable:(NSString *)userID;

- (void)getFavouritesWithPage:(int)page
                        count:(int)count;

- (void)getGroupTimelineWithGroupID:(NSString *)groupID
                            sinceID:(NSString *)sinceID
                              maxID:(NSString *)maxID
                     startingAtPage:(int)page
                              count:(int)count
                            feature:(int)feature;

- (void)uploadAvatar:(UIImage *)image;
- (void)getLongURLWithShort:(NSString *)shortURL;

@end
