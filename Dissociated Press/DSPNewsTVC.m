//
//  NewsTableViewController.m
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 11/10/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//
#import <RedditKit/RedditKit.h>

#import "DSPNewsTVC.h"
#import "DSPNewsStory.h"
#import "DSPNewsLoader.h"
#import "DSPDissociatedNewsLoader.h"
#import "DSPSubmitLinkTVC.h"
#import <iAd/iAd.h>
#import "IAPHelper.h"


@interface DSPNewsTVC ()

@property (strong, nonatomic) DSPQueryHeaderView *queryHeaderView;
@property (strong, nonatomic) DSPTopicHeaderView *topicHeaderView;
@property (strong, nonatomic) UIPopoverController *topicsPopover;
@property (strong, nonatomic) UIActivityIndicatorView *footerActivityIndicator;
@property (strong, nonatomic) NSMutableArray *queries; // array of strings;
@property (strong, nonatomic) NSMutableArray *topics; //array of strings;
@property (strong, nonatomic) UISegmentedControl *queryTypeControl;
@property (strong, nonatomic) NSMutableArray *newsArray;
@property (strong, nonatomic) DSPDissociatedNewsLoader *newsLoader;
@property (nonatomic) int pageNumber;
@property (strong, nonatomic) dispatch_queue_t newsLoaderQueue;

@property (strong, nonatomic) NSMutableDictionary *rowHeightCache;
@property (strong, nonatomic) DSPNewsTableViewCell *sizingCell;

@end

@implementation DSPNewsTVC

