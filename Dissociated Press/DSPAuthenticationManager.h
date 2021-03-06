// AuthenticationManager.h
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 12/8/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^AuthenticationSuccessBlock)(NSError *error);

@interface DSPAuthenticationManager : NSObject

+ (void)loginWithKeychainWithCompletion:(AuthenticationSuccessBlock)completion;
+ (void)signInWithUsername:(NSString *)username password:(NSString *)password completion:(AuthenticationSuccessBlock)completion;
+ (void)signOut;
+ (NSString *)passwordForDissociatedPress;
+ (NSString *)usernameForDissociatedPress;

@end
