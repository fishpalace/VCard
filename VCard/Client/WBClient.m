//
//  WBClient.m
//  VCard
//
//  Created by 海山 叶 on 12-3-28.
//  Copyright (c) 2012年 Mondev. All rights reserved.
//

#import "WBClient.h"
#import "SFHFKeychainUtils.h"
#import "WBSDKGlobal.h"
#import "WBUtil.h"
#import "NSNotificationCenter+Addition.h"
#import "AppDelegate.h"

#define kWBURLSchemePrefix              @"WB_"

#define kWBKeychainServiceNameSuffix    @"_WeiBoServiceName"
#define kWBKeychainUserID               @"WeiBoUserID"
#define kWBKeychainAccessToken          @"WeiBoAccessToken"
#define kWBKeychainAdvancedToken        @"kWBKeychainAdvancedToken"
#define kWBKeychainExpireTime           @"WeiBoExpireTime"

typedef enum {
    HTTPMethodPost,
    HTTPMethodForm,
    HTTPMethodGet,
} HTTPMethod;

@interface WBClient()

@property (nonatomic, assign) BOOL shouldReportError;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, retain) NSMutableDictionary *params;
@property (nonatomic, assign) HTTPMethod httpMethod;
@property (nonatomic, assign) WBRequestPostDataType postDataType;

- (NSString *)urlSchemeString;

- (void)saveAuthorizeDataToKeychain;
- (void)readAuthorizeDataFromKeychain;
- (void)deleteAuthorizeDataInKeychain;

@end

@implementation WBClient

@synthesize appKey = _appKey;
@synthesize appSecret = _appSecret;
@synthesize userID = _userID;
@synthesize accessToken = _accessToken;
@synthesize expireTime = _expireTime;
@synthesize redirectURI = _redirectURI;
@synthesize isUserExclusive = isUserExclusive;
@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize hasError = _hasError;
@synthesize shouldReportError = _shouldReportError;

@synthesize preCompletionBlock = _preCompletionBlock;

@synthesize responseJSONObject = _responseJSONObject;

@synthesize path = _path;
@synthesize params = _params;
@synthesize httpMethod = _httpMethod;
@synthesize postDataType = _postDataType;

#pragma mark - WBEngine Life Circle

+ (id)client
{
    //autorelease intentially ommited here
    return [[WBClient alloc] init]; 
}

- (id)init
{
    if (self = [super init]) {
        _appKey = kWBSDKAppKey;
        _appSecret = kWBSDKAppSecret;
        _redirectURI = @"http://";
        
        isUserExclusive = NO;
        
        _params = [[NSMutableDictionary alloc] initWithCapacity:10];
        _hasError = NO;
        _httpMethod = HTTPMethodGet;
        _postDataType = kWBRequestPostDataTypeNone;
        
        self.shouldReportError = YES;
        
        [self readAuthorizeDataFromKeychain];
    }
    
    return self;
}

- (void)dealloc {
    [_appKey release], _appKey = nil;
    [_appSecret release], _appSecret = nil;
    
    [_userID release], _userID = nil;
    [_accessToken release], _accessToken = nil;
    
    [_redirectURI release], _redirectURI = nil;
    
    [_request setDelegate:nil];
    [_request disconnect];
    [_request release], _request = nil;
        
    _delegate = nil;
    
    [super dealloc];
}

#pragma mark - WBEngine Private Methods

- (NSString *)urlSchemeString
{
    return [NSString stringWithFormat:@"%@%@", kWBURLSchemePrefix, _appKey];
}

- (void)saveAuthorizeDataToKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    [SFHFKeychainUtils storeUsername:kWBKeychainUserID andPassword:_userID forServiceName:serviceName updateExisting:YES error:nil];
	[SFHFKeychainUtils storeUsername:kWBKeychainAccessToken andPassword:_accessToken forServiceName:serviceName updateExisting:YES error:nil];
	[SFHFKeychainUtils storeUsername:kWBKeychainExpireTime andPassword:[NSString stringWithFormat:@"%lf", _expireTime] forServiceName:serviceName updateExisting:YES error:nil];
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kUserDefaultAuthorized];
    [[NSUserDefaults standardUserDefaults] setValue:_userID forKey:kUserDefaultCurrentUserID];
}