#pragma mark - view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.queries = [NSMutableArray array];
    self.topics = [NSMutableArray arrayWithObjects:@"Headlines", @"World", @"Technology", @"Entertainment", @"Health", nil];
    
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    self.topicHeaderView = [[DSPTopicHeaderView alloc] init];
    self.topicHeaderView.delegate = self;
    
    self.queryHeaderView = [[DSPQueryHeaderView alloc] init];
    self.queryHeaderView.delegate = self;
    
    self.footerActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.footerActivityIndicator.hidesWhenStopped = YES;
    self.tableView.tableFooterView = self.footerActivityIndicator;
    
    /*
     *create a cell instance to use for autolayout sizing
     */
    self.sizingCell = [[DSPNewsTableViewCell alloc] initWithReuseIdentifier:nil];
    self.sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.sizingCell.hidden = YES;
    [self.tableView addSubview:self.sizingCell];
    self.sizingCell.frame = CGRectMake(0, 0, CGRectGetWidth(self.tableView.bounds), 300);
    
    self.newsLoaderQueue = dispatch_queue_create("com.DissociatedPress.newsLoaderQueue", DISPATCH_QUEUE_CONCURRENT);
    
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(loadNews)];
    refreshButton.tintColor = [UIColor darkGrayColor];
    self.navigationItem.rightBarButtonItem = refreshButton;
    
    self.queryTypeControl = [[UISegmentedControl alloc] initWithItems:@[@"T",@"S"]];
    [self.queryTypeControl setImage:[UIImage imageNamed:@"UITabBarMostViewed"] forSegmentAtIndex:0];
    [self.queryTypeControl setImage:[UIImage imageNamed:@"UITabBarSearch"] forSegmentAtIndex:1];
    self.queryTypeControl.tintColor = [UIColor darkGrayColor];
    self.queryTypeControl.selectedSegmentIndex = 1;
    [self.queryTypeControl addTarget:self action:@selector(changedQueryType:) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *controlButton = [[UIBarButtonItem alloc] initWithCustomView:self.queryTypeControl];
    self.navigationItem.leftBarButtonItem = controlButton;
    
    [self updateIAPStatus:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateIAPStatus:) name:IAPHelperProductPurchasedNotification object:nil];
    
    [self loadNews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"%@ %@",[self class], NSStringFromSelector(_cmd));
    // Dispose of any resources that can be recreated.
    self.rowHeightCache = [NSMutableDictionary dictionary];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    self.rowHeightCache = [NSMutableDictionary dictionary];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)loadNews
{
    [self.footerActivityIndicator startAnimating];
    
    self.navigationItem.title = [self tokenDescriptionString];
    
    for (int i = 0; i < self.queryHeaderView.stepper.maximumValue; i++) {
        UISearchBar *searchBar = self.queryHeaderView.searchBars[i];
        self.queries[i] = searchBar.text;
    }
    
    //reset and populate news array
    dispatch_barrier_async(self.newsLoaderQueue, ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *rangeToDelete = [self indexPathArrayForRangeFromStart:0 toEnd:self.newsArray.count inSection:0];
            [self.newsArray removeAllObjects];
            [self.tableView deleteRowsAtIndexPaths:rangeToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
        
        self.rowHeightCache = [NSMutableDictionary dictionary];
        self.pageNumber = 1;
        DSPDissociatedNewsLoader *newsLoader = [[DSPDissociatedNewsLoader alloc] init];
        NSArray *newNews;
        if (self.queryTypeControl.selectedSegmentIndex == 0) {
            newNews = [newsLoader loadDissociatedNewsForTopics:self.topics pageNumber:self.pageNumber];
        } else {
            newNews = [newsLoader loadDissociatedNewsForQueries:[self.queries subarrayWithRange:NSMakeRange(0, self.queryHeaderView.stepper.value)] pageNumber:self.pageNumber];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([newNews count] == 0) {
                UIAlertView *noResultsError = [[UIAlertView alloc] initWithTitle:@"No results found"
                                                                         message:@"Check your internet connection or try a different query."
                                                                        delegate:nil
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil];
                [noResultsError show];
                [self.footerActivityIndicator stopAnimating];
            } else {
                self.newsLoader = newsLoader;
                self.newsArray = [newNews mutableCopy];
                NSArray *rangeToInsert = [self indexPathArrayForRangeFromStart:0 toEnd:self.newsArray.count inSection:0];
                [self.tableView insertRowsAtIndexPaths:rangeToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        });
    });
}

- (void)updateIAPStatus:(NSNotification *)notification
{
    if ([[IAPHelper sharedInstance] productPurchased:IAPHelperProductRemoveAds]) {
        self.canDisplayBannerAds = NO;
    }
    else {
        self.canDisplayBannerAds = YES;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.newsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseIdentifier = @"NewsFeedCell";
    DSPNewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) cell = [[DSPNewsTableViewCell alloc] initWithReuseIdentifier:cellReuseIdentifier];
    
    cell.newsStory = [self.newsArray objectAtIndex:indexPath.row];
    cell.delegate = self;
    cell.indexPath = indexPath;
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (self.queryTypeControl.selectedSegmentIndex == 0) {
        if (section == 0) return self.topicHeaderView;
    } else {
        if (section == 0) return self.queryHeaderView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.queryTypeControl.selectedSegmentIndex == 0) {
        if (section == 0) return [self.topicHeaderView headerHeight];
        
    } else {
        if (section == 0) return [self.queryHeaderView headerHeight];
    }
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSPNewsStory *story = [self.newsArray objectAtIndex:indexPath.row];
    
    NSNumber *cachedHeight = self.rowHeightCache[story.uniqueIdentifier];
    if (cachedHeight != nil) return [cachedHeight floatValue];
    
    self.sizingCell.newsStory = story;
    
    [self.sizingCell setNeedsLayout];
    [self.sizingCell layoutIfNeeded];
    
    CGFloat calculatedHeight = [self.sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    self.rowHeightCache[story.uniqueIdentifier] = @(calculatedHeight);
    
    return calculatedHeight;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSPNewsStory *story = [self.newsArray objectAtIndex:indexPath.row];
    NSNumber *cachedHeight = self.rowHeightCache[story.uniqueIdentifier];
    if (cachedHeight != nil) return [cachedHeight floatValue];
    return 160.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.pageNumber < 16) {
        if (indexPath.row >= self.newsArray.count - 1) {
            dispatch_barrier_async(self.newsLoaderQueue, ^{
                self.pageNumber++;
                NSArray *newNews;
                if (self.queryTypeControl.selectedSegmentIndex == 0) {
                    newNews = [self.newsLoader loadDissociatedNewsForTopics:self.topics pageNumber:self.pageNumber];
                } else {
                    newNews = [self.newsLoader loadDissociatedNewsForQueries:[self.queries subarrayWithRange:NSMakeRange(0, self.queryHeaderView.stepper.value)] pageNumber:self.pageNumber];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSArray *rangeToInsert = [self indexPathArrayForRangeFromStart:self.newsArray.count toEnd:(self.newsArray.count + newNews.count) inSection:0];
                    [self.newsArray addObjectsFromArray:newNews];
                    [self.tableView insertRowsAtIndexPaths:rangeToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            });
        }
    } else {
        [self.footerActivityIndicator stopAnimating];
    }
}

- (NSArray *)indexPathArrayForRangeFromStart:(NSInteger)start toEnd:(NSInteger)end inSection:(NSInteger)section
{
    //returns an array of index paths in the given range
    //used by the tableview when inserting/deleting rows
    NSMutableArray *rangeArray = [NSMutableArray array];
    for (NSInteger i = start; i < end; i++) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:section];
        [rangeArray addObject:path];
    }
    return rangeArray;
}


#pragma mark - Misc Delegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self loadNews];
}

