//
//  PagedScrollView.m
//
//  Modified from https://github.com/jianpx/ios-cabin/tree/master/PagedImageScrollView 
//

#import "PagedScrollView.h"

@interface PagedScrollView() <UIScrollViewDelegate>
@property (nonatomic) BOOL pageControlIsChangingPage;
@end

@implementation PagedScrollView


#define PAGECONTROL_DOT_WIDTH 20
#define PAGECONTROL_HEIGHT 20

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        self.scrollView.backgroundColor = [UIColor whiteColor];
        self.pageControl = [[UIPageControl alloc] init];
        [self setDefaults];
        [self.pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.scrollView];
        [self addSubview:self.pageControl];
        self.scrollView.delegate = self;
        
        self.scrollView.autoresizesSubviews = YES;
        self.scrollView.contentOffset = CGPointZero;
        self.scrollView.directionalLockEnabled = NO;
    }
    return self;
}


- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    self.scrollView.frame = CGRectMake(0,0, frame.size.width, frame.size.height);
    self.scrollView.contentSize = CGSizeMake(frame.size.width * self.pageControl.numberOfPages, frame.size.height);
    CGRect scrollFrame = CGRectMake(frame.size.width * self.pageControl.currentPage, 0.f, frame.size.width, frame.size.height);
    [self.scrollView scrollRectToVisible:scrollFrame animated:NO];
    self.pageControlIsChangingPage = YES;
    self.pageControlPos = self.pageControlPos;
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(UIView *v, NSUInteger i, BOOL *stop)
     {
         v.frame = CGRectMake(self.frame.size.width * i, 0.f, self.frame.size.width, self.frame.size.height);
         [v setNeedsLayout];
     }];
}

- (void)setPageControlPos:(enum PageControlPosition)pageControlPos
{
    CGFloat width = PAGECONTROL_DOT_WIDTH * self.pageControl.numberOfPages;
    _pageControlPos = pageControlPos;
    if (pageControlPos == PageControlPositionRightCorner)
    {
        self.pageControl.frame = CGRectMake(self.scrollView.frame.size.width - width, self.scrollView.frame.size.height - PAGECONTROL_HEIGHT, width, PAGECONTROL_HEIGHT);
    }else if (pageControlPos == PageControlPositionCenterBottom)
    {
        self.pageControl.frame = CGRectMake((self.scrollView.frame.size.width - width) / 2, self.scrollView.frame.size.height - PAGECONTROL_HEIGHT, width, PAGECONTROL_HEIGHT);
    }else if (pageControlPos == PageControlPositionLeftCorner)
    {
        self.pageControl.frame = CGRectMake(0, self.scrollView.frame.size.height - PAGECONTROL_HEIGHT, width, PAGECONTROL_HEIGHT);
    }
}

- (void)setDefaults
{
    //Magenta
    UIColor *tintColor = [UIColor colorWithRed:203.f/255.f green:86.f/255.f blue:142.f/255.f alpha:1.f];
    self.pageControl.currentPageIndicatorTintColor = tintColor;
    self.pageControl.pageIndicatorTintColor = [UIColor darkGrayColor];
    self.pageControl.hidesForSinglePage = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.pageControlPos = PageControlPositionCenterBottom;
}


- (void)setScrollViewContents: (NSArray *)views
{
    //remove original subviews first.
    for (UIView *subview in [self.scrollView subviews]) {
        [subview removeFromSuperview];
    }
    if (views.count <= 0) {
        self.pageControl.numberOfPages = 0;
        return;
    }
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * views.count, self.scrollView.frame.size.height);
    
    [views enumerateObjectsUsingBlock:^(UIView *v, NSUInteger i, BOOL *stop)
    {
        v.frame = CGRectMake(self.frame.size.width * i, v.frame.origin.y, v.frame.size.width, v.frame.size.height);
        [self.scrollView addSubview:views[i]];
    }];
    self.pageControl.numberOfPages = views.count;
    //call pagecontrolpos setter.
    self.pageControlPos = self.pageControlPos;
}

- (void)changePage:(UIPageControl *)sender
{
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * self.pageControl.currentPage;
    frame.origin.y = 0;
    frame.size = self.scrollView.frame.size;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    self.pageControlIsChangingPage = YES;
}

#pragma scrollviewdelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.pageControlIsChangingPage) {
        return;
    }
    CGFloat pageWidth = scrollView.frame.size.width;
    //switch page at 50% across
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.pageControlIsChangingPage = NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.pageControlIsChangingPage = NO;
}

@end
