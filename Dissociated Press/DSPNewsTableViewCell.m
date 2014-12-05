//
//  NewsTableViewCell.m
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 11/15/14.
//  Copyright (c) 2014 Joseph Wilkerson. All rights reserved.
//

#import "DSPNewsTableViewCell.h"

@interface DSPNewsTableViewCell ()

@property (strong, nonatomic) NSMutableArray *hasThumbnailConstraints;
@property (strong, nonatomic) NSMutableArray *noThumbnailConstraints;

@end

@implementation DSPNewsTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    self.cardView = [[UIView alloc] init];
    [self.cardView setAlpha:1];
    self.cardView.backgroundColor = [UIColor whiteColor];
    self.cardView.layer.masksToBounds = NO;
    self.cardView.layer.cornerRadius = 4;
    self.cardView.layer.shadowOffset = CGSizeMake(0, 3.f);
    self.cardView.layer.shadowRadius = -.4f;
    self.cardView.layer.shadowOpacity = 0.2;
    self.cardView.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.cardView];
    
    self.thumbnail = [[UIImageView alloc] init];
    self.thumbnail.contentMode = UIViewContentModeScaleAspectFit;
    self.thumbnail.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.thumbnail];
    
    self.titleLabel = [[DSPNewsLabel alloc] init];
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.titleLabel.textColor = [UIColor blackColor];
    self.titleLabel.backgroundColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 3;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.titleLabel];
    
    self.dateLabel = [[DSPNewsLabel alloc] init];
    self.dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    self.dateLabel.textColor = [UIColor colorWithRed:0.0 green:0.4 blue:0.13 alpha:1.0];
    self.dateLabel.backgroundColor = [UIColor whiteColor];
    self.dateLabel.numberOfLines = 1;
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.dateLabel];
    
    self.contentLabel = [[DSPNewsLabel alloc] init];
    self.contentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.contentLabel.textColor = [UIColor blackColor];
    self.contentLabel.backgroundColor = [UIColor whiteColor];
    self.contentLabel.numberOfLines = 4;
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cardView addSubview:self.contentLabel];
    
    self.hasThumbnailConstraints = [NSMutableArray array];
    self.noThumbnailConstraints = [NSMutableArray array];
    
    [self applyConstraints];
    
    return self;
}


- (void)setNewsStory:(DSPNewsStory *)newsStory
{
    _newsStory = newsStory;
    
    self.titleLabel.text = [newsStory.title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.contentLabel.text = [newsStory.content stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateLabel.text = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:newsStory.date]];
    
    if (newsStory.hasThumbnail) {
        self.thumbnail.hidden = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = [NSData dataWithContentsOfURL:newsStory.imageUrl];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.thumbnail.image = [[UIImage alloc] initWithData:imageData];
            });
        });
    } else {
        self.thumbnail.hidden = YES;
    }
    
    [self setNeedsUpdateConstraints];
    [self setNeedsLayout];
}

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.newsStory.hasThumbnail) {
        [self.cardView removeConstraints:self.noThumbnailConstraints];
        [self.cardView addConstraints:self.hasThumbnailConstraints];
    } else {
        [self.cardView removeConstraints:self.hasThumbnailConstraints];
        [self.cardView addConstraints:self.noThumbnailConstraints];
    }
}

- (void)applyConstraints
{
    NSLayoutConstraint *constraint;
    /*
     *constraints between cardView and contentView
     */
    [self.contentView removeConstraints:self.contentView.constraints];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.cardView
                                              attribute:NSLayoutAttributeTop
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.contentView
                                              attribute:NSLayoutAttributeTop
                                             multiplier:1
                                               constant:8];
    constraint.priority = 999;
    [self.contentView addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.cardView
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1
                                               constant:8];
    constraint.priority = 1000;
    [self.contentView addConstraint:constraint];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardView
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeading
                                                                multiplier:1
                                                                  constant:16]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentView
                                                                 attribute:NSLayoutAttributeTrailing
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.cardView
                                                                 attribute:NSLayoutAttributeTrailing
                                                                multiplier:1
                                                                  constant:16]];
    
    /*
     *cardview's subviews constraints
     */
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.titleLabel
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:16]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.dateLabel
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:16]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardView
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.contentLabel
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1
                                                               constant:16]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.cardView
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1
                                                               constant:16]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.dateLabel
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1
                                                               constant:0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.contentLabel
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1
                                                               constant:0]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.dateLabel
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.titleLabel
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:8]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.contentLabel
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.dateLabel
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:8]];
    
    [self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.cardView
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                 toItem:self.contentLabel
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:16]];
    
    [self.thumbnail addConstraint:[NSLayoutConstraint constraintWithItem:self.thumbnail
                                                               attribute:NSLayoutAttributeWidth
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.thumbnail
                                                               attribute:NSLayoutAttributeHeight
                                                              multiplier:1
                                                                constant:0]];
    
    [self.thumbnail setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.thumbnail setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [self.thumbnail addConstraint:[NSLayoutConstraint constraintWithItem:self.thumbnail
                                                               attribute:NSLayoutAttributeHeight
                                                               relatedBy:NSLayoutRelationLessThanOrEqual
                                                                  toItem:nil
                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                              multiplier:1
                                                                constant:120]];
    
    //hasthumbnail
    
    [self.hasThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.thumbnail
                                                                         attribute:NSLayoutAttributeTrailing
                                                                        multiplier:1
                                                                          constant:8]];
    
    [self.hasThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.thumbnail
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.cardView
                                                                         attribute:NSLayoutAttributeCenterY
                                                                        multiplier:1
                                                                          constant:0]];
    
    [self.hasThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.thumbnail
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.cardView
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1
                                                                          constant:16]];
    
    [self.hasThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.thumbnail
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                            toItem:self.cardView
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1
                                                                          constant:16]];
    
    [self.hasThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.cardView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                            toItem:self.thumbnail
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1
                                                                          constant:16]];
    
    //nothumbnail
    [self.noThumbnailConstraints addObject:[NSLayoutConstraint constraintWithItem:self.titleLabel
                                                                        attribute:NSLayoutAttributeLeading
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.cardView
                                                                        attribute:NSLayoutAttributeLeading
                                                                       multiplier:1
                                                                         constant:16]];
}

@end