//
//  DSPWebViewController.m
//  DissociatedPress-iOS
//
//  Created by Joe Wilkerson on 12/18/14.
//
//

#import "DSPWebViewController.h"

@interface DSPWebViewController () <UIWebViewDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;
@property (strong, nonatomic) UIBarButtonItem *forwardButton;

@end

@implementation DSPWebViewController

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    
    self.webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
    self.view = self.webView;
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicator.hidesWhenStopped = YES;
    self.navigationItem.titleView = self.activityIndicator;
    
    self.backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(goBack:)];
    self.backButton.enabled = self.webView.canGoBack;
    self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
    self.forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(goForward:)];
    self.forwardButton.enabled = self.webView.canGoForward;
    self.navigationItem.rightBarButtonItems = @[self.forwardButton, self.refreshButton, self.backButton];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)goBack:(UIButton *)sender
{
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (void)refresh:(UIBarButtonItem *)sender
{
    [self.webView reload];
}

- (void)goForward:(UIButton *)sender
{
    if (self.webView.canGoForward) {
        [self.webView goForward];
    }
}

#pragma  mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicator startAnimating];
    
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicator stopAnimating];
    
    self.backButton.enabled = self.webView.canGoBack;
    self.forwardButton.enabled = self.webView.canGoForward;
}


@end