- (void)readAuthorizeDataFromKeychain
{
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    self.userID = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainUserID andServiceName:serviceName error:nil];
    self.accessToken = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainAccessToken andServiceName:serviceName error:nil];
    self.advancedToken = [SFHFKeychainUtils getPasswordForUsername:kWBKeychainAdvancedToken andServiceName:serviceName error:nil];
    self.expireTime = [[SFHFKeychainUtils getPasswordForUsername:kWBKeychainExpireTime andServiceName:serviceName error:nil] doubleValue];
}

- (void)deleteAuthorizeDataInKeychain
{
    self.userID = nil;
    self.accessToken = nil;
    self.expireTime = 0;
    
    NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
    [SFHFKeychainUtils deleteItemForUsername:kWBKeychainUserID andServiceName:serviceName error:nil];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainAccessToken andServiceName:serviceName error:nil];
	[SFHFKeychainUtils deleteItemForUsername:kWBKeychainExpireTime andServiceName:serviceName error:nil];
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:kUserDefaultAuthorized];
}

#pragma mark - WBEngine Public Methods

- (void)setCompletionBlock:(void (^)(WBClient* client))completionBlock
{
    [_completionBlock autorelease];
    _completionBlock = [completionBlock copy];
}

- (void)setPreCompletionBlock:(WCCompletionBlock)preCompletionBlock
{
    [_preCompletionBlock autorelease];
    _preCompletionBlock = [preCompletionBlock copy];
}

- (WCCompletionBlock)completionBlock
{
    return _completionBlock;
}

- (void)reportCompletion
{
    if (_preCompletionBlock) {
        _preCompletionBlock(self);
    }
    if (_completionBlock) {
        _completionBlock(self);
    }
}


#pragma mark Authorization

- (void)logOut
{
    [self deleteAuthorizeDataInKeychain];
    
    if ([_delegate respondsToSelector:@selector(engineDidLogOut:)]) {
        [_delegate clientDidLogOut:self];
    }
    
    [self autorelease];
}

- (BOOL)isLoggedIn
{
    //    return userID && accessToken && refreshToken;
    return _userID && _accessToken && (_expireTime > 0);
}

