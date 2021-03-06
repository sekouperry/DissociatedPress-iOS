//
//  Dissociator.h
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 11/11/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSPNewsLoader.h"
#import "DSPNewsStory.h"

@interface DSPDissociatedNewsLoader : DSPNewsLoader

- (NSArray *)loadDissociatedNewsForQueries:(NSArray *)queries pageNumber:(int)pageNumber;
- (NSArray *)loadDissociatedNewsForTopics:(NSArray *)topics pageNumber:(int)pageNumber;

- (NSString *)dissociatedTitleForStory:(DSPNewsStory *)story;
- (NSString *)dissociatedContentForStory:(DSPNewsStory *)story;

@end
