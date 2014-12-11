//
//  NewsTableViewCell.h
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 11/15/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DSPNewsStory.h"
#import "DSPLabel.h"

@protocol DSPNewsCellDelegate <NSObject>
- (void)didClickActionButtonInCellAtIndexPath:(NSIndexPath*)cellIndex;
@end

@interface DSPNewsTableViewCell : UITableViewCell

@property (strong, nonatomic) DSPNewsStory *newsStory;
@property (strong, nonatomic) DSPLabel *titleLabel;
@property (strong, nonatomic) DSPLabel *dateLabel;
@property (strong, nonatomic) DSPLabel *contentLabel;
@property (strong, nonatomic) UIImageView *thumbnail;
@property (strong, nonatomic) UIView *cardView;
@property (weak, nonatomic) id<DSPNewsCellDelegate>delegate;
@property (strong, nonatomic) NSIndexPath *indexPath;

- (instancetype)initWithReuseIdentifier:(NSString*)reuseIdentifier;

@end