- (void)touchedStepper:(UIStepper *)sender
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)touchedTopicHeader
{
    DSPTopicsTVC *topicsTVC = [[DSPTopicsTVC alloc] initWithStyle:UITableViewStyleGrouped];
    topicsTVC.delegate = self;
    topicsTVC.selectedTopics = self.topics;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.topicsPopover = [[UIPopoverController alloc] initWithContentViewController:topicsTVC];
        self.topicsPopover.delegate = self;
        topicsTVC.preferredContentSize = CGSizeMake(320, topicsTVC.tableViewHeight+44.0);
        [self.topicsPopover presentPopoverFromRect:self.topicHeaderView.frame inView:self.originalContentView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        UINavigationController *navigationVC = [[UINavigationController alloc] initWithRootViewController:topicsTVC];
        [self presentViewController:navigationVC animated:YES completion:nil];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self loadNews];
}

- (void)didDismissTopicsTVC
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.topicsPopover dismissPopoverAnimated:YES];
    } else {
        [self loadNews];
    }
}


- (void)didClickActionButtonInCellAtIndexPath:(NSIndexPath *)cellIndex
{
    DSPNewsStory *story = self.newsArray[cellIndex.row];
    
    DSPSubmitLinkTVC *submissionVC = [[DSPSubmitLinkTVC alloc] init];
    submissionVC.story = story;
    submissionVC.tokenDescriptionString = [self tokenDescriptionString];
    if (self.queryTypeControl.selectedSegmentIndex == 0) {
        submissionVC.topics = self.topics;
    } else {
        submissionVC.queries = [self.queries subarrayWithRange:NSMakeRange(0, self.queryHeaderView.stepper.value)];
    }
    [self.navigationController pushViewController:submissionVC animated:YES];
}

- (void)dissociateCellAtIndexPath:(NSIndexPath *)cellIndex
{
    DSPNewsStory *story = self.newsArray[cellIndex.row];
    story.dissociatedTitle = [self.newsLoader dissociatedTitleForStory:story];
    story.dissociatedContent = [self.newsLoader dissociatedContentForStory:story];
    [self.rowHeightCache removeObjectForKey:story.uniqueIdentifier];
    [self.tableView reloadRowsAtIndexPaths:@[cellIndex] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)reassociateCellAtIndexPath:(NSIndexPath *)cellIndex
{
    DSPNewsStory *story = self.newsArray[cellIndex.row];
    story.dissociatedTitle = nil;
    story.dissociatedContent = nil;
    [self.rowHeightCache removeObjectForKey:story.uniqueIdentifier];
    [self.tableView reloadRowsAtIndexPaths:@[cellIndex] withRowAnimation:UITableViewRowAnimationFade];
}

- (NSString *)tokenDescriptionString
{
    NSMutableString *tokenDescriptionString = [[NSMutableString alloc] initWithString:@"Token size: "];
    NSInteger tokenSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"tokenSizeParameter"];
    BOOL dissociateByWord = [[NSUserDefaults standardUserDefaults] boolForKey:@"dissociateByWordParameter"];
    
    [tokenDescriptionString appendString:[NSString stringWithFormat:@"%ld ", (long)tokenSize]];
    if (dissociateByWord) [tokenDescriptionString appendString:@"Word"];
    else [tokenDescriptionString appendString:@"Character"];
    if (tokenSize > 1) [tokenDescriptionString appendString:@"s"];
    
    return tokenDescriptionString;
}

- (void)changedQueryType:(UISegmentedControl *)segmentedControl;
{
    [self loadNews];
}

@end