- (BOOL)isAuthorizeExpired
{
    if ([[NSDate date] timeIntervalSince1970] > _expireTime)
    {
        // force to log out
        [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}

#pragma mark Upload avatar

- (void)uploadAvatar:(UIImage *)image {
    self.path = @"account/avatar/upload.json";
    [self.params setObject:image forKey:@"image"];
    self.postDataType = kWBRequestPostDataTypeMultipart;
    
    self.httpMethod = HTTPMethodPost;
    [self loadAdvancedRequest];
}

#pragma mark Post

- (void)sendWeiBoWithText:(NSString *)text
                    image:(UIImage *)image
               longtitude:(NSString *)longtitude 
                 latitude:(NSString *)latitude {
    if(image) {
        self.path = @"statuses/upload.json";
        //NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
		[self.params setObject:image forKey:@"pic"];
        self.postDataType = kWBRequestPostDataTypeMultipart;
    } else {
        self.path = @"statuses/update.json";
        self.postDataType = kWBRequestPostDataTypeNormal;
    }
    
    if(image)
        [self.params setObject:(text ? text : @"分享图片") forKey:@"status"];
    else
        [self.params setObject:(text ? text : @"发表微博") forKey:@"status"];
    
    if(longtitude && latitude) {
        [self.params setObject:longtitude forKey:@"long"];
        [self.params setObject:latitude forKey:@"lat"];
    }
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)sendWeiBoWithText:(NSString *)text image:(UIImage *)image {
    [self sendWeiBoWithText:text image:image longtitude:nil latitude:nil];
}

- (void)sendRepostWithText:(NSString *)text
             weiboID:(NSString *)originID 
             commentType:(RepostWeiboType)type {
    self.path = @"statuses/repost.json";
    [self.params setObject:(text ? text : @"") forKey:@"status"];
    [self.params setObject:originID forKey:@"id"];
    [self.params setObject:[NSString stringWithFormat:@"%d", type] forKey:@"is_comment"];
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)sendWeiboCommentWithText:(NSString *)text
             weiboID:(NSString *)originID 
               commentOrigin:(BOOL)commentOrigin {
    self.path = @"comments/create.json";
    [self.params setObject:(text ? text : @"") forKey:@"comment"];
    [self.params setObject:originID forKey:@"id"];
    [self.params setObject:[NSString stringWithFormat:@"%d", commentOrigin] forKey:@"comment_ori"];
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)sendReplyCommentWithText:(NSString *)text
                   weiboID:(NSString *)originID
                         replyID:(NSString *)replyID
                   commentOrigin:(BOOL)commentOrigin {
    self.path = @"comments/reply.json";
    [self.params setObject:(text ? text : @"") forKey:@"comment"];
    [self.params setObject:originID forKey:@"id"];
    [self.params setObject:replyID forKey:@"cid"];
    [self.params setObject:[NSString stringWithFormat:@"%d", commentOrigin] forKey:@"comment_ori"];
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)getAtUsersSuggestions:(NSString *)q {
    self.path = @"search/suggestions/at_users.json";
    // 0 for friends, 1 for followers
    [self.params setObject:@"0" forKey:@"type"];
    [self.params setObject:q forKey:@"q"];
    [self loadNormalRequest];
}

- (void)getTopicSuggestions:(NSString *)q {
    self.path = @"search/suggestions/statuses.json";
    [self.params setObject:q forKey:@"q"];
    [self loadNormalRequest];
}

- (void)getUserSuggestions:(NSString *)q
{
    self.path = @"search/suggestions/users.json";
    [self.params setObject:q forKey:@"q"];
    [self loadNormalRequest];
}

- (void)getUser:(NSString *)userID_
{
    self.path = @"users/show.json";
    if (userID_) {
        [self.params setObject:userID_ forKey:@"uid"];
    } else {
        //TODO: Handle id nil error
        return;
    }
    [self loadNormalRequest];
}

- (void)getUserByScreenName:(NSString *)screenName_
{
    self.path = @"users/show.json";
    if (screenName_) {
        [self.params setObject:screenName_ forKey:@"screen_name"];
    } else {
        //TODO: Handle id nil error
        return;
    }
    [self loadNormalRequest];
}

- (void)authorizeUsingUserID:(NSString *)userID password:(NSString *)password
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:_appKey, @"client_id",
                            _appSecret, @"client_secret",
                            @"password", @"grant_type",
                            _redirectURI, @"redirect_uri",
                            userID, @"username",
                            password, @"password", nil];
    self.params = params;
    
    [self setPreCompletionBlock:^(WBClient *client) {
        if (!client.hasError && [self.responseJSONObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary*)client.responseJSONObject;
            
            self.accessToken = [dict objectForKey:@"access_token"];
            self.userID = [dict objectForKey:@"uid"];
            self.expireTime = [[NSDate date] timeIntervalSince1970] + [[dict objectForKey:@"expires_in"] intValue];
                        
            [self saveAuthorizeDataToKeychain];
            
            WBClient *advancedAuthorizeClient = [WBClient client];
            [advancedAuthorizeClient setCompletionBlock:client.completionBlock];
            client.completionBlock = nil;
            [advancedAuthorizeClient authorizeWithAdvancedAppKeyUsingUserID:userID password:password];
            
            NSLog(@"login step 1 succeeded");
        } else {
            client.hasError = YES;
            NSLog(@"login step 1 failed");
        }
    }];
    [self loadAuthorizeRequest];
}

