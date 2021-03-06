//
//  DPNewsHeaderView.m
//  DissociatedPress-iOS
//
//  Created by Joseph Wilkerson on 12/4/14.
//
//

#import "DSPQueryHeaderView.h"

#define NUM_MAX_SEARCHBARS 3

@implementation DSPQueryHeaderView

- (instancetype)init
{
    self = [super init];
    
    
    self.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    self.layer.shadowOffset = CGSizeMake(0,0);
    self.layer.shadowRadius = 4;

    NSArray *queries = @[@"\"United Nations\"",@"Vacations",@"florida man",@"bieber fever",@"pro-state agitators"];
    self.searchBars = [NSMutableArray array];
    for (int i = 0; i < NUM_MAX_SEARCHBARS; i++) {
        UISearchBar *searchBar = [[UISearchBar alloc] init];
        searchBar.backgroundImage = [[UIImage alloc] init];
        [self addSubview:searchBar];
        [self.searchBars addObject:searchBar];
        [searchBar setAutocorrectionType:UITextAutocorrectionTypeNo];
        [searchBar setAutocapitalizationType:UITextAutocapitalizationTypeNone];
        searchBar.placeholder = [NSString stringWithFormat:@"Query %lu",(unsigned long)self.searchBars.count];
        if ([queries[i] length] > 0) {
            searchBar.text = queries[i];
        }
        searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    self.stepper = [[UIStepper alloc] init];
    self.stepper.minimumValue = 1;
    self.stepper.maximumValue = NUM_MAX_SEARCHBARS;
    self.stepper.value = 2;
    [self addSubview:self.stepper];
    self.stepper.translatesAutoresizingMaskIntoConstraints = NO;
    self.stepper.backgroundColor = [UIColor whiteColor];
    self.stepper.tintColor = [UIColor darkGrayColor];
    self.stepper.layer.cornerRadius = 5.f;
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            44.0 * self.stepper.value);
    
    [self applyConstraints];
    
    return self;
}

- (CGFloat)headerHeight
{
    return MAX(44.0, 44.0 * self.stepper.value);
}


- (void)setDelegate:(id<DSPQueryHeaderDelegate,UISearchBarDelegate>)delegate
{
    for (UISearchBar *searchBar in self.searchBars) {
        searchBar.delegate = delegate;
    }
    [self.stepper addTarget:delegate action:@selector(touchedStepper:) forControlEvents:UIControlEventValueChanged];

    _delegate = delegate;
}

- (void)applyConstraints
{
    NSLayoutConstraint *constraint;
    for (int numSearchBar = 0; numSearchBar < NUM_MAX_SEARCHBARS; numSearchBar++) {
        UISearchBar *searchBar = self.searchBars[numSearchBar];
        [searchBar setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh - numSearchBar) forAxis:UILayoutConstraintAxisVertical];
        
        constraint = [NSLayoutConstraint constraintWithItem:searchBar
                                                  attribute:NSLayoutAttributeLeading
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.stepper
                                                  attribute:NSLayoutAttributeTrailing
                                                 multiplier:1
                                                   constant:8];
        constraint.priority = UILayoutPriorityDefaultHigh;
        [self addConstraint:constraint];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeTrailing
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:searchBar
                                                         attribute:NSLayoutAttributeTrailing
                                                        multiplier:1
                                                          constant:0]];
        
        if (numSearchBar == 0) {//pin first search bar to top of superview
            [self addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:0]];
        } else {//pin each search bar to the bottom of the preceding bar
            UISearchBar *lastSearchBar = self.searchBars[numSearchBar - 1];
            [self addConstraint:[NSLayoutConstraint constraintWithItem:searchBar
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:lastSearchBar
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0]];
            if (numSearchBar == NUM_MAX_SEARCHBARS - 1) {//pin the last searchbar to the bottom of the superview
                [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:searchBar
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1
                                                                  constant:0]];
            }
        }
    }
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.stepper
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:8]];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.stepper
                                              attribute:NSLayoutAttributeLeading
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self attribute:NSLayoutAttributeLeading
                                             multiplier:1
                                               constant:8];
    constraint.priority = UILayoutPriorityDefaultHigh;
    [self addConstraint:constraint];

}
@end
