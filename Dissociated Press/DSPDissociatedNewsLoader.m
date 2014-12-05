//
//  Dissociator.m
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 11/11/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//

#import "DSPDissociatedNewsLoader.h"
#import "DSPNewsStory.h"

@interface DSPDissociatedNewsLoader ()

@property (strong, nonatomic) NSMutableArray *titleTokens;
@property (strong, nonatomic) NSMutableDictionary *titleTokenContext;
@property (strong, nonatomic) NSMutableArray *contentTokens;
@property (strong, nonatomic) NSMutableDictionary *contentTokenContext;

@property (nonatomic) NSInteger tokenSize;
@property (strong, nonatomic) NSNumber *dissociateByWord;
@end

@implementation DSPDissociatedNewsLoader

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.titleTokens = [NSMutableArray array];
        self.titleTokenContext = [NSMutableDictionary dictionary];
        self.contentTokens = [NSMutableArray array];
        self.contentTokenContext = [NSMutableDictionary dictionary];
        self.tokenSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"tokenSizeParameter"];
        self.dissociateByWord = [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"dissociateByWordParameter"]];
    }
    return self;
}


- (NSArray *)loadDissociatedNewsForQueries:(NSArray *)queries pageNumber:(int)page
{
    NSMutableArray *results = [NSMutableArray array];
    for (NSString *query in queries) {
        [results addObjectsFromArray:[super loadNewsForQuery:query pageNumber:page]];
    }
    //shuffle stories
    for (int i = 0; i < results.count; i++)
    {
        [results exchangeObjectAtIndex:i withObjectAtIndex:arc4random_uniform(i+1)];
    }
    
    NSMutableDictionary *titleSeeds = [[NSMutableDictionary alloc] initWithCapacity:results.count];
    NSMutableDictionary *contentSeeds = [[NSMutableDictionary alloc] initWithCapacity:results.count];
    //tokenize each story and add it to the token lists
    for (DSPNewsStory *story in results) {
        NSNumber *storyHash  = [NSNumber numberWithUnsignedInteger:[story hash]];
        
        NSUInteger seedIndex = [self.titleTokens count]; //index of the first token to be added for story.title
        NSString *title = [story.title stringByAppendingString:@"\n"];
        [self tokenizeString:title toTokenArray:self.titleTokens TokenContext:self.titleTokenContext];
        titleSeeds[storyHash] = self.titleTokens[seedIndex]; //save the first token from this story to seed the dissociation
        
        seedIndex = [self.contentTokens count]; //index of the first token to be added for story.content
        NSString *content = [story.content stringByAppendingString:@"\n"];
        [self tokenizeString:content toTokenArray:self.contentTokens TokenContext:self.contentTokenContext];
        contentSeeds[storyHash] = self.contentTokens[seedIndex]; //save the first token from this story to seed the dissociation
    }
    
    //rewrite each story using the collected tokens
    for (DSPNewsStory *story in results) {
        NSNumber *storyHash = [NSNumber numberWithUnsignedInteger:[story hash]];
        NSString *titleSeed = titleSeeds[storyHash];
        story.title = [self reassociateWithSeed:titleSeed tokens:self.titleTokens context:self.titleTokenContext];
        
        NSString *contentSeed = contentSeeds[storyHash];
        story.content = [self reassociateWithSeed:contentSeed tokens:self.contentTokens context:self.contentTokenContext];
        
    }
    return results;
}

- (void)tokenizeString:(NSString *)sourceString toTokenArray:(NSMutableArray *)tokenArray TokenContext:(NSMutableDictionary *)tokenContext
{
    NSUInteger stringEnumerationOptions = NSStringEnumerationByComposedCharacterSequences;
    if ([self.dissociateByWord boolValue]) {
        stringEnumerationOptions = NSStringEnumerationByWords;
    }
    NSMutableArray *token = [NSMutableArray array];
    [sourceString enumerateSubstringsInRange:NSMakeRange(0, sourceString.length) options:stringEnumerationOptions usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        substring = [sourceString substringWithRange:enclosingRange];
        [token addObject:substring];
        if (token.count > self.tokenSize) [token removeObjectAtIndex:0];
        
        if ([substring rangeOfString:@"\n"].location != NSNotFound) {
            //taper off when adding the final token
            while ([token count] > 0) {
                NSString *tokenString = [token componentsJoinedByString:@""];
                [tokenArray addObject:tokenString];
                if (!tokenContext[tokenString]) tokenContext[tokenString] = [NSMutableArray array];
                [tokenContext[tokenString] addObject:[NSNumber numberWithInteger:(tokenArray.count - 1)]];
                [token removeObjectAtIndex:0];
            }
            
        } else if (token.count == self.tokenSize) {
            NSString *tokenString = [token componentsJoinedByString:@""];
            [tokenArray addObject:tokenString];
            if (!tokenContext[tokenString]) tokenContext[tokenString] = [NSMutableArray array];
            [tokenContext[tokenString] addObject:[NSNumber numberWithInteger:(tokenArray.count - 1)]];
        }
    }];
}


- (NSString *)reassociateWithSeed:(NSString *)seed tokens:(NSArray *)tokens context:(NSDictionary *)context
{
    BOOL success = NO;
    NSString *outString = @"";
    NSUInteger index;
    while (!success) {
        outString = @"";
        NSString *currentToken = seed;
        
        while ([currentToken rangeOfString:@"\n"].location == NSNotFound) {
            outString = [outString stringByAppendingString:currentToken];
            index = arc4random() % [context[currentToken] count];
            index = [context[currentToken][index] intValue] + self.tokenSize;
            if (index >= [tokens count]) {
                currentToken = @"\n";
            }
            else currentToken = tokens[index];
        }
        outString = [outString stringByAppendingString:currentToken];
        
        if ([outString length] > self.tokenSize) {
            success = YES;
        }
    }
    return outString;
}

@end