- (void)authorizeWithAdvancedAppKeyUsingUserID:(NSString *)userID password:(NSString *)password
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:kWBSDKAdvancedAppKey, @"client_id",
                                   kWBSDKAdvancedAppSecret, @"client_secret",
                                   @"password", @"grant_type",
                                   _redirectURI, @"redirect_uri",
                                   userID, @"username",
                                   password, @"password", nil];
    
    self.params = params;
    
    [self setPreCompletionBlock:^(WBClient *client) {
        if([self.responseJSONObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary*)client.responseJSONObject;
            self.advancedToken = [dict objectForKey:@"access_token"];
            
            NSString *serviceName = [[self urlSchemeString] stringByAppendingString:kWBKeychainServiceNameSuffix];
            [SFHFKeychainUtils storeUsername:kWBKeychainAdvancedToken andPassword:_advancedToken forServiceName:serviceName updateExisting:YES error:nil];
            
            WBClient *getUserInfoClient = [WBClient client];
            [getUserInfoClient setCompletionBlock:client.completionBlock];
            client.completionBlock = nil;
            [getUserInfoClient getUser:client.userID];
            
            NSLog(@"login step 2 succeeded");
        } else {
            client.hasError = YES;
            NSLog(@"login step 2 failed");
        }
    }];
    
    [self loadAuthorizeRequest];
}

- (void)getFriendsTimelineSinceID:(NSString *)sinceID 
                            maxID:(NSString *)maxID 
                   startingAtPage:(int)page 
                            count:(int)count
                          feature:(int)feature
{
    self.path = @"statuses/friends_timeline.json";
	
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:maxID forKey:@"max_id"];
    }
    if (page > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    if (feature > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", feature] forKey:@"feature"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"statuses"];
    }];
    
    [self loadNormalRequest];
}

- (void)getAddressFromGeoWithCoordinate:(NSString *)coordinate
{
    self.path = @"location/geo/geo_to_address.json";
	
    if (coordinate) {
        [self.params setObject:coordinate forKey:@"coordinate"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"geos"];
    }];
    
    [self loadNormalRequest];
}

- (void)getFriendsOfUser:(NSString *)userID cursor:(int)cursor count:(int)count
{
    self.path = @"friendships/friends.json";
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    }
    if (cursor) {
        [self.params setObject:[NSString stringWithFormat:@"%d", cursor] forKey:@"cursor"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    [self loadNormalRequest];
}


- (void)getFollowersOfUser:(NSString *)userID cursor:(int)cursor count:(int)count
{
    self.path = @"friendships/followers.json";
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    }
    if (cursor) {
        [self.params setObject:[NSString stringWithFormat:@"%d", cursor] forKey:@"cursor"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    [self loadNormalRequest];
}

- (void)getUserTimeline:(NSString *)userID 
				SinceID:(NSString *)sinceID 
                  maxID:(NSString *)maxID 
		 startingAtPage:(int)page 
				  count:(int)count
                feature:(int)feature
{
    self.path = @"statuses/user_timeline.json";
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    } else {
        //TODO: Handle userID nil Error
        return;
    }
	
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:maxID forKey:@"max_id"];
    }
    if (page > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    if (feature > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", feature] forKey:@"feature"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"statuses"];
    }];
    
    [self loadNormalRequest];
}

- (void)getCommentOfStatus:(NSString *)statusID
                   maxID:(NSString *)maxID
                    count:(int)count
             authorFilter:(BOOL)filter
{
    self.path = @"comments/show.json";
    if (statusID) {
        [self.params setObject:statusID forKey:@"id"];
    }
    if (maxID) {
        [self.params setObject:[NSString stringWithFormat:@"%@", maxID] forKey:@"max_id"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    int filterFactor = filter ? 1 : 0;
    [self.params setObject:[NSString stringWithFormat:@"%d", filterFactor] forKey:@"filter_by_author"];
    
    [self loadNormalRequest];
}


- (void)getRepostOfStatus:(NSString *)statusID
                    maxID:(NSString *)maxID
                    count:(int)count
             authorFilter:(BOOL)filter
{
    self.path = @"statuses/repost_timeline.json";
    if (statusID) {
        [self.params setObject:statusID forKey:@"id"];
    }
    if (maxID >= 0) {
        [self.params setObject:[NSString stringWithFormat:@"%@", maxID] forKey:@"max_id"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    int filterFactor = filter ? 1 : 0;
    [self.params setObject:[NSString stringWithFormat:@"%d", filterFactor] forKey:@"filter_by_author"];
    
    [self loadNormalRequest];
}

- (void)getCommentsToMeSinceID:(NSString *)sinceID
                         maxID:(NSString *)maxID
                          page:(int)page
                         count:(int)count
{
    self.path = @"comments/to_me.json";
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:[NSString stringWithFormat:@"%@", maxID] forKey:@"max_id"];
    }
    [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    
    [self loadNormalRequest];
}

- (void)getCommentsByMeSinceID:(NSString *)sinceID
                         maxID:(NSString *)maxID
                          page:(int)page
                         count:(int)count
{
    self.path = @"comments/by_me.json";
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:[NSString stringWithFormat:@"%@", maxID] forKey:@"max_id"];
    }
    [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    
    [self loadNormalRequest];
}

- (void)getCommentsMentioningMeSinceID:(NSString *)sinceID
                                 maxID:(NSString *)maxID
                                  page:(int)page
                                 count:(int)count
{
    self.path = @"comments/mentions.json";
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:[NSString stringWithFormat:@"%@", maxID] forKey:@"max_id"];
    }
    [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    
    [self loadNormalRequest];
}


- (void)getMentionsSinceID:(NSString *)sinceID
					 maxID:(NSString *)maxID 
					  page:(int)page 
					 count:(int)count
{
	self.path = @"statuses/mentions.json";
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:maxID forKey:@"max_id"];
    }
    if (page) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"statuses"];
    }];
    
    [self loadNormalRequest];
}

- (void)follow:(NSString *)userID
{
    self.path = @"friendships/create.json";
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    } else {
        //TODO: Handle id nil error
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)unfollow:(NSString *)userID
{
    self.path = @"friendships/destroy.json";
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    } else {
        //TODO: Handle id nil error
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)favorite:(NSString *)statusID
{
    self.path = @"favorites/create.json";
    if (statusID) {
        [self.params setObject:statusID forKey:@"id"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)unFavorite:(NSString *)statusID
{
    self.path = @"favorites/destroy.json";
    if (statusID) {
        [self.params setObject:statusID forKey:@"id"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)deleteStatus:(NSString *)statusID
{
    self.path = @"statuses/destroy.json";
    if (statusID) {
        [self.params setObject:statusID forKey:@"id"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)deleteComment:(NSString *)commentID
{
    self.path = @"comments/destroy.json";
    if (commentID) {
        [self.params setObject:commentID forKey:@"cid"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)getUnreadCount:(NSString *)userID
{
    self.shouldReportError = NO;
    self.path = @"remind/unread_count.json";
    
    if (userID) {
        [self.params setObject:userID forKey:@"uid"];
    } else {
        return;
    }
    
    [self loadNormalRequest];
}

- (void)resetUnreadCount:(NSString *)type
{
    self.shouldReportError = NO;
    self.path = @"remind/set_count.json";
    if (type) {
        [self.params setObject:type forKey:@"type"];
    }
    
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)searchUser:(NSString *)q page:(int)page count:(int)count
{
    self.path = @"search/users.json";
    if (q) {
        [self.params setObject:q forKey:@"q"];
    }
    if (count) {
        [self.params setObject:[NSString stringWithFormat:@"%i", count] forKey:@"count"];
    }
    if (page) {
        [self.params setObject:[NSString stringWithFormat:@"%i", page] forKey:@"page"];
    }
    
    [self loadAdvancedRequest];
}

- (void)searchTopic:(NSString *)q
     startingAtPage:(int)page
              count:(int)count
{
    self.path = @"search/topics.json";
    if (q) {
        [self.params setObject:q forKey:@"q"];
    } else {
        //TODO: Handle userID nil Error
        return;
    }
	
    if (page > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"statuses"];
    }];
    
    [self loadNormalRequest];
}

- (void)getGroups
{
    self.shouldReportError = NO;
    self.path = @"friendships/groups.json";
    [self loadAdvancedRequest];
}

- (void)getTrends
{
    self.path = @"trends.json";
    [self.params setObject:self.userID forKey:@"uid"];
    [self.params setObject:[NSString stringWithFormat:@"%d", 200] forKey:@"count"];
    [self loadNormalRequest];
}

- (void)getHotTopics
{
    self.path = @"trends/daily.json";
    [self loadNormalRequest];
}

- (void)checkIsTrendFollowed:(NSString *)trendName
{
    self.path = @"trends/is_follow.json";
    if (trendName) {
        [self.params setObject:trendName forKey:@"trend_name"];
    }
    
    [self loadNormalRequest];
}

- (void)followTrend:(NSString *)trendName
{
    self.path = @"trends/follow.json";
    if (trendName) {
        [self.params setObject:trendName forKey:@"trend_name"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)unfollowTrend:(NSString *)trendName
{
    self.path = @"trends/destroy.json";
    if (trendName) {
        [self.params setObject:trendName forKey:@"trend_id"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadNormalRequest];
}

- (void)deleteGroup:(NSString *)groupID
{
    self.path = @"friendships/groups/destroy.json";
    if (groupID) {
        [self.params setObject:groupID forKey:@"list_id"];
    }
    self.postDataType = kWBRequestPostDataTypeNormal;
    self.httpMethod = HTTPMethodPost;
    [self loadAdvancedRequest];
}

- (void)getFavouritesWithPage:(int)page
                        count:(int)count
{
    self.path = @"favorites.json";
    if (page > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"favorites"];
    }];
    [self loadNormalRequest];
}

- (void)getGroupTimelineWithGroupID:(NSString *)groupID
                            sinceID:(NSString *)sinceID
                              maxID:(NSString *)maxID
                     startingAtPage:(int)page
                              count:(int)count
                            feature:(int)feature
{
    self.path = @"friendships/groups/timeline.json";
	
    if (groupID) {
        [self.params setObject:groupID forKey:@"list_id"];
    }
    if (sinceID) {
        [self.params setObject:sinceID forKey:@"since_id"];
    }
    if (maxID) {
        [self.params setObject:maxID forKey:@"max_id"];
    }
    if (page > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", page] forKey:@"page"];
    }
    if (count > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", count] forKey:@"count"];
    }
    if (feature > 0) {
        [self.params setObject:[NSString stringWithFormat:@"%d", feature] forKey:@"feature"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"statuses"];
    }];
    
    [self loadAdvancedRequest];
}

- (void)getLongURLWithShort:(NSString *)shortURL
{
    self.path = @"short_url/expand.json";
    
    if (shortURL) {
        [self.params setObject:shortURL forKey:@"url_short"];
    }
    
    [self setPreCompletionBlock:^(WBClient *client) {
        NSDictionary *dict = self.responseJSONObject;
        self.responseJSONObject = [dict objectForKey:@"urls"];
    }];
    
    [self loadNormalRequest];
}


#pragma mark Request

- (void)loadNormalRequest
{
    [_request disconnect];
    
    self.request = [WBRequest requestWithAccessToken:_accessToken
                                                 url:[NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, self.path]
                                          httpMethod:self.httpMethod == HTTPMethodGet ? @"GET" : @"POST"
                                              params:self.params
                                        postDataType:self.postDataType
                                    httpHeaderFields:nil
                                            delegate:self];
	
	[_request connect];
}

- (void)loadAdvancedRequest
{
    [_request disconnect];
    
    self.request = [WBRequest requestWithAccessToken:_advancedToken
                                                 url:[NSString stringWithFormat:@"%@%@", kWBSDKAPIDomain, self.path]
                                          httpMethod:self.httpMethod == HTTPMethodGet ? @"GET" : @"POST"
                                              params:self.params
                                        postDataType:self.postDataType
                                    httpHeaderFields:nil
                                            delegate:self];
	
	[_request connect];
}

- (void)loadAuthorizeRequest
{
    [_request disconnect];
    
    self.request = [WBRequest requestWithURL:kWBAccessTokenURL
                                  httpMethod:@"POST"
                                      params:self.params
                                postDataType:kWBRequestPostDataTypeNormal
                            httpHeaderFields:nil 
                                    delegate:self];
	
	[_request connect];
}   

#pragma mark - WBRequestDelegate Methods

- (void)request:(WBRequest *)request didFinishLoadingWithResult:(id)result
{
    self.responseJSONObject = result;
    [self reportCompletion];
    [self autorelease];
}

- (void)request:(WBRequest *)request didFailWithError:(NSError *)error
{
    if(self.shouldReportError)
        [NSNotificationCenter postWBClientErrorNotification:error];
    self.hasError = YES;
    [self reportCompletion];
    [self autorelease];
}

@